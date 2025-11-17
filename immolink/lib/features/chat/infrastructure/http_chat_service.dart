import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immosync/core/config/db_config.dart';
import 'package:immosync/features/chat/domain/models/chat_message.dart';
import 'package:immosync/features/chat/domain/models/conversation.dart';

/// HTTP-based chat service that communicates with your normal backend API
/// This replaces the Matrix-based implementation
class HttpChatService {
  final String _apiUrl = DbConfig.apiUrl;
  final http.Client _client;

  HttpChatService({http.Client? client}) : _client = client ?? http.Client();

  /// Send a message via HTTP API to your backend
  Future<String> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      print('[HttpChat] Sending message to conversation $conversationId');
      print('[HttpChat] From: $senderId, To: $receiverId');
      print('[HttpChat] Content: $content');

      final response = await _client.post(
        Uri.parse('$_apiUrl/chat/$conversationId/messages'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'senderId': senderId,
          'receiverId': receiverId,
          'content': content,
          'messageType': messageType,
        }),
      );

      print('[HttpChat] Response status: ${response.statusCode}');
      print('[HttpChat] Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final messageId = responseData['messageId'];
        print('[HttpChat] Message sent successfully with ID: $messageId');
        return messageId.toString();
      } else {
        print(
            '[HttpChat] Failed to send message: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('[HttpChat] Error sending message: $e');
      rethrow;
    }
  }

  /// Get conversations for a user
  Future<List<Conversation>> getConversationsForUser(String userId) async {
    try {
      print('[HttpChat] Getting conversations for user: $userId');

      final response = await _client.get(
        Uri.parse('$_apiUrl/conversations/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('[HttpChat] Conversations response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final conversations =
            data.map((json) => Conversation.fromMap(json)).toList();
        print('[HttpChat] Found ${conversations.length} conversations');
        return conversations;
      } else {
        print('[HttpChat] Failed to get conversations: ${response.statusCode}');
        throw Exception('Failed to fetch conversations');
      }
    } catch (e) {
      print('[HttpChat] Error getting conversations: $e');
      rethrow;
    }
  }

  /// Get messages for a conversation
  Future<List<ChatMessage>> getMessagesForConversation(
      String conversationId) async {
    try {
      print('[HttpChat] Getting messages for conversation: $conversationId');

      final response = await _client.get(
        Uri.parse('$_apiUrl/chat/$conversationId/messages'),
        headers: {'Content-Type': 'application/json'},
      );

      print('[HttpChat] Messages response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final messages = data.map((json) => ChatMessage.fromMap(json)).toList();
        print('[HttpChat] Found ${messages.length} messages');
        return messages;
      } else {
        print('[HttpChat] Failed to get messages: ${response.statusCode}');
        throw Exception('Failed to fetch messages');
      }
    } catch (e) {
      print('[HttpChat] Error getting messages: $e');
      rethrow;
    }
  }

  /// Create a new conversation
  Future<String> createConversation({
    required String senderId,
    required String receiverId,
    String? initialMessage,
  }) async {
    try {
      print(
          '[HttpChat] Creating conversation between $senderId and $receiverId');

      final response = await _client.post(
        Uri.parse('$_apiUrl/conversations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'participants': [senderId, receiverId],
          'createdBy': senderId,
        }),
      );

      print('[HttpChat] Create conversation response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final conversationId =
            responseData['conversationId'] ?? responseData['id'];
        print('[HttpChat] Conversation created with ID: $conversationId');

        // Send initial message if provided
        if (initialMessage != null && initialMessage.isNotEmpty) {
          await sendMessage(
            conversationId: conversationId.toString(),
            senderId: senderId,
            receiverId: receiverId,
            content: initialMessage,
          );
        }

        return conversationId.toString();
      } else {
        print(
            '[HttpChat] Failed to create conversation: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create conversation');
      }
    } catch (e) {
      print('[HttpChat] Error creating conversation: $e');
      rethrow;
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      print('[HttpChat] Marking message as read: $messageId');

      final response = await _client.patch(
        Uri.parse('$_apiUrl/messages/$messageId/read'),
        headers: {'Content-Type': 'application/json'},
      );

      print('[HttpChat] Mark read response: ${response.statusCode}');

      if (response.statusCode != 200) {
        print(
            '[HttpChat] Failed to mark message as read: ${response.statusCode}');
        throw Exception('Failed to mark message as read');
      }
    } catch (e) {
      print('[HttpChat] Error marking message as read: $e');
      rethrow;
    }
  }

  /// Find or create conversation between two users
  Future<String> findOrCreateConversation({
    required String senderId,
    required String receiverId,
    String? initialMessage,
  }) async {
    try {
      print(
          '[HttpChat] Finding or creating conversation between $senderId and $receiverId');

      // First try to find existing conversation
      final conversations = await getConversationsForUser(senderId);
      for (final conversation in conversations) {
        final participants = conversation.participants;
        if (participants != null &&
            participants.contains(senderId) &&
            participants.contains(receiverId)) {
          print('[HttpChat] Found existing conversation: ${conversation.id}');
          return conversation.id;
        }
      }

      // Create new conversation if none exists
      return await createConversation(
        senderId: senderId,
        receiverId: receiverId,
        initialMessage: initialMessage,
      );
    } catch (e) {
      print('[HttpChat] Error finding/creating conversation: $e');
      rethrow;
    }
  }

  // Stub methods for compatibility (not needed for HTTP API)
  Future<String?> getMatrixRoomIdForConversation({
    required String conversationId,
    required String currentUserId,
    required String otherUserId,
  }) async {
    // Not needed for HTTP API - return null
    return null;
  }

  Future<List<int>?> downloadAndDecryptAttachment(String attachmentId) async {
    try {
      print('[HttpChat] Downloading attachment: $attachmentId');

      final response = await _client.get(
        Uri.parse('$_apiUrl/attachments/$attachmentId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('[HttpChat] Attachment download response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('[HttpChat] Attachment downloaded successfully');
        return response.bodyBytes;
      } else {
        print(
            '[HttpChat] Failed to download attachment: ${response.statusCode}');
        throw Exception('Failed to download attachment');
      }
    } catch (e) {
      print('[HttpChat] Error downloading attachment: $e');
      rethrow;
    }
  }

  Future<void> blockUser(String userId, String otherUserId) async {
    try {
      print('[HttpChat] Blocking user: $otherUserId by $userId');

      final response = await _client.post(
        Uri.parse('$_apiUrl/users/$userId/block'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'blockedUserId': otherUserId}),
      );

      print('[HttpChat] Block user response: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('[HttpChat] Failed to block user: ${response.statusCode}');
        throw Exception('Failed to block user');
      }

      print('[HttpChat] User blocked successfully');
    } catch (e) {
      print('[HttpChat] Error blocking user: $e');
      rethrow;
    }
  }

  Future<void> unblockUser(String userId, String otherUserId) async {
    try {
      print('[HttpChat] Unblocking user: $otherUserId by $userId');

      final response = await _client.delete(
        Uri.parse('$_apiUrl/users/$userId/block/$otherUserId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('[HttpChat] Unblock user response: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        print('[HttpChat] Failed to unblock user: ${response.statusCode}');
        throw Exception('Failed to unblock user');
      }

      print('[HttpChat] User unblocked successfully');
    } catch (e) {
      print('[HttpChat] Error unblocking user: $e');
      rethrow;
    }
  }

  Future<void> reportConversation(String conversationId) async {
    try {
      print('[HttpChat] Reporting conversation: $conversationId');

      final response = await _client.post(
        Uri.parse('$_apiUrl/conversations/$conversationId/report'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'reason': 'Inappropriate content',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      print('[HttpChat] Report conversation response: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        print(
            '[HttpChat] Failed to report conversation: ${response.statusCode}');
        throw Exception('Failed to report conversation');
      }

      print('[HttpChat] Conversation reported successfully');
    } catch (e) {
      print('[HttpChat] Error reporting conversation: $e');
      rethrow;
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      print('[HttpChat] Deleting conversation: $conversationId');

      final response = await _client.delete(
        Uri.parse('$_apiUrl/conversations/$conversationId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('[HttpChat] Delete conversation response: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        print(
            '[HttpChat] Failed to delete conversation: ${response.statusCode}');
        throw Exception('Failed to delete conversation');
      }

      print('[HttpChat] Conversation deleted successfully');
    } catch (e) {
      print('[HttpChat] Error deleting conversation: $e');
      rethrow;
    }
  }

  Future<String> sendImage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String imagePath,
  }) async {
    try {
      print('[HttpChat] Sending image to conversation $conversationId');
      print('[HttpChat] Image path: $imagePath');

      final uri = Uri.parse('$_apiUrl/chat/$conversationId/messages/image');
      final request = http.MultipartRequest('POST', uri);

      // Add fields
      request.fields['senderId'] = senderId;
      request.fields['receiverId'] = receiverId;
      request.fields['messageType'] = 'image';

      // Add image file
      final imageFile = await http.MultipartFile.fromPath('image', imagePath);
      request.files.add(imageFile);

      // Send request via client
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      print('[HttpChat] Send image response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final messageId = responseData['messageId'];
        print('[HttpChat] Image sent successfully with ID: $messageId');
        return messageId.toString();
      } else {
        print('[HttpChat] Failed to send image: ${response.statusCode}');
        throw Exception('Failed to send image: ${response.statusCode}');
      }
    } catch (e) {
      print('[HttpChat] Error sending image: $e');
      rethrow;
    }
  }

  Future<String> sendDocument({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String documentPath,
  }) async {
    try {
      print('[HttpChat] Sending document to conversation $conversationId');
      print('[HttpChat] Document path: $documentPath');

      final uri = Uri.parse('$_apiUrl/chat/$conversationId/messages/document');
      final request = http.MultipartRequest('POST', uri);

      // Add fields
      request.fields['senderId'] = senderId;
      request.fields['receiverId'] = receiverId;
      request.fields['messageType'] = 'document';

      // Add document file
      final documentFile =
          await http.MultipartFile.fromPath('document', documentPath);
      request.files.add(documentFile);

      // Send request via client
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      print('[HttpChat] Send document response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final messageId = responseData['messageId'];
        print('[HttpChat] Document sent successfully with ID: $messageId');
        return messageId.toString();
      } else {
        print('[HttpChat] Failed to send document: ${response.statusCode}');
        throw Exception('Failed to send document: ${response.statusCode}');
      }
    } catch (e) {
      print('[HttpChat] Error sending document: $e');
      rethrow;
    }
  }

  // Compatibility method - not needed for HTTP
  Future<void> ensureMatrixReady({required String userId}) async {
    print('[HttpChat] ensureMatrixReady called - not needed for HTTP API');
    // No-op for HTTP API
  }
}
