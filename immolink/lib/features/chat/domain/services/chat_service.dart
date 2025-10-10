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

class ChatService {
  final String _apiUrl = DbConfig.apiUrl;
  final Map<String, List<int>> _attachmentCache = {};

  Future<List<Conversation>> getConversationsForUser(String userId) async {
    final response = await http.get(
      Uri.parse('$_apiUrl/conversations/user/$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Conversation.fromMap(json)).toList();
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

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final response = await http.get(
      Uri.parse('$_apiUrl/chat/$conversationId/messages'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ChatMessage.fromMap(json)).toList();
    }
    throw Exception('Failed to fetch messages');
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
  // Resolve Matrix roomId for this conversation (server must provide mapping)
  final roomId = await _fetchOrCreateMatrixRoomId(
    conversationId: conversationId,
    creatorUserId: senderId,
    otherUserId: receiverId);
    if (roomId == null || roomId.isEmpty) {
      throw Exception('Matrix roomId not found for conversation $conversationId');
    }
  // Send via FRB and capture Matrix event id
  final matrixEventId = await frb.sendMessage(roomId: roomId, body: content);
  // Matrix-only: do not persist chat content to backend anymore.
  return matrixEventId;
  }

  Future<String?> _fetchOrCreateMatrixRoomId({
    required String conversationId,
    required String creatorUserId,
    required String otherUserId,
  }) async {
    // Expect backend to expose mapping endpoint
    final res = await http.get(
      Uri.parse('$_apiUrl/conversations/$conversationId/matrix-room'),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data['matrixRoomId'] ?? data['roomId'] ?? data['matrix_room_id'];
    }
    if (res.statusCode == 404) {
      // Ask backend to create the room mapping now
      final create = await http.post(
        Uri.parse('$_apiUrl/matrix/rooms/create-room'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'conversationId': conversationId,
          'creatorUserId': creatorUserId,
          'otherUserId': otherUserId,
        }),
      );
      if (create.statusCode == 200) {
        final data = json.decode(create.body);
        return data['roomId'] ?? data['matrixRoomId'];
      }
    }
    return null;
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

  Future<void> deleteConversation(String conversationId) async {
    final resp = await http.delete(Uri.parse('$_apiUrl/conversations/$conversationId'));
    if (resp.statusCode != 200) {
      throw Exception('Failed to delete conversation: ${resp.body}');
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
      body: json.encode({ 'reporterId': reporterId, 'reason': reason ?? 'unspecified' }),
    );
    if (resp.statusCode != 201) {
      throw Exception('Failed to report conversation: ${resp.body}');
    }
  }

  Future<void> blockUser({ required String userId, required String targetUserId }) async {
    final resp = await http.post(
      Uri.parse('$_apiUrl/users/$userId/block'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({ 'targetUserId': targetUserId }),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to block user: ${resp.body}');
    }
  }

  Future<void> unblockUser({ required String userId, required String targetUserId }) async {
    final resp = await http.post(
      Uri.parse('$_apiUrl/users/$userId/unblock'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({ 'targetUserId': targetUserId }),
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
