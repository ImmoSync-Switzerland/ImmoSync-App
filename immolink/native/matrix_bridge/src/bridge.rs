use flutter_rust_bridge::frb;
use crate::frb_generated::StreamSink;
use matrix_sdk::{Client, config::SyncSettings, room::Room};
use matrix_sdk::ruma::{RoomId, OwnedEventId};
use matrix_sdk::ruma::api::client::receipt::create_receipt::v3::ReceiptType;
use matrix_sdk::ruma::events::receipt::ReceiptThread;
use matrix_sdk::ruma::events::room::message::{RoomMessageEventContent, OriginalSyncRoomMessageEvent, MessageType};
use matrix_sdk::ruma::events::room::member::StrippedRoomMemberEvent;
use serde::{Deserialize, Serialize};
use once_cell::sync::OnceCell;
use tokio::task::JoinHandle;
use tokio::runtime::Runtime;
use url::Url;
use std::sync::Mutex;

static TOKIO_RT: OnceCell<Runtime> = OnceCell::new();
static CLIENT: OnceCell<Client> = OnceCell::new();
static SYNC_HANDLE: OnceCell<Mutex<Option<JoinHandle<()>>>> = OnceCell::new();
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

/// Create a direct message room and invite another user
/// The creator is automatically added to the room when it's created
#[frb]
pub fn create_room(other_mxid: String) -> Result<String, String> {
    use matrix_sdk::ruma::UserId;
    use matrix_sdk::ruma::api::client::room::create_room::v3::Request as CreateRoomRequest;
    use matrix_sdk::ruma::api::client::room::Visibility;
    use matrix_sdk::ruma::events::room::encryption::RoomEncryptionEventContent;
    
    let rt = get_rt();
    rt.block_on(async move {
        let client = CLIENT.get().ok_or_else(|| "Client not initialized".to_string())?.clone();
        
        eprintln!("[Bridge][create_room] Creating DM room with {}", other_mxid);
        eprintln!("[Bridge][create_room] Creator (me): {:?}", client.user_id());
        
        let other_user_id = UserId::parse(&other_mxid).map_err(|e| e.to_string())?;
        
        // Create a direct private room with trusted_private_chat preset
        let mut request = CreateRoomRequest::new();
        request.visibility = Visibility::Private;
        request.is_direct = true;
        request.invite = vec![other_user_id];
        // preset is optional in the builder, defaults to private_chat
        // Note: The creator is automatically joined to the room
        
        let response = client.create_room(request).await.map_err(|e| {
            eprintln!("[Bridge][create_room] Failed to create room: {}", e);
            e.to_string()
        })?;
        
        let room_id = response.room_id().to_string();
        eprintln!("[Bridge][create_room] Created room: {}", room_id);
        
        // Enable encryption for the room
        let rid = response.room_id();
        if let Some(room) = client.get_room(rid) {
            eprintln!("[Bridge][create_room] Enabling encryption...");
            let enc_content = RoomEncryptionEventContent::with_recommended_defaults();
            match room.send_state_event(enc_content).await {
                Ok(_) => eprintln!("[Bridge][create_room] Encryption enabled"),
                Err(e) => eprintln!("[Bridge][create_room] Failed to enable encryption: {}", e),
            }
        }
        
        Ok(room_id)
    })
}

#[frb]
pub fn send_message(room_id: String, body: String) -> Result<String, String> {
    let rt = get_rt();
    rt.block_on(async move {
        let client = CLIENT.get().ok_or_else(|| "Client not initialized".to_string())?.clone();
        let rid = RoomId::parse(&room_id).map_err(|e| e.to_string())?;
        
        eprintln!("[Bridge][send_message] Looking for room {}", room_id);
        
        // Try to join by ID first (handles invites and returns quickly if already member)
        match client.join_room_by_id(&rid).await {
            Ok(_) => eprintln!("[Bridge][send_message] join_room_by_id succeeded"),
            Err(e) => eprintln!("[Bridge][send_message] join_room_by_id failed: {}", e),
        }
        
        // Wait and poll for room to appear (up to 5 seconds)
        let mut room = None;
        for i in 0..50 {
            if let Some(r) = client.get_room(&rid) {
                eprintln!("[Bridge][send_message] Found room after {} attempts", i + 1);
                room = Some(r);
                break;
            }
            tokio::time::sleep(std::time::Duration::from_millis(100)).await;
        }
        
        let room = room.ok_or_else(|| {
            eprintln!("[Bridge][send_message] Room {} not found in client after polling", room_id);
            format!("Room {} not found after join attempt - sync may not have received invite yet", room_id)
        })?;
        
        // Explicitly join the room object (handles accepting invites)
        match room.join().await {
            Ok(_) => eprintln!("[Bridge][send_message] room.join() succeeded"),
            Err(e) => eprintln!("[Bridge][send_message] room.join() failed: {} (may already be joined)", e),
        }
        
        // Wait a bit for state to settle
        tokio::time::sleep(std::time::Duration::from_millis(500)).await;
        
        // Send the message
        eprintln!("[Bridge][send_message] Attempting to send message");
        let content = RoomMessageEventContent::text_plain(body);
        let send_resp = room
            .send(content)
            .await
            .map_err(|e| {
                eprintln!("[Bridge][send_message] Failed to send: {}", e);
                e.to_string()
            })?;
        
        eprintln!("[Bridge][send_message] Message sent successfully: {}", send_resp.event_id);
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
        let eid: OwnedEventId = event_id
            .parse::<OwnedEventId>()
            .map_err(|e| e.to_string())?;
        let room = client
            .get_room(&rid)
            .ok_or_else(|| "Room not found".to_string())?;
        room
            .send_single_receipt(ReceiptType::Read, ReceiptThread::Unthreaded, eid)
            .await
            .map_err(|e| e.to_string())?;
        Ok(())
    })
}

#[frb]
pub fn start_sync() -> Result<(), String> {
    let rt = get_rt();
    // Spawn a background sync loop if not already running
    let cell = SYNC_HANDLE.get_or_init(|| Mutex::new(None));
    {
        let guard = cell.lock().map_err(|_| "failed to lock sync handle".to_string())?;
        if guard.is_some() {
            return Ok(());
        }
    }
    let handle = rt.spawn(async move {
        if let Some(client) = CLIENT.get() {
            let client = client.clone();
            // Auto-accept room invitations
            client.add_event_handler(|room_member: StrippedRoomMemberEvent, client: Client, room: Room| async move {
                if room_member.state_key != client.user_id().unwrap() {
                    return;
                }
                if room_member.content.membership != matrix_sdk::ruma::events::room::member::MembershipState::Invite {
                    return;
                }
                eprintln!("[Bridge][sync] Auto-accepting invitation to room: {}", room.room_id());
                if let Err(e) = room.join().await {
                    eprintln!("[Bridge][sync] Failed to auto-accept invitation: {}", e);
                } else {
                    eprintln!("[Bridge][sync] Successfully auto-accepted invitation");
                }
            });

            // Register event handler to forward message events to Dart via StreamSink
            // Note: OriginalSyncRoomMessageEvent is already decrypted by the SDK
            client.add_event_handler(|ev: OriginalSyncRoomMessageEvent, room: Room| async move {
                let rid = room.room_id().to_string();
                let eid = ev.event_id.to_string();
                let sender = ev.sender.to_string();
                let ts: i64 = i64::from(ev.origin_server_ts.0);
                // Extract plaintext (SDK has already decrypted if keys available)
                let content = match &ev.content.msgtype {
                    MessageType::Text(t) => Some(t.body.clone()),
                    MessageType::Notice(n) => Some(n.body.clone()),
                    MessageType::Emote(e) => Some(e.body.clone()),
                    _ => None,
                };
                // If we have content, message was successfully decrypted (or was plaintext)
                // Mark as encrypted=false since the content is available
                let is_encrypted = false;
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
    {
        let mut guard = cell.lock().map_err(|_| "failed to lock sync handle".to_string())?;
        *guard = Some(handle);
    }
    Ok(())
}

#[frb]
pub fn stop_sync() -> Result<(), String> {
    if let Some(cell) = SYNC_HANDLE.get() {
        if let Ok(mut guard) = cell.lock() {
            if let Some(handle) = guard.take() {
                handle.abort();
            }
        }
    }
    Ok(())
}
