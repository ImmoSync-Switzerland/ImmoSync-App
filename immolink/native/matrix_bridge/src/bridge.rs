use flutter_rust_bridge::frb;
use matrix_sdk::{Client, config::SyncSettings};
use matrix_sdk::ruma::{RoomId};
use matrix_sdk::ruma::events::room::message::RoomMessageEventContent;
use serde::{Deserialize, Serialize};
use once_cell::sync::OnceCell;
use tokio::runtime::Runtime;
use url::Url;

static TOKIO_RT: OnceCell<Runtime> = OnceCell::new();
static CLIENT: OnceCell<Client> = OnceCell::new();

#[derive(Serialize, Deserialize)]
pub struct LoginResult {
    pub user_id: String,
    pub access_token: String,
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

#[frb]
pub fn start_sync() -> Result<(), String> {
    let rt = get_rt();
    rt.block_on(async move {
        let client = CLIENT.get().ok_or_else(|| "Client not initialized".to_string())?.clone();
        client
            .sync_once(SyncSettings::default())
            .await
            .map_err(|e| e.to_string())?;
        Ok(())
    })
}

#[frb]
pub fn stop_sync() -> Result<(), String> {
    // matrix-sdk currently manages syncing via the provided sync methods; for
    // this scaffold we don't start a persistent background sync loop.
    Ok(())
}
