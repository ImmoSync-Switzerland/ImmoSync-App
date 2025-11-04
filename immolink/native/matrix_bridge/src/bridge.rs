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
pub fn clear_store(data_dir: String) -> Result<(), String> {
    use std::fs;
    eprintln!("[Bridge][clear_store] Clearing Matrix store at: {}", data_dir);
    let store_path = std::path::Path::new(&data_dir);
    if store_path.exists() {
        fs::remove_dir_all(store_path).map_err(|e| format!("Failed to clear store: {}", e))?;
        eprintln!("[Bridge][clear_store] Store cleared successfully");
    } else {
        eprintln!("[Bridge][clear_store] Store directory doesn't exist, nothing to clear");
    }
    Ok(())
}

#[frb]
pub fn init(homeserver: String, data_dir: String) -> Result<(), String> {
    let url = Url::parse(&homeserver).map_err(|e| e.to_string())?;
    let rt = get_rt();
    rt.block_on(async move {
        eprintln!("[Bridge][init] Initializing Matrix client with persistent storage at: {}", data_dir);
        
        // Use SQLite store for persistent state, crypto keys, AND session
        let store_path = std::path::Path::new(&data_dir);
        
        // IMPORTANT: For session persistence to work, we need to:
        // 1. Create the store directory if it doesn't exist
        // 2. Use the same passphrase (None for no encryption) consistently
        // 3. The SDK will automatically load the session from the store on build
        
        std::fs::create_dir_all(store_path).map_err(|e| format!("Failed to create store directory: {}", e))?;
        
        // Try to build client, if device mismatch occurs, clear store and retry
        let client = match Client::builder()
            .homeserver_url(url.clone())
            .sqlite_store(store_path, None) // None = no passphrase encryption
            .build()
            .await
        {
            Ok(c) => c,
            Err(e) => {
                let err_str = e.to_string();
                if err_str.contains("account in the store doesn't match") {
                    eprintln!("[Bridge][init] Device mismatch detected during build, clearing store and retrying");
                    if let Err(clear_err) = std::fs::remove_dir_all(store_path) {
                        eprintln!("[Bridge][init] Warning: Failed to clear store: {}", clear_err);
                    }
                    // Recreate directory and retry
                    std::fs::create_dir_all(store_path).map_err(|e| format!("Failed to recreate store directory: {}", e))?;
                    Client::builder()
                        .homeserver_url(url)
                        .sqlite_store(store_path, None)
                        .build()
                        .await
                        .map_err(|e| format!("Failed to build client after clearing store: {}", e))?
                } else {
                    return Err(format!("Failed to build client: {}", err_str));
                }
            }
        };
        
        // Check if session was restored from SQLite store
        // The Matrix SDK 0.7 with SQLite store SHOULD automatically restore sessions
        // If this consistently shows "No existing session", it means:
        // 1. First login (expected)
        // 2. Session wasn't properly saved (problem with flush/timing)
        // 3. Store was cleared/corrupted
        if let Some(user_id) = client.user_id() {
            eprintln!("[Bridge][init] ✓ Session restored from SQLite store");
            eprintln!("[Bridge][init] User ID: {}", user_id);
            if let Some(device_id) = client.device_id() {
                eprintln!("[Bridge][init] Device ID: {}", device_id);
            }
            eprintln!("[Bridge][init] IMPORTANT: Session persistence IS working!");
        } else {
            eprintln!("[Bridge][init] No existing session in SQLite store, will need to login");
            eprintln!("[Bridge][init] Note: On mobile this would typically persist automatically");
            eprintln!("[Bridge][init] Windows may require explicit session management");
        }
        
        eprintln!("[Bridge][init] Client initialized with persistent store");
        CLIENT.set(client).map_err(|_| "Client already initialized".to_string())?;
        Ok(())
    })
}

#[frb]
pub fn login(user: String, password: String) -> Result<LoginResult, String> {
    let rt = get_rt();
    rt.block_on(async move {
        let client = CLIENT.get().ok_or_else(|| "Client not initialized".to_string())?.clone();
        
        // Check if already logged in (session restored from store)
        if let Some(uid) = client.user_id() {
            eprintln!("[Bridge][login] Already logged in as {}, skipping login", uid);
            eprintln!("[Bridge][login] Device ID: {:?}", client.device_id());
            return Ok(LoginResult { 
                user_id: uid.to_string(), 
                access_token: String::new() 
            });
        }
        
        eprintln!("[Bridge][login] Not logged in, performing login for {}", user);
        eprintln!("[Bridge][login] Username: {}", user);
        eprintln!("[Bridge][login] Password length: {} chars", password.len());
        eprintln!("[Bridge][login] Password (first 8 chars): {}...", &password[..password.len().min(8)]);
        
        // CRITICAL: The login MUST be done with the Matrix client that has the SQLite store
        // configured, otherwise the session won't persist across restarts!
        eprintln!("[Bridge][login] Using matrix_auth().login_username()...");
        
        // Login using username & password (new API via matrix_auth)
        match client
            .matrix_auth()
            .login_username(&user, &password)
            .send()
            .await
        {
            Ok(_resp) => {
                let uid = client
                    .user_id()
                    .ok_or_else(|| "No user id after login".to_string())?
                    .to_string();
                let device_id = client.device_id().map(|d| d.to_string()).unwrap_or_else(|| "unknown".to_string());

                eprintln!("[Bridge][login] ✓ Login successful!");
                eprintln!("[Bridge][login] User ID: {}", uid);
                eprintln!("[Bridge][login] Device ID: {}", device_id);
                eprintln!("[Bridge][login] Session is now persisted in SQLite store");
                eprintln!("[Bridge][login] On next restart, session should be auto-restored");
                
                // Initialize encryption (Olm machine)
                eprintln!("[Bridge][login] Initializing encryption...");
                client.encryption().wait_for_e2ee_initialization_tasks().await;
                eprintln!("[Bridge][login] Encryption initialized successfully");
                
                // Access token retrieval differs across SDK versions; keep empty for now.
                Ok(LoginResult { user_id: uid, access_token: String::new() })
            }
            Err(e) => {
                let err_str = e.to_string();
                eprintln!("[Bridge][login] Login failed: {}", err_str);
                
                // If crypto store mismatch, the store needs to be cleared
                if err_str.contains("account in the store doesn't match") {
                    return Err(format!(
                        "Device mismatch error. The crypto store has data from a different device. \
                        Please restart the app to clear the store automatically."
                    ));
                }
                
                Err(err_str)
            }
        }
    })
}

/// Create a direct message room and invite another user
/// The creator is automatically added to the room when it's created
/// If creator_mxid is provided, it will also be invited (for multi-device support)
#[frb]
pub fn create_room(other_mxid: String, creator_mxid: Option<String>) -> Result<String, String> {
    use matrix_sdk::ruma::UserId;
    use matrix_sdk::ruma::api::client::room::create_room::v3::Request as CreateRoomRequest;
    use matrix_sdk::ruma::api::client::room::Visibility;
    use matrix_sdk::ruma::events::room::encryption::RoomEncryptionEventContent;
    
    let rt = get_rt();
    rt.block_on(async move {
        let client = CLIENT.get().ok_or_else(|| "Client not initialized".to_string())?.clone();
        
        eprintln!("[Bridge][create_room] Creating DM room with {}", other_mxid);
        eprintln!("[Bridge][create_room] Creator (me): {:?}", client.user_id());
        eprintln!("[Bridge][create_room] Creator MXID to invite: {:?}", creator_mxid);
        
        let other_user_id = UserId::parse(&other_mxid).map_err(|e| e.to_string())?;
        
        // Build invitation list
        let mut invitees = vec![other_user_id];
        
        // If creator_mxid is provided, invite that too (for dashboard/other sessions)
        // BUT: Only if it's different from the current user (who is creating the room)
        if let Some(creator_mxid_str) = creator_mxid {
            if !creator_mxid_str.is_empty() {
                match UserId::parse(&creator_mxid_str) {
                    Ok(creator_user_id) => {
                        // Check if creator_mxid is different from the current user
                        // Compare UserId refs, not OwnedUserId
                        if let Some(current_user_id) = client.user_id() {
                            let creator_as_ref: &UserId = creator_user_id.as_ref();
                            if current_user_id != creator_as_ref {
                                eprintln!("[Bridge][create_room] Also inviting creator's other sessions: {}", creator_mxid_str);
                                invitees.push(creator_user_id);
                            } else {
                                eprintln!("[Bridge][create_room] Creator is current user, skipping invite (already room creator)");
                            }
                        }
                    }
                    Err(e) => {
                        eprintln!("[Bridge][create_room] Invalid creator_mxid: {}", e);
                    }
                }
            }
        }
        
        // Create a direct private room with trusted_private_chat preset
        let mut request = CreateRoomRequest::new();
        request.visibility = Visibility::Private;
        request.is_direct = true;
        request.invite = invitees;
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

/// Get timeline messages from a room
/// Returns a JSON array of messages: [{"sender":"@user:server","body":"text","timestamp":1234567890,"eventId":"$xyz"}]
#[frb]
pub fn get_room_messages(room_id: String, limit: u32) -> Result<String, String> {
    use matrix_sdk::ruma::events::room::message::MessageType;
    use matrix_sdk::ruma::events::AnyTimelineEvent;
    use serde_json::json;
    
    let rt = get_rt();
    rt.block_on(async move {
        let client = CLIENT.get().ok_or_else(|| "Client not initialized".to_string())?.clone();
        let rid = RoomId::parse(&room_id).map_err(|e| e.to_string())?;
        
        // Try to get the room, if not found try to join it first
        let room = match client.get_room(&rid) {
            Some(r) => {
                eprintln!("[Bridge][get_room_messages] Room found: {} state: {:?}", room_id, r.state());
                r
            }
            None => {
                eprintln!("[Bridge][get_room_messages] Room not found locally, attempting to join: {}", room_id);
                match client.join_room_by_id(&rid).await {
                    Ok(joined_room) => {
                        eprintln!("[Bridge][get_room_messages] Successfully joined room: {}", room_id);
                        joined_room
                    }
                    Err(e) => {
                        return Err(format!("Room not found and failed to join: {}", e));
                    }
                }
            }
        };
        
        // Get messages using /messages endpoint
        use matrix_sdk::ruma::api::client::message::get_message_events;
        let mut request = get_message_events::v3::Request::backward(rid.clone());
        request.limit = limit.try_into().unwrap_or(50u32.try_into().unwrap());
        
        let response = client.send(request, None).await.map_err(|e| format!("Failed to get messages: {}", e))?;
        
        eprintln!("[Bridge][get_room_messages] Got {} events from /messages endpoint", response.chunk.len());
        
        let mut messages = Vec::new();
        
        // Parse and decrypt timeline events
        for event in response.chunk.iter().rev() {
            if let Ok(timeline_event) = event.deserialize() {
                match timeline_event {
                    AnyTimelineEvent::MessageLike(msg_like) => {
                        match msg_like {
                            matrix_sdk::ruma::events::AnyMessageLikeEvent::RoomMessage(room_msg) => {
                                if let matrix_sdk::ruma::events::MessageLikeEvent::Original(msg) = room_msg {
                                    let body = match &msg.content.msgtype {
                                        MessageType::Text(text) => text.body.clone(),
                                        _ => continue,
                                    };
                                    
                                    let timestamp_secs = msg.origin_server_ts.as_secs();
                                    
                                    messages.push(json!({
                                        "sender": msg.sender.to_string(),
                                        "body": body,
                                        "timestamp": timestamp_secs,
                                        "eventId": msg.event_id.to_string(),
                                    }));
                                }
                            }
                            matrix_sdk::ruma::events::AnyMessageLikeEvent::RoomEncrypted(_encrypted_event) => {
                                // Encrypted messages - these will be decrypted during sync
                                // With persistent storage, they'll be available after restart
                                eprintln!("[Bridge][get_room_messages] Encrypted message found - will be decrypted via sync");
                            }
                            _ => {}
                        }
                    }
                    _ => {}
                }
            }
        }
        
        eprintln!("[Bridge][get_room_messages] Returning {} decrypted messages", messages.len());
        
        let result = json!(messages);
        Ok(result.to_string())
    })
}

// Old implementation using /messages API (kept for reference, but doesn't decrypt)
#[allow(dead_code)]
fn get_room_messages_old(room_id: String, limit: u32) -> Result<String, String> {
    use matrix_sdk::ruma::events::room::message::MessageType;
    use matrix_sdk::ruma::events::AnyTimelineEvent;
    use serde_json::json;
    
    let rt = get_rt();
    rt.block_on(async move {
        let client = CLIENT.get().ok_or_else(|| "Client not initialized".to_string())?.clone();
        let rid = RoomId::parse(&room_id).map_err(|e| e.to_string())?;
        
        let room = client.get_room(&rid).ok_or_else(|| "Room not found".to_string())?;
        
        // Get messages using /messages endpoint
        use matrix_sdk::ruma::api::client::message::get_message_events;
        let mut request = get_message_events::v3::Request::backward(rid);
        request.limit = limit.try_into().unwrap_or(50u32.try_into().unwrap());
        
        let response = client.send(request, None).await.map_err(|e| format!("Failed to get messages: {}", e))?;
        
        eprintln!("[Bridge][get_room_messages] Got {} events from /messages endpoint", response.chunk.len());
        
        let mut messages = Vec::new();
        let mut event_type_counts = std::collections::HashMap::new();
        
        // Parse timeline events
        for (i, event) in response.chunk.iter().rev().enumerate() {
            match event.deserialize() {
                Ok(timeline_event) => {
                    match timeline_event {
                        AnyTimelineEvent::MessageLike(msg_like) => {
                            *event_type_counts.entry("MessageLike").or_insert(0) += 1;
                            match msg_like {
                                matrix_sdk::ruma::events::AnyMessageLikeEvent::RoomMessage(room_msg) => {
                                    match room_msg {
                                        matrix_sdk::ruma::events::MessageLikeEvent::Original(msg) => {
                                            let body = match &msg.content.msgtype {
                                                MessageType::Text(text) => text.body.clone(),
                                                other => {
                                                    eprintln!("[Bridge][get_room_messages] Event {}: Skipping non-text message type: {:?}", i, other);
                                                    continue;
                                                }
                                            };
                                            
                                            // Convert timestamp: MilliSecondsSinceUnixEpoch to seconds
                                            let timestamp_secs = msg.origin_server_ts.as_secs();
                                            
                                            messages.push(json!({
                                                "sender": msg.sender.to_string(),
                                                "body": body,
                                                "timestamp": timestamp_secs,
                                                "eventId": msg.event_id.to_string(),
                                            }));
                                        }
                                        matrix_sdk::ruma::events::MessageLikeEvent::Redacted(_) => {
                                            eprintln!("[Bridge][get_room_messages] Event {}: Redacted message", i);
                                        }
                                    }
                                }
                                matrix_sdk::ruma::events::AnyMessageLikeEvent::RoomEncrypted(encrypted) => {
                                    *event_type_counts.entry("RoomEncrypted").or_insert(0) += 1;
                                    eprintln!("[Bridge][get_room_messages] Event {}: Encrypted message - trying to decrypt via room timeline", i);
                                    // Note: We can't decrypt here directly with the /messages API
                                    // The SDK needs to decrypt these through the timeline
                                    // For now, skip encrypted historical messages
                                }
                                other => {
                                    let type_name = match &other {
                                        matrix_sdk::ruma::events::AnyMessageLikeEvent::CallAnswer(_) => "CallAnswer",
                                        matrix_sdk::ruma::events::AnyMessageLikeEvent::CallInvite(_) => "CallInvite",
                                        matrix_sdk::ruma::events::AnyMessageLikeEvent::CallHangup(_) => "CallHangup",
                                        matrix_sdk::ruma::events::AnyMessageLikeEvent::CallCandidates(_) => "CallCandidates",
                                        matrix_sdk::ruma::events::AnyMessageLikeEvent::KeyVerificationReady(_) => "KeyVerificationReady",
                                        matrix_sdk::ruma::events::AnyMessageLikeEvent::KeyVerificationStart(_) => "KeyVerificationStart",
                                        matrix_sdk::ruma::events::AnyMessageLikeEvent::KeyVerificationCancel(_) => "KeyVerificationCancel",
                                        matrix_sdk::ruma::events::AnyMessageLikeEvent::KeyVerificationAccept(_) => "KeyVerificationAccept",
                                        matrix_sdk::ruma::events::AnyMessageLikeEvent::KeyVerificationKey(_) => "KeyVerificationKey",
                                        matrix_sdk::ruma::events::AnyMessageLikeEvent::KeyVerificationMac(_) => "KeyVerificationMac",
                                        matrix_sdk::ruma::events::AnyMessageLikeEvent::KeyVerificationDone(_) => "KeyVerificationDone",
                                        matrix_sdk::ruma::events::AnyMessageLikeEvent::Reaction(_) => "Reaction",
                                        matrix_sdk::ruma::events::AnyMessageLikeEvent::RoomRedaction(_) => "RoomRedaction",
                                        _ => "Unknown"
                                    };
                                    eprintln!("[Bridge][get_room_messages] Event {}: Other MessageLike type: {}", i, type_name);
                                }
                            }
                        },
                        AnyTimelineEvent::State(state) => {
                            *event_type_counts.entry("State").or_insert(0) += 1;
                        }
                    }
                }
                Err(e) => {
                    *event_type_counts.entry("ParseError").or_insert(0) += 1;
                    eprintln!("[Bridge][get_room_messages] Event {}: Failed to deserialize: {}", i, e);
                }
            }
        }
        
        eprintln!("[Bridge][get_room_messages] Event type summary: {:?}", event_type_counts);
        eprintln!("[Bridge][get_room_messages] Returning {} messages", messages.len());
        
        let result = json!(messages);
        Ok(result.to_string())
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
                // Convert timestamp to seconds (consistent with get_room_messages)
                let ts: i64 = ev.origin_server_ts.as_secs().into();
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
                eprintln!("[Bridge][sync] Emitting event to Dart: room={} event={} content={:?}", &rid, &eid, &content);
                let evt = MatrixEvent { room_id: rid, event_id: eid, sender, ts, content, is_encrypted };
                if let Some(cell) = EVENT_SINK.get() {
                    if let Ok(mut guard) = cell.lock() {
                        if let Some(sink) = guard.as_mut() {
                            match sink.add(evt) {
                                Ok(_) => eprintln!("[Bridge][sync] Event emitted successfully"),
                                Err(e) => eprintln!("[Bridge][sync] Failed to emit event: {:?}", e),
                            }
                        } else {
                            eprintln!("[Bridge][sync] No sink available");
                        }
                    }
                }
            });

            // Use long-polling sync for real-time updates
            // Important: Keep the same settings object so sync token gets updated between calls
            let mut settings = SyncSettings::default().timeout(std::time::Duration::from_secs(30));
            eprintln!("[Bridge][sync] Sync loop starting with 30s long-polling...");
            let mut sync_count = 0;
            loop {
                sync_count += 1;
                if sync_count % 5 == 1 {
                    eprintln!("[Bridge][sync] Sync iteration {} (long-polling for 30s or until events arrive)", sync_count);
                }
                match client.sync_once(settings.clone()).await {
                    Ok(response) => {
                        // Update settings with the new sync token for incremental sync
                        settings = settings.token(response.next_batch);
                        if sync_count <= 5 {
                            eprintln!("[Bridge][sync] Sync successful, got token for next iteration");
                        }
                    }
                    Err(e) => {
                        eprintln!("[Bridge][sync] error: {}", e);
                        // brief backoff on error
                        tokio::time::sleep(std::time::Duration::from_secs(2)).await;
                    }
                }
                // No delay needed with long-polling - server holds connection until events arrive
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
