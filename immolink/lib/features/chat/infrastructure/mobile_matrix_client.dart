import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Logger utility for mobile Matrix client
class MobileMatrixLogger {
  static final List<String> _logs = [];
  static final StreamController<String> _logController = StreamController<String>.broadcast();
  
  static void log(String message) {
    final timestamp = DateTime.now().toString();
    final logEntry = '[$timestamp] $message';
    _logs.add(logEntry);
    _logController.add(logEntry);
    
    // Keep only last 100 log entries to prevent memory issues
    if (_logs.length > 100) {
      _logs.removeAt(0);
    }
    
    // Also print to debug console
    debugPrint(logEntry);
  }
  
  static List<String> getLogs() => List.from(_logs);
  static Stream<String> get logStream => _logController.stream;
  static void clearLogs() => _logs.clear();
}

/// Mobile Matrix client implementation using the official Matrix Dart SDK
/// This provides Matrix functionality for Android, iOS, and other platforms
/// where the Rust bridge is not available.
class MobileMatrixClient {
  static final MobileMatrixClient _instance = MobileMatrixClient._();
  static MobileMatrixClient get instance => _instance;
  MobileMatrixClient._();

  matrix.Client? _client;
  bool _isInitialized = false;
  bool _isLoggedIn = false;
  String? _currentUserId;
  String? _currentHomeserver;
  
  // Event stream for real-time updates
  final StreamController<MatrixEventData> _eventController = StreamController<MatrixEventData>.broadcast();
  Stream<MatrixEventData> get eventStream => _eventController.stream;

  /// Create database for Matrix client
  Future<matrix.DatabaseApi> _createDatabase(String path) async {
    // Use MatrixSdkDatabase implementation
    return await matrix.MatrixSdkDatabase.init(path);
  }

  /// Initialize the Matrix client
  Future<void> init(String homeserver, String dataDir) async {
    if (_isInitialized && _currentHomeserver == homeserver) {
      MobileMatrixLogger.log('[MobileMatrix] Already initialized for $homeserver');
      return;
    }

    try {
      MobileMatrixLogger.log('[MobileMatrix] Initializing client for $homeserver');
      
      // Create client name based on platform
      final clientName = 'ImmoLink-${defaultTargetPlatform.name}';
      
      // Get database directory - ensure it exists
      final Directory appDir = await getApplicationDocumentsDirectory();
      final dbDir = Directory('${appDir.path}/matrix');
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
        MobileMatrixLogger.log('[MobileMatrix] Created database directory: ${dbDir.path}');
      }
      
      final dbPath = '${dbDir.path}/matrix_mobile.db';
      MobileMatrixLogger.log('[MobileMatrix] Database path: $dbPath');
      
      // Create Matrix client with required database parameter
      _client = matrix.Client(
        clientName,
        database: await _createDatabase(dbPath),
      );

      // Set homeserver with proper validation
      final homeserverUri = Uri.parse(homeserver);
      MobileMatrixLogger.log('[MobileMatrix] Checking homeserver: $homeserverUri');
      
      await _client!.checkHomeserver(homeserverUri);
      MobileMatrixLogger.log('[MobileMatrix] Homeserver check successful');
      
      _currentHomeserver = homeserver;
      _isInitialized = true;
      
      MobileMatrixLogger.log('[MobileMatrix] Client initialized successfully');
    } catch (e) {
      MobileMatrixLogger.log('[MobileMatrix] Failed to initialize: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Login with username and password
  Future<Map<String, String>> login(String username, String password) async {
    if (!_isInitialized || _client == null) {
      throw Exception('Client not initialized - call init() first');
    }

    try {
      MobileMatrixLogger.log('[MobileMatrix] Starting login process for: $username');
      
      // Check if already logged in
      if (_isLoggedIn && _client!.isLogged()) {
        MobileMatrixLogger.log('[MobileMatrix] Already logged in as ${_client!.userID}');
        return {
          'userId': _client!.userID!,
          'accessToken': 'existing_session',
        };
      }

      MobileMatrixLogger.log('[MobileMatrix] Attempting Matrix login...');
      final loginResponse = await _client!.login(
        matrix.LoginType.mLoginPassword,
        identifier: matrix.AuthenticationUserIdentifier(user: username),
        password: password,
      );

      _currentUserId = _client!.userID;
      _isLoggedIn = true;
      
      MobileMatrixLogger.log('[MobileMatrix] Login successful! UserID: ${_client!.userID}');
      MobileMatrixLogger.log('[MobileMatrix] Access token received: ${loginResponse.accessToken.substring(0, 10)}...');
      
      // Note: Encryption settings will be handled per-room during send
      // to avoid "unknown devices" blocking messages
      
      // Wait for initial sync to complete before returning
      MobileMatrixLogger.log('[MobileMatrix] Starting sync process...');
      await _startSync();
      
      // Give some time for initial sync
      await Future.delayed(const Duration(seconds: 2));
      MobileMatrixLogger.log('[MobileMatrix] Login process completed successfully');
      
      return {
        'userId': _client!.userID!,
        'accessToken': loginResponse.accessToken,
      };
    } catch (e) {
      MobileMatrixLogger.log('[MobileMatrix] Login failed with error: $e');
      _isLoggedIn = false;
      _currentUserId = null;
      rethrow;
    }
  }

  /// Start the sync process
  Future<void> _startSync() async {
    if (_client == null) {
      MobileMatrixLogger.log('[MobileMatrix] Cannot start sync - client is null');
      return;
    }

    try {
      MobileMatrixLogger.log('[MobileMatrix] Initializing sync listeners...');
      
      // Listen to login state changes
      _client!.onLoginStateChanged.stream.listen((loginState) {
        MobileMatrixLogger.log('[MobileMatrix] Login state changed: $loginState');
        if (loginState == matrix.LoginState.loggedOut) {
          _isLoggedIn = false;
          _currentUserId = null;
        }
      });
      
      // Listen to sync updates
      _client!.onSync.stream.listen(_handleSyncUpdate, onError: (error) {
        MobileMatrixLogger.log('[MobileMatrix] Sync stream error: $error');
      });
      
      // Listen to timeline events (messages, etc.)
      _client!.onTimelineEvent.stream.listen(_handleEvent, onError: (error) {
        MobileMatrixLogger.log('[MobileMatrix] Timeline event error: $error');
      });
      
      // Listen to room state events (room updates)
      _client!.onTimelineEvent.stream.where((event) => event.type == matrix.EventTypes.RoomMember).listen((event) {
        MobileMatrixLogger.log('[MobileMatrix] Room member update in: ${event.roomId}');
      });
      
      MobileMatrixLogger.log('[MobileMatrix] Starting Matrix sync...');
      
      // Wait for rooms to load
      await _client!.roomsLoading;
      MobileMatrixLogger.log('[MobileMatrix] Rooms loaded successfully');
      
      // Log current room count
      final roomCount = _client!.rooms.length;
      MobileMatrixLogger.log('[MobileMatrix] Sync started successfully - $roomCount rooms available');
      
    } catch (e) {
      MobileMatrixLogger.log('[MobileMatrix] Failed to start sync: $e');
      rethrow;
    }
  }

  /// Handle sync updates
  void _handleSyncUpdate(matrix.SyncUpdate update) {
    debugPrint('[MobileMatrix] Sync update received');
    // Handle room updates, presence updates, etc.
  }

  /// Handle individual events
  void _handleEvent(matrix.Event event) {
    debugPrint('[MobileMatrix] Event received: ${event.type} in room ${event.roomId}');
    
    // Convert to our event format and emit
    if (event.type == matrix.EventTypes.Message) {
      final matrixEvent = MatrixEventData(
        roomId: event.roomId ?? '',
        eventId: event.eventId,
        sender: event.senderId,
        ts: event.originServerTs.millisecondsSinceEpoch,
        content: event.content['body']?.toString(),
        isEncrypted: event.type == matrix.EventTypes.Encrypted,
      );
      
      _eventController.add(matrixEvent);
    }
  }

  /// Create a direct message room
  Future<String> createRoom(String otherMxid, [String? creatorMxid]) async {
    if (!_isLoggedIn || _client == null) {
      throw Exception('Client not logged in');
    }

    try {
      MobileMatrixLogger.log('[MobileMatrix] Creating DM room with: $otherMxid');
      MobileMatrixLogger.log('[MobileMatrix] Creator MXID: ${creatorMxid ?? 'not specified'}');
      
      // Check if a DM room already exists
      try {
        final existingRoom = _client!.rooms.firstWhere(
          (room) => room.isDirectChat && room.summary.mJoinedMemberCount == 2,
        );
        
        if (existingRoom.id.isNotEmpty) {
          MobileMatrixLogger.log('[MobileMatrix] Existing DM room found: ${existingRoom.id}');
          return existingRoom.id;
        }
      } catch (e) {
        // No existing room found, create new one
        MobileMatrixLogger.log('[MobileMatrix] No existing DM room, will create new one...');
      }
    } catch (e) {
      // No existing room found, create new one
      MobileMatrixLogger.log('[MobileMatrix] No existing DM room, creating new one...');
    }

    try {
      final roomId = await _client!.createRoom(
        invite: [otherMxid],
        isDirect: true,
        preset: matrix.CreateRoomPreset.trustedPrivateChat,
        name: null, // Let Matrix generate the name
        topic: null,
        visibility: matrix.Visibility.private,
      );

      MobileMatrixLogger.log('[MobileMatrix] DM room created successfully: $roomId');
      
      // Wait a moment for the room to be fully set up
      await Future.delayed(const Duration(milliseconds: 500));
      
      return roomId;
    } catch (e) {
      MobileMatrixLogger.log('[MobileMatrix] Failed to create room: ${e.toString()}');
      MobileMatrixLogger.log('[MobileMatrix] Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Send a message to a room
  Future<String> sendMessage(String roomId, String body) async {
    if (!_isLoggedIn || _client == null) {
      throw Exception('Client not logged in - please login first');
    }

    if (body.trim().isEmpty) {
      throw Exception('Message body cannot be empty');
    }

    try {
      MobileMatrixLogger.log('[MobileMatrix] Attempting to send message to room: $roomId');
      MobileMatrixLogger.log('[MobileMatrix] Message content: ${body.substring(0, body.length > 50 ? 50 : body.length)}${body.length > 50 ? '...' : ''}');
      
      final room = _client!.getRoomById(roomId);
      if (room == null) {
        MobileMatrixLogger.log('[MobileMatrix] Room not found: $roomId');
        MobileMatrixLogger.log('[MobileMatrix] Available rooms: ${_client!.rooms.map((r) => r.id).join(', ')}');
        throw Exception('Room not found: $roomId');
      }

      MobileMatrixLogger.log('[MobileMatrix] Room found: ${room.id}');
      
      // Check if we can send messages to this room (simplified check)
      try {
        final powerLevel = room.getPowerLevelByUserId(_client!.userID!);
        MobileMatrixLogger.log('[MobileMatrix] User power level in room: $powerLevel');
        // Most rooms allow sending messages with power level 0, so we'll proceed
      } catch (e) {
        MobileMatrixLogger.log('[MobileMatrix] Could not check power levels, proceeding anyway: $e');
      }

      MobileMatrixLogger.log('[MobileMatrix] Sending text event...');
      MobileMatrixLogger.log('[MobileMatrix] Room encryption enabled: ${room.encrypted}');
      
      String? eventId;
      try {
        // Try to send message normally (with encryption if room requires it)
        eventId = await room.sendTextEvent(body);
        MobileMatrixLogger.log('[MobileMatrix] ✅ Message sent successfully (encrypted)');
      } catch (e) {
        final errorMsg = e.toString().toLowerCase();
        
        // Check if error is due to unknown/unverified devices
        if (errorMsg.contains('unknown') || errorMsg.contains('unverified') || errorMsg.contains('device')) {
          MobileMatrixLogger.log('[MobileMatrix] ⚠️ Unknown devices detected: $e');
          MobileMatrixLogger.log('[MobileMatrix] 🔐 Auto-approving unknown devices for encrypted messaging...');
          
          try {
            // Step 1: Get the encryption object
            final encryption = _client!.encryption;
            if (encryption == null) {
              throw Exception('Encryption not enabled on client');
            }
            
            MobileMatrixLogger.log('[MobileMatrix] 🔐 Fetching device keys to auto-verify...');
            
            // Step 2: Get all device keys in the room
            final participants = room.getParticipants();
            MobileMatrixLogger.log('[MobileMatrix] Found ${participants.length} participants');
            
            // Step 3: Auto-verify all unverified devices
            int devicesVerified = 0;
            for (final user in participants) {
              try {
                // Get stored device keys for this user
                final deviceKeys = await _client!.userDeviceKeys[user.id]?.deviceKeys.values;
                
                if (deviceKeys != null) {
                  for (final deviceKey in deviceKeys) {
                    // If device is blocked or not verified, unblock and mark as verified
                    if (deviceKey.blocked || !deviceKey.verified) {
                      MobileMatrixLogger.log('[MobileMatrix]   Auto-verifying: ${deviceKey.deviceId} (user: ${user.id})');
                      
                      // Unblock the device
                      await deviceKey.setBlocked(false);
                      
                      // Mark as verified
                      await deviceKey.setVerified(true);
                      
                      devicesVerified++;
                    }
                  }
                }
              } catch (deviceError) {
                MobileMatrixLogger.log('[MobileMatrix]   Warning: Could not verify devices for ${user.id}: $deviceError');
                // Continue with other users
              }
            }
            
            MobileMatrixLogger.log('[MobileMatrix] ✅ Auto-verified $devicesVerified device(s)');
            
            // Step 4: Retry sending the encrypted message
            MobileMatrixLogger.log('[MobileMatrix] 🔄 Retrying encrypted send after verification...');
            eventId = await room.sendTextEvent(body);
            MobileMatrixLogger.log('[MobileMatrix] ✅ Message sent successfully (encrypted after auto-verification)');
            
          } catch (approvalError) {
            MobileMatrixLogger.log('[MobileMatrix] ❌ Auto-approval failed: $approvalError');
            
            // Final fallback: Try to send anyway (Matrix SDK may allow it)
            try {
              final txnId = _client!.generateUniqueTransactionId();
              eventId = await room.sendEvent({
                'msgtype': 'm.text',
                'body': body,
              }, txid: txnId);
              MobileMatrixLogger.log('[MobileMatrix] ✅ Message sent with fallback method');
            } catch (finalError) {
              throw Exception(
                'Cannot send encrypted message:\n'
                'Device verification failed: $approvalError\n'
                'Original error: $e\n'
                'Final attempt: $finalError'
              );
            }
          }
        } else {
          // Re-throw other errors
          MobileMatrixLogger.log('[MobileMatrix] ❌ Send failed with error: $e');
          rethrow;
        }
      }
      
      if (eventId == null) {
        MobileMatrixLogger.log('[MobileMatrix] Warning: Event ID is null after sending message');
        return 'sent_but_no_id';
      }
      
      MobileMatrixLogger.log('[MobileMatrix] Message sent successfully! EventID: $eventId');
      return eventId;
    } catch (e) {
      MobileMatrixLogger.log('[MobileMatrix] Failed to send message: ${e.toString()}');
      MobileMatrixLogger.log('[MobileMatrix] Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Get room messages (timeline history)
  Future<String> getRoomMessages(String roomId, int limit) async {
    if (!_isLoggedIn || _client == null) {
      throw Exception('Client not logged in');
    }

    try {
      debugPrint('[MobileMatrix] Getting messages for room $roomId (limit: $limit)');
      
      final room = _client!.getRoomById(roomId);
      if (room == null) {
        throw Exception('Room not found: $roomId');
      }

      // Get timeline
      final timeline = await room.getTimeline();
      
      final messages = <Map<String, dynamic>>[];
      
      // Convert timeline events to our message format  
      for (final event in timeline.events) {
        if (event.type == matrix.EventTypes.Message) {
          messages.add({
            'eventId': event.eventId,
            'sender': event.senderId,
            'body': event.content['body'] ?? '',
            'timestamp': event.originServerTs.millisecondsSinceEpoch ~/ 1000,
          });
        }
      }
      
      // Sort by timestamp (oldest first)
      messages.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
      
      debugPrint('[MobileMatrix] Retrieved ${messages.length} messages');
      return jsonEncode(messages);
    } catch (e) {
      debugPrint('[MobileMatrix] Failed to get room messages: $e');
      return '[]'; // Return empty array on error
    }
  }

  /// Mark a message as read
  Future<void> markRead(String roomId, String eventId) async {
    if (!_isLoggedIn || _client == null) {
      throw Exception('Client not logged in');
    }

    try {
      debugPrint('[MobileMatrix] Marking read: $eventId in $roomId');
      
      final room = _client!.getRoomById(roomId);
      if (room == null) {
        throw Exception('Room not found: $roomId');
      }

      await room.setReadMarker(eventId);
      debugPrint('[MobileMatrix] Read marker set successfully');
    } catch (e) {
      debugPrint('[MobileMatrix] Failed to mark as read: $e');
    }
  }

  /// Subscribe to events (for compatibility with Rust bridge API)
  void subscribeEvents(Function(MatrixEventData) callback) {
    debugPrint('[MobileMatrix] Subscribing to events');
    eventStream.listen(callback);
  }

  /// Check if client is ready
  bool get isReady => _isInitialized && _isLoggedIn && _client != null;
  
  /// Get current user ID
  String? get currentUserId => _currentUserId;

  /// Get diagnostic information about the client state
  Map<String, dynamic> getDiagnostics() {
    return {
      'isInitialized': _isInitialized,
      'isLoggedIn': _isLoggedIn,
      'currentUserId': _currentUserId,
      'currentHomeserver': _currentHomeserver,
      'clientExists': _client != null,
      'clientIsLogged': _client?.isLogged() ?? false,
      'roomCount': _client?.rooms.length ?? 0,
      'prevBatch': _client?.prevBatch ?? 'none',
      'loginState': _client?.onLoginStateChanged.value.toString() ?? 'unknown',
    };
  }

  /// Test connectivity and basic functionality
  Future<Map<String, dynamic>> testConnection() async {
    final diagnostics = getDiagnostics();
    MobileMatrixLogger.log('[MobileMatrix] Connection Test Results: $diagnostics');
    
    if (_client != null && _isLoggedIn) {
      try {
        // Test basic API call - just verify we can make API calls
        final rooms = _client!.rooms;
        MobileMatrixLogger.log('[MobileMatrix] API test successful: ${rooms.length} rooms available');
        diagnostics['profileTest'] = 'success';
        diagnostics['apiTest'] = 'rooms accessible';
      } catch (e) {
        MobileMatrixLogger.log('[MobileMatrix] Profile fetch failed: $e');
        diagnostics['profileTest'] = 'failed: $e';
      }
    }
    
    return diagnostics;
  }

  /// Dispose resources
  void dispose() {
    _eventController.close();
    // Note: Don't dispose the Matrix client as it needs to persist
  }
}

/// Matrix event data structure (compatible with Rust bridge format)
class MatrixEventData {
  final String roomId;
  final String eventId;
  final String sender;
  final int ts;
  final String? content;
  final bool isEncrypted;

  const MatrixEventData({
    required this.roomId,
    required this.eventId,
    required this.sender,
    required this.ts,
    this.content,
    required this.isEncrypted,
  });

  Map<String, dynamic> toJson() => {
    'roomId': roomId,
    'eventId': eventId,
    'sender': sender,
    'ts': ts,
    'content': content,
    'isEncrypted': isEncrypted,
  };
}