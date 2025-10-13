import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
      debugPrint('[MobileMatrix] Already initialized for $homeserver');
      return;
    }

    try {
      debugPrint('[MobileMatrix] Initializing client for $homeserver');
      
      // Create client name based on platform
      final clientName = 'ImmoLink-${defaultTargetPlatform.name}';
      
      // Get database directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final dbPath = '${appDir.path}/matrix_mobile.db';
      
      // Create Matrix client with required database parameter
      _client = matrix.Client(
        clientName,
        database: await _createDatabase(dbPath),
      );

      // Set homeserver
      await _client!.checkHomeserver(Uri.parse(homeserver));
      
      _currentHomeserver = homeserver;
      _isInitialized = true;
      
      debugPrint('[MobileMatrix] Client initialized successfully');
    } catch (e) {
      debugPrint('[MobileMatrix] Failed to initialize: $e');
      rethrow;
    }
  }

  /// Login with username and password
  Future<Map<String, String>> login(String username, String password) async {
    if (!_isInitialized || _client == null) {
      throw Exception('Client not initialized');
    }

    try {
      debugPrint('[MobileMatrix] Logging in as $username');
      
      final loginResponse = await _client!.login(
        matrix.LoginType.mLoginPassword,
        identifier: matrix.AuthenticationUserIdentifier(user: username),
        password: password,
      );

      _currentUserId = _client!.userID;
      _isLoggedIn = true;
      
      debugPrint('[MobileMatrix] Login successful for ${_client!.userID}');
      
      // Start sync
      await _startSync();
      
      return {
        'userId': _client!.userID!,
        'accessToken': loginResponse.accessToken,
      };
    } catch (e) {
      debugPrint('[MobileMatrix] Login failed: $e');
      rethrow;
    }
  }

  /// Start the sync process
  Future<void> _startSync() async {
    if (_client == null) return;

    try {
      debugPrint('[MobileMatrix] Starting sync...');
      
      // Listen to timeline events
      _client!.onSync.stream.listen(_handleSyncUpdate);
      _client!.onTimelineEvent.stream.listen(_handleEvent);
      
      // Start syncing
      _client!.onLoginStateChanged.stream.listen((loginState) {
        debugPrint('[MobileMatrix] Login state changed: $loginState');
      });
      
      await _client!.roomsLoading;
      debugPrint('[MobileMatrix] Sync started successfully');
    } catch (e) {
      debugPrint('[MobileMatrix] Failed to start sync: $e');
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
      debugPrint('[MobileMatrix] Creating room with $otherMxid');
      
      final roomId = await _client!.createRoom(
        invite: [otherMxid],
        isDirect: true,
        preset: matrix.CreateRoomPreset.trustedPrivateChat,
      );

      debugPrint('[MobileMatrix] Room created: $roomId');
      return roomId;
    } catch (e) {
      debugPrint('[MobileMatrix] Failed to create room: $e');
      rethrow;
    }
  }

  /// Send a message to a room
  Future<String> sendMessage(String roomId, String body) async {
    if (!_isLoggedIn || _client == null) {
      throw Exception('Client not logged in');
    }

    try {
      debugPrint('[MobileMatrix] Sending message to $roomId: $body');
      
      final room = _client!.getRoomById(roomId);
      if (room == null) {
        throw Exception('Room not found: $roomId');
      }

      final eventId = await room.sendTextEvent(body);
      debugPrint('[MobileMatrix] Message sent with eventId: $eventId');
      
      return eventId ?? 'unknown';
    } catch (e) {
      debugPrint('[MobileMatrix] Failed to send message: $e');
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