use flutter_rust_bridge::{frb, StreamSink};
use matrix_sdk::{Client, config::SyncSettings, room::Room};
use matrix_sdk::ruma::{RoomId};
use matrix_sdk::ruma::events::receipt::ReceiptType;
use matrix_sdk::ruma::events::room::message::{RoomMessageEventContent, OriginalSyncRoomMessageEvent, MessageType};
use serde::{Deserialize, Serialize};
use once_cell::sync::OnceCell;
use tokio::task::JoinHandle;
use tokio::runtime::Runtime;
use url::Url;
use std::sync::Mutex;

static TOKIO_RT: OnceCell<Runtime> = OnceCell::new();
static CLIENT: OnceCell<Client> = OnceCell::new();
static SYNC_HANDLE: OnceCell<JoinHandle<()>> = OnceCell::new();
static EVENT_SINK: OnceCell<Mutex<Option<StreamSink<MatrixEvent>>>> = OnceCell::new();

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct MatrixEvent {
    pub room_id: String,
    pub event_id: String,
    pub sender: String,
    pub ts: i64,
    pub content: Option<String>,
    pub is_encrypted: bool,
}

#[derive(Serialize, Deserialize)]
pub struct LoginResult {
    pub user_id: String,
    pub access_token: String,
}

/// Subscribe a Dart StreamSink to receive Matrix events.
#[frb]
pub fn subscribe_events(sink: StreamSink<MatrixEvent>) -> Result<(), String> {
    let cell = EVENT_SINK.get_or_init(|| Mutex::new(None));
    let mut guard = cell.lock().map_err(|_| "failed to lock event sink".to_string())?;
    *guard = Some(sink);
    Ok(())
}

fn get_rt() -> &'static Runtime {
    TOKIO_RT.get_or_init(|| {
        Runtime::new().expect("Failed to create Tokio runtime")
    })
}

#[frb]
pub fn init(homeserver: String, _data_dir: String) -> Result<(), String> {
    let url = Url::parse(&homeserver).map_err(|e| e.to_string())?;
    let rt = get_rt();
    rt.block_on(async move {
        let client = Client::builder()
            .homeserver_url(url)
            .build()
            .await
            .map_err(|e| e.to_string())?;
        CLIENT.set(client).map_err(|_| "Client already initialized".to_string())?;
        Ok(())
    })
}

#[frb]
pub fn login(user: String, password: String) -> Result<LoginResult, String> {
    let rt = get_rt();
    rt.block_on(async move {
        let client = CLIENT.get().ok_or_else(|| "Client not initialized".to_string())?.clone();
        // Login using username & password (new API via matrix_auth)
        let _resp = client
            .matrix_auth()
            .login_username(&user, &password)
            .send()
            .await
            .map_err(|e| e.to_string())?;

        let uid = client
            .user_id()
            .ok_or_else(|| "No user id after login".to_string())?
            .to_string();

        // Access token retrieval differs across SDK versions; keep empty for now.
        Ok(LoginResult { user_id: uid, access_token: String::new() })
    })
}

#[frb]
pub fn create_room(_other_mxid: String) -> Result<String, String> {
    // TODO: Implement room creation (DM or group) using matrix-sdk APIs.
    Err("create_room not implemented".to_string())
}

#[frb]
pub fn send_message(room_id: String, body: String) -> Result<String, String> {
    let rt = get_rt();
    rt.block_on(async move {
        let client = CLIENT.get().ok_or_else(|| "Client not initialized".to_string())?.clone();
        let rid = RoomId::parse(&room_id).map_err(|e| e.to_string())?;
        let room = client.get_room(&rid).ok_or_else(|| "Room not found".to_string())?;
        let content = RoomMessageEventContent::text_plain(body);
        let send_resp = room
            .send(content)
            .await
            .map_err(|e| e.to_string())?;
        // Return event id if available
        Ok(send_resp.event_id.to_string())
    })
}

/// Send a read receipt for a specific event in a room.
#[frb]
pub fn mark_read(room_id: String, event_id: String) -> Result<(), String> {
    let rt = get_rt();
    rt.block_on(async move {
        let client = CLIENT.get().ok_or_else(|| "Client not initialized".to_string())?.clone();
        let rid = RoomId::parse(&room_id).map_err(|e| e.to_string())?;
        let room = client.get_room(&rid).ok_or_else(|| "Room not found".to_string())?;
        room
            .read_receipt(ReceiptType::Read, &event_id.into())
            .await
            .map_err(|e| e.to_string())?;
        Ok(())
    })
}

#[frb]
pub fn start_sync() -> Result<(), String> {
    let rt = get_rt();
    // Spawn a background sync loop if not already running
    if SYNC_HANDLE.get().is_some() {
        return Ok(());
    }
    let handle = rt.spawn(async move {
        if let Some(client) = CLIENT.get() {
            let client = client.clone();
            // Register event handler to forward message events to Dart via StreamSink
            client.add_event_handler(|ev: OriginalSyncRoomMessageEvent, room: Room| async move {
                let rid = room.room_id().to_string();
                let eid = ev.event_id.to_string();
                let sender = ev.sender.to_string();
                let ts = ev.origin_server_ts.0;
                // Extract plaintext if available (SDK decrypts before handler when keys available)
                let content = match &ev.content.msgtype {
                    MessageType::Text(t) => Some(t.body.clone()),
                    MessageType::Notice(n) => Some(n.body.clone()),
                    MessageType::Emote(e) => Some(e.body.clone()),
                    _ => None,
                };
                let is_encrypted = content.is_none();
                let evt = MatrixEvent { room_id: rid, event_id: eid, sender, ts, content, is_encrypted };
                if let Some(cell) = EVENT_SINK.get() {
                    if let Ok(mut guard) = cell.lock() {
                        if let Some(sink) = guard.as_mut() {
                            let _ = sink.add(evt);
                        }
                    }
                }
            });

            let mut settings = SyncSettings::default();
            loop {
                if let Err(e) = client.sync_once(settings.clone()).await {
                    eprintln!("[matrix][sync] error: {}", e);
                    // brief backoff on error
                    tokio::time::sleep(std::time::Duration::from_secs(2)).await;
                } else {
                    // small delay to avoid tight loop; real apps should use long-polling sync
                    tokio::time::sleep(std::time::Duration::from_millis(300)).await;
                }
            }
        }
    });
    SYNC_HANDLE.set(handle).map_err(|_| "Sync already running".to_string())?;
    Ok(())
}

#[frb]
pub fn stop_sync() -> Result<(), String> {
    if let Some(handle) = SYNC_HANDLE.take() {
        handle.abort();
    }
    Ok(())
}
