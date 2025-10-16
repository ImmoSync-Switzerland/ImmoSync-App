import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:convert';
import 'package:immosync/core/config/db_config.dart';
import 'package:immosync/features/chat/domain/models/chat_message.dart';
import 'package:immosync/features/chat/domain/models/conversation.dart';
import 'dart:io';
import 'package:immosync/core/crypto/e2ee_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:immosync/bridge.dart' as frb; // FRB generated helpers
import 'package:immosync/features/chat/infrastructure/matrix_chat_service.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';

class ChatService {
  final String _apiUrl = DbConfig.apiUrl;
  final Map<String, List<int>> _attachmentCache = {};
  
  /// Get headers with authorization token if available
  Map<String, String> _getHeaders({Ref? ref}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (ref != null) {
      try {
        final auth = ref.read(authProvider);
        final token = auth.sessionToken;
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        print('[ChatService] Could not get auth token: $e');
      }
    }
    return headers;
  }

  Future<List<Conversation>> getConversationsForUser(String userId) async {
    final response = await http.get(
      Uri.parse('$_apiUrl/conversations/user/$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final all = data.map((json) => Conversation.fromMap(json)).toList();
      // Matrix-only: keep only conversations that already have a Matrix room mapping
      // Filter by existing mapping using new optimized by-users route when possible
      final futures = all.map((c) async {
        final other = c.otherParticipantId ?? '';
        if (other.isEmpty) return null;
        try {
          final byUsers = await http.get(
            Uri.parse('$_apiUrl/matrix/rooms/by-users/$userId/$other'),
            headers: {'Content-Type': 'application/json'},
          );
          if (byUsers.statusCode == 200) return c;
        } catch (_) {}
        // Fallback to per-conversation mapping check
        try {
          final mr = await http.get(
            Uri.parse('$_apiUrl/conversations/${c.id}/matrix-room'),
            headers: {'Content-Type': 'application/json'},
          );
          if (mr.statusCode == 200) return c;
        } catch (_) {}
        return null;
      }).toList();
      final results = await Future.wait(futures);
      return results.whereType<Conversation>().toList();
    }
    throw Exception('Failed to load conversations');
  }

  Future<List<Conversation>> getConversations() async {
    // Fallback method - this should be replaced with user-specific calls
    final response = await http.get(
      Uri.parse(
          '$_apiUrl/conversations/user/current'), // Will need current user ID
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Conversation.fromMap(json)).toList();
    }
    return []; // Return empty list instead of throwing
  }

  Future<List<ChatMessage>> getMessages(String conversationId, {Ref? ref}) async {
    print('[ChatService] Fetching messages for conversation: $conversationId');
    print('[ChatService] API URL: $_apiUrl/chat/$conversationId/messages');
    
    final response = await http.get(
      Uri.parse('$_apiUrl/chat/$conversationId/messages'),
      headers: _getHeaders(ref: ref),
    );

    print('[ChatService] Response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('[ChatService] Fetched ${data.length} messages from backend');
      return data.map((json) => ChatMessage.fromMap(json)).toList();
    }
    
    print('[ChatService] Failed to fetch messages: ${response.statusCode} - ${response.body}');
    throw Exception('Failed to fetch messages: ${response.statusCode}');
  }

  /// Ensure Matrix client is initialized, logged in, and syncing for the given user
  Future<void> ensureMatrixReady({required String userId}) async {
    await MatrixChatService.instance.ensureReadyForUser(userId);
  }

  Future<String> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    Ref? ref,
    String? otherUserId,
    // Removed misplaced import statement
  }) async {
    // Ensure Matrix native client is ready for this sender (init/login/sync)
    await MatrixChatService.instance.ensureReadyForUser(senderId);
    // Resolve Matrix roomId for this conversation (server must provide mapping)
    String? roomId = await _fetchOrCreateMatrixRoomId(
        conversationId: conversationId,
        creatorUserId: senderId,
        otherUserId: receiverId,
        ref: ref);
    if (roomId == null || roomId.isEmpty) {
      // Try to ensure/create the room immediately before aborting
      roomId = await _ensureRoom(
        conversationId: conversationId,
        creatorUserId: senderId,
        otherUserId: receiverId,
        ref: ref,
      );
      if (roomId == null || roomId.isEmpty) {
        throw Exception(
            'Matrix roomId not found for conversation $conversationId');
      }
    }
    // Send via FRB and capture Matrix event id; on room-not-found, ensure room and retry once
    try {
      // Debug log for tracing
      // ignore: avoid_print
      print('[MatrixSend] attempt -> conv=$conversationId roomId=$roomId');
      final matrixEventId =
          await frb.sendMessage(roomId: roomId, body: content);
      
      // CRITICAL: Also store in HTTP backend for persistence and search
      try {
        print('[MatrixSend] Storing message in backend: eventId=$matrixEventId');
        await _storeMessageInBackend(
          conversationId: conversationId,
          senderId: senderId,
          receiverId: receiverId,
          content: content,
          matrixRoomId: roomId,
          matrixEventId: matrixEventId,
          ref: ref,
        );
        print('[MatrixSend] Message stored in backend successfully');
      } catch (backendError) {
        // Log but don't fail - Matrix message was sent successfully
        print('[MatrixSend] WARNING: Failed to store in backend: $backendError');
      }
      
      return matrixEventId;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      // ignore: avoid_print
      print('[MatrixSend] caught error: $msg');
      final looksNoRoom = msg.contains('room not found') ||
          msg.contains('no such room') ||
          msg.contains('unknown room');
      final notInvited =
          msg.contains('not invited') || msg.contains('m_forbidden');

      // ignore: avoid_print
      print('[MatrixSend] looksNoRoom=$looksNoRoom notInvited=$notInvited');

      if (!looksNoRoom && !notInvited) {
        // ignore: avoid_print
        print('[MatrixSend] rethrowing error');
        rethrow;
      }

      // If "not invited", delete the old mapping and force recreation via SDK
      if (notInvited) {
        // ignore: avoid_print
        print(
            '[MatrixSend] not invited to room, deleting old mapping and recreating...');
        await _deleteRoomMapping(conversationId, ref);
        // Clear the old roomId to force fetching the new one
        roomId = null;
      }

      // Attempt to (re)create/ensure the room and retry once
      // ignore: avoid_print
      print('[MatrixSend] room missing, ensuring + retrying once...');
      final newRoomId = await _ensureRoom(
        conversationId: conversationId,
        creatorUserId: senderId,
        otherUserId: receiverId,
        ref: ref,
      );
      if (newRoomId != null && newRoomId.isNotEmpty) {
        roomId = newRoomId;
      }
      // Wait longer for background sync to pick up the newly created room
      // ignore: avoid_print
      print('[MatrixSend] waiting for sync to fetch new room...');
      await Future.delayed(const Duration(seconds: 3));
      // Re-fetch mapping in case a different roomId was created
      roomId ??= await _fetchOrCreateMatrixRoomId(
        conversationId: conversationId,
        creatorUserId: senderId,
        otherUserId: receiverId,
        ref: ref,
      );
      if (roomId == null || roomId.isEmpty) {
        throw Exception('Send failed: unable to ensure Matrix room');
      }
      // ignore: avoid_print
      print('[MatrixSend] retry -> conv=$conversationId roomId=$roomId');
      try {
        // ignore: avoid_print
        print('[MatrixSend] calling frb.sendMessage with new roomId...');
        final matrixEventId =
            await frb.sendMessage(roomId: roomId, body: content);
        // ignore: avoid_print
        print(
            '[MatrixSend] SUCCESS! Message sent with event ID: $matrixEventId');
        
        // Store in backend (retry path)
        try {
          await _storeMessageInBackend(
            conversationId: conversationId,
            senderId: senderId,
            receiverId: receiverId,
            content: content,
            matrixRoomId: roomId,
            matrixEventId: matrixEventId,
            ref: ref,
          );
        } catch (backendError) {
          print('[MatrixSend] WARNING: Failed to store in backend (retry): $backendError');
        }
        
        return matrixEventId;
      } catch (e2) {
        final msg2 = e2.toString().toLowerCase();
        final stillNoRoom = msg2.contains('room not found') ||
            msg2.contains('no such room') ||
            msg2.contains('unknown room');
        if (!stillNoRoom) rethrow;
        // Last attempt: wait a bit longer for sync to catch up and try once more
        // ignore: avoid_print
        print(
            '[MatrixSend] still missing after ensure; waiting 2s and trying final time...');
        await Future.delayed(const Duration(seconds: 2));
        final finalEventId =
            await frb.sendMessage(roomId: roomId, body: content);
        
        // Store in backend (final attempt path)
        try {
          await _storeMessageInBackend(
            conversationId: conversationId,
            senderId: senderId,
            receiverId: receiverId,
            content: content,
            matrixRoomId: roomId,
            matrixEventId: finalEventId,
            ref: ref,
          );
        } catch (backendError) {
          print('[MatrixSend] WARNING: Failed to store in backend (final): $backendError');
        }
        
        return finalEventId;
      }
    }
  }

  Future<String?> _fetchOrCreateMatrixRoomId({
    required String conversationId,
    required String creatorUserId,
    required String otherUserId,
    Ref? ref,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    // Attach Authorization if available
    try {
      if (ref != null) {
        // lazy import to avoid circular
        // ignore: avoid_dynamic_calls
        final auth = ref.read(authProvider);
        final token = auth.sessionToken;
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }
    } catch (_) {}
    // Expect backend to expose mapping endpoint
    final res = await http.get(
      Uri.parse('$_apiUrl/conversations/$conversationId/matrix-room'),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data['matrixRoomId'] ?? data['roomId'] ?? data['matrix_room_id'];
    }
    if (res.statusCode == 404) {
      if (otherUserId.isEmpty) {
        // Without other user, we cannot ensure the room; return null
        return null;
      }
      // Create room via SDK instead of backend HTTP API
      return await _ensureRoom(
        conversationId: conversationId,
        creatorUserId: creatorUserId,
        otherUserId: otherUserId,
        ref: ref,
      );
    }
    return null;
  }

  /// Ensure/create the Matrix room mapping via SDK and return the roomId if successful.
  Future<String?> _ensureRoom({
    required String conversationId,
    required String creatorUserId,
    required String otherUserId,
    Ref? ref,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    try {
      if (ref != null) {
        final auth = ref.read(authProvider);
        final token = auth.sessionToken;
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }
    } catch (_) {}

    // First check if other user has Matrix account and get their MXID
    String? otherMxid = await _getMatrixMxid(otherUserId);
    if (otherMxid == null || otherMxid.isEmpty) {
      // ignore: avoid_print
      print(
          '[MatrixRoom] Other user has no Matrix account, need to provision first');
      // Call backend to provision the other user
      final primaryHost = DbConfig.primaryHost;
      final provisionUri = Uri.parse('$primaryHost/api/matrix/provision');
      // ignore: avoid_print
      print('[MatrixRoom] Provisioning user $otherUserId at $provisionUri');
      final provResp = await http.post(
        provisionUri,
        headers: headers,
        body: json.encode({'userId': otherUserId}),
      );
      // ignore: avoid_print
      print(
          '[MatrixRoom] Provision response: status=${provResp.statusCode} body=${provResp.body}');
      if (provResp.statusCode < 200 || provResp.statusCode >= 300) {
        // ignore: avoid_print
        print('[MatrixRoom] Failed to provision other user: ${provResp.body}');
        return null;
      }
      // Retry getting MXID and update the variable
      otherMxid = await _getMatrixMxid(otherUserId);
      if (otherMxid == null || otherMxid.isEmpty) {
        // ignore: avoid_print
        print('[MatrixRoom] Still no MXID after provisioning');
        return null;
      }
    }

    // Get creator's MXID so we can invite their other sessions (e.g., dashboard)
    String? creatorMxid = await _getMatrixMxid(creatorUserId);
    if (creatorMxid == null || creatorMxid.isEmpty) {
      // ignore: avoid_print
      print('[MatrixRoom] Creator has no Matrix account MXID');
      // This shouldn't happen since creator is current user, but handle gracefully
      creatorMxid = null;
    }

    // Create room using SDK (mobile app's session)
    // SDK creation is more reliable for mobile because the room exists in the same session
    try {
      // ignore: avoid_print
      print(
          '[MatrixRoom] Creating room with SDK, otherMxid: $otherMxid, creatorMxid: $creatorMxid');
      final roomId = await frb.createRoom(
        otherMxid: otherMxid,
        creatorMxid:
            creatorMxid, // Pass creator's MXID to invite their other sessions
      );
      // ignore: avoid_print
      print('[MatrixRoom] Created room via SDK: $roomId');

      // Important: Wait for room creation and invitation to propagate
      await Future.delayed(const Duration(seconds: 2));

      // Persist mapping to backend so dashboard can discover it
      final primaryHost = DbConfig.primaryHost;
      final persistUrl = '$primaryHost/api/matrix/rooms/persist-mapping';
      // ignore: avoid_print
      print('[MatrixRoom] Persisting mapping to backend: $persistUrl');

      final persistResp = await http.post(
        Uri.parse(persistUrl),
        headers: headers,
        body: json.encode({
          'conversationId': conversationId,
          'roomId': roomId,
          'participants': [creatorUserId, otherUserId],
        }),
      );

      if (persistResp.statusCode >= 200 && persistResp.statusCode < 300) {
        // ignore: avoid_print
        print('[MatrixRoom] Successfully persisted mapping');
        return roomId;
      } else {
        // ignore: avoid_print
        print('[MatrixRoom] Failed to persist mapping: ${persistResp.body}');
        // Still return roomId - mobile app can use it even if persistence failed
        return roomId;
      }
    } catch (e) {
      // ignore: avoid_print
      print('[MatrixRoom] Failed to create room via SDK: $e');
      return null;
    }
  }

  /// Get the Matrix MXID for a user from backend
  Future<String?> _getMatrixMxid(String userId) async {
    try {
      // Use primaryHost (localhost proxy) to match where provisioning happens
      final primaryHost = DbConfig.primaryHost;
      final url = '$primaryHost/api/matrix/accounts/$userId/mxid';
      // ignore: avoid_print
      print('[MatrixRoom] Getting MXID from $url');
      final resp = await http.get(Uri.parse(url));
      // ignore: avoid_print
      print(
          '[MatrixRoom] MXID response: status=${resp.statusCode} body=${resp.body}');
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final mxid = data['mxid'] as String?;
        // ignore: avoid_print
        print('[MatrixRoom] Parsed MXID: $mxid');
        return mxid;
      }
    } catch (e) {
      // ignore: avoid_print
      print('[MatrixRoom] Failed to get MXID for user $userId: $e');
    }
    return null;
  }

  /// Delete an old Matrix room mapping to force recreation
  Future<void> _deleteRoomMapping(String conversationId, Ref? ref) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (ref != null) {
        final auth = ref.read(authProvider);
        final token = auth.sessionToken;
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }
      final resp = await http.delete(
        Uri.parse('$_apiUrl/matrix/rooms/mapping/$conversationId'),
        headers: headers,
      );
      if (resp.statusCode == 200) {
        // ignore: avoid_print
        print(
            '[MatrixRoom] Deleted old mapping for conversation $conversationId');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[MatrixRoom] Failed to delete mapping: $e');
    }
  }

  // Public helper for UI layers to resolve room mapping without duplicating logic
  Future<String?> getMatrixRoomIdForConversation({
    required String conversationId,
    required String currentUserId,
    required String otherUserId,
  }) async {
    return _fetchOrCreateMatrixRoomId(
        conversationId: conversationId,
        creatorUserId: currentUserId,
        otherUserId: otherUserId);
  }

  /// Store a Matrix message in the HTTP backend for persistence
  /// This ensures messages are searchable and survive Matrix sync issues
  Future<void> _storeMessageInBackend({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    required String matrixRoomId,
    required String matrixEventId,
    Ref? ref,
  }) async {
    print('[ChatService] Storing message in backend: $conversationId');
    final response = await http.post(
      Uri.parse('$_apiUrl/chat/$conversationId/messages'),
      headers: _getHeaders(ref: ref),
      body: json.encode({
        'conversationId': conversationId,
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'messageType': 'text',
        'matrixRoomId': matrixRoomId,
        'matrixEventId': matrixEventId,
      }),
    );

    print('[ChatService] Backend store response: ${response.statusCode}');
    if (response.statusCode != 201 && response.statusCode != 200) {
      print('[ChatService] Backend store failed: ${response.body}');
      throw Exception(
          'Failed to store message in backend: ${response.statusCode} ${response.body}');
    }
    print('[ChatService] Message stored successfully in backend');
  }

  // Note: Conversation preview updates are handled by backend on message POST

  Future<String> findOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final response = await http.post(
      Uri.parse('$_apiUrl/conversations/find-or-create'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'currentUserId': currentUserId,
        'otherUserId': otherUserId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['_id'];
    }
    throw Exception('Failed to find or create conversation: ${response.body}');
  }

  /// Delete a conversation and its messages on the backend.
  /// Also removes any Matrix mapping in backend storage. Note: This does not
  /// leave/delete the actual Matrix room on the homeserver.
  Future<void> deleteConversation(String conversationId, {Ref? ref}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    try {
      if (ref != null) {
        final auth = ref.read(authProvider);
        final token = auth.sessionToken;
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }
    } catch (_) {}

    final resp = await http.delete(
      Uri.parse('$_apiUrl/conversations/$conversationId'),
      headers: headers,
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return;
    }
    throw Exception(
        'Failed to delete conversation (${resp.statusCode}): ${resp.body}');
  }

  Future<String> createConversation({
    required String propertyId,
    required String landlordId,
    required String tenantId,
    String? initialMessage,
  }) async {
    final response = await http.post(
      Uri.parse('$_apiUrl/conversations'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'propertyId': propertyId,
        'landlordId': landlordId,
        'tenantId': tenantId,
        'initialMessage': initialMessage,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['conversationId'];
    }
    throw Exception('Failed to create conversation');
  }

  Future<void> inviteTenant({
    required String propertyId,
    required String landlordId,
    required String tenantId,
    String? message,
  }) async {
    final response = await http.post(
      Uri.parse('$_apiUrl/invitations'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'propertyId': propertyId,
        'landlordId': landlordId,
        'tenantId': tenantId,
        'message': message ?? 'You have been invited to rent this property',
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to send invitation');
    }
  } // Create a new conversation (now uses find-or-create to preserve history)

  Future<String> createNewConversation({
    required String otherUserId,
    required String initialMessage,
    String? currentUserId,
  }) async {
    try {
      // Use provided currentUserId or fallback to a temp ID
      final actualCurrentUserId = currentUserId ?? 'current-user-id';

      // First try to find existing conversation to preserve history
      try {
        final existingConversationId = await findOrCreateConversation(
          currentUserId: actualCurrentUserId,
          otherUserId: otherUserId,
        );

        // If we found an existing conversation, send the initial message to it
        await sendMessage(
          conversationId: existingConversationId,
          senderId: actualCurrentUserId,
          receiverId: otherUserId,
          content: initialMessage,
        );

        return existingConversationId;
      } catch (e) {
        // If find-or-create fails, fall back to creating a new conversation
        print('Find-or-create failed, creating new conversation: $e');
      }

      // Fallback: create a completely new conversation
      final response = await http.post(
        Uri.parse('$_apiUrl/conversations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'otherUserId': otherUserId,
          'initialMessage': initialMessage,
          'participants': [actualCurrentUserId, otherUserId],
          'lastMessage': initialMessage,
          'lastMessageTime': DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['conversationId'];
      } else {
        throw Exception('Failed to create conversation: ${response.body}');
      }
    } catch (e) {
      print('Error creating conversation: $e');
      throw Exception('Failed to create conversation: $e');
    }
  }

  // Get recent conversations for dashboard (last 3)
  Future<List<Conversation>> getRecentConversations(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/conversations/user/$userId?limit=3'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Conversation.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching recent conversations: $e');
      return [];
    }
  }

  Future<void> reportConversation({
    required String conversationId,
    required String reporterId,
    String? reason,
  }) async {
    final resp = await http.post(
      Uri.parse('$_apiUrl/conversations/$conversationId/report'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(
          {'reporterId': reporterId, 'reason': reason ?? 'unspecified'}),
    );
    if (resp.statusCode != 201) {
      throw Exception('Failed to report conversation: ${resp.body}');
    }
  }

  Future<void> blockUser(
      {required String userId, required String targetUserId}) async {
    final resp = await http.post(
      Uri.parse('$_apiUrl/users/$userId/block'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'targetUserId': targetUserId}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to block user: ${resp.body}');
    }
  }

  Future<void> unblockUser(
      {required String userId, required String targetUserId}) async {
    final resp = await http.post(
      Uri.parse('$_apiUrl/users/$userId/unblock'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'targetUserId': targetUserId}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to unblock user: ${resp.body}');
    }
  }

  // Send document/file message
  Future<ChatMessage?> sendDocument({
    required String conversationId,
    required String senderId,
    required String fileName,
    required String filePath,
    String? fileSize,
    String? otherUserId,
    WidgetRef? ref,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      Map<String, dynamic>? encMeta;
      if (ref != null && otherUserId != null) {
        final e2ee = ref.read(e2eeServiceProvider);
        encMeta = await e2ee.encryptAttachment(
            conversationId: conversationId,
            otherUserId: otherUserId,
            bytes: bytes);
      }
      if (encMeta == null) {
        throw Exception('Encryption key not established yet');
      }
      final uri = Uri.parse('$_apiUrl/chat/attachments/$conversationId');
      final request = http.MultipartRequest('POST', uri);
      request.fields['senderId'] = senderId;
      if (otherUserId != null) request.fields['receiverId'] = otherUserId;
      request.fields['messageType'] = 'file';
      request.fields['fileName'] = fileName;
      request.fields['iv'] = encMeta['iv'];
      request.fields['tag'] = encMeta['tag'];
      request.fields['v'] = encMeta['v'].toString();
      final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
      final parts = mimeType.split('/');
      request.files.add(http.MultipartFile.fromBytes(
          'file', base64.decode(encMeta['ciphertext']),
          filename: fileName + '.enc',
          contentType: MediaType(parts[0], parts[1])));
      final resp =
          await _sendMultipartWithProgress(request, onProgress: onProgress);
      if (resp.statusCode != 201) {
        throw Exception('Upload failed: ${resp.body}');
      }
      final decoded = json.decode(resp.body);
      if (decoded is Map && decoded['stored'] != null) {
        return ChatMessage.fromMap(decoded['stored']);
      }
      return null;
    } catch (e) {
      print('Error sending encrypted document: $e');
      throw Exception('Failed to send document: $e');
    }
  }

  // Send image message
  Future<ChatMessage?> sendImage({
    required String conversationId,
    required String senderId,
    required String fileName,
    required String imagePath,
    String? otherUserId,
    WidgetRef? ref,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      Map<String, dynamic>? encMeta;
      if (ref != null && otherUserId != null) {
        final e2ee = ref.read(e2eeServiceProvider);
        encMeta = await e2ee.encryptAttachment(
            conversationId: conversationId,
            otherUserId: otherUserId,
            bytes: bytes);
      }
      if (encMeta == null) {
        throw Exception('Encryption key not established yet');
      }
      final uri = Uri.parse('$_apiUrl/chat/attachments/$conversationId');
      final request = http.MultipartRequest('POST', uri);
      request.fields['senderId'] = senderId;
      if (otherUserId != null) request.fields['receiverId'] = otherUserId;
      request.fields['messageType'] = 'image';
      request.fields['fileName'] = fileName;
      request.fields['iv'] = encMeta['iv'];
      request.fields['tag'] = encMeta['tag'];
      request.fields['v'] = encMeta['v'].toString();
      final mimeType = lookupMimeType(fileName) ?? 'image/png';
      final parts = mimeType.split('/');
      request.files.add(http.MultipartFile.fromBytes(
          'file', base64.decode(encMeta['ciphertext']),
          filename: fileName + '.enc',
          contentType: MediaType(parts[0], parts[1])));
      final resp =
          await _sendMultipartWithProgress(request, onProgress: onProgress);
      if (resp.statusCode != 201) {
        throw Exception('Upload failed: ${resp.body}');
      }
      final decoded = json.decode(resp.body);
      if (decoded is Map && decoded['stored'] != null) {
        return ChatMessage.fromMap(decoded['stored']);
      }
      return null;
    } catch (e) {
      print('Error sending encrypted image: $e');
      throw Exception('Failed to send image: $e');
    }
  }

  Future<List<int>?> downloadAndDecryptAttachment({
    required ChatMessage message,
    required String currentUserId,
    required String otherUserId,
    required WidgetRef ref,
  }) async {
    if (message.metadata == null) return null;
    final fileId = message.metadata!['fileId'];
    if (fileId == null) return null;
    if (_attachmentCache.containsKey(fileId)) return _attachmentCache[fileId];
    try {
      final resp =
          await http.get(Uri.parse('$_apiUrl/chat/attachments/file/$fileId'));
      if (resp.statusCode != 200) return null;
      final bytes = resp.bodyBytes;
      final iv = message.metadata!['iv'] ??
          message.metadata!['IV'] ??
          message.metadata!['Iv'];
      final tag = message.metadata!['tag'] ??
          message.metadata!['TAG'] ??
          message.metadata!['Tag'];
      if (iv == null || tag == null) return null;
      final e2ee = ref.read(e2eeServiceProvider);
      final clear = await e2ee.decryptAttachment(
        conversationId: message.conversationId ?? message.id,
        otherUserId: otherUserId,
        ciphertext: bytes,
        iv: iv,
        tag: tag,
      );
      if (clear != null) {
        _attachmentCache[fileId] = clear;
      }
      return clear;
    } catch (_) {
      return null;
    }
  }

  // Internal helper to send multipart with progress reporting
  Future<http.Response> _sendMultipartWithProgress(
      http.MultipartRequest request,
      {void Function(double progress)? onProgress}) async {
    // Simpler, robust path: avoid double-finalizing multipart files which
    // causes 'Bad state: Can\'t finalize a finalized MultipartFile'.
    // We forego fine-grained progress and just emit 0.0 -> 1.0.
    final client = http.Client();
    try {
      if (onProgress != null) onProgress(0.0);
      final streamedResp = await client.send(request);
      if (onProgress != null) onProgress(1.0);
      return http.Response.fromStream(streamedResp);
    } finally {
      client.close();
    }
  }
}
