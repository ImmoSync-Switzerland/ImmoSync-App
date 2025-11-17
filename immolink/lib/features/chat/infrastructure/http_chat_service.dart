import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immosync/core/config/db_config.dart';
import 'package:immosync/features/chat/domain/models/chat_message.dart';
import 'package:immosync/features/chat/domain/models/conversation.dart';

/// HTTP-based chat service that communicates with your normal backend API
/// This replaces the Matrix-based implementation
class HttpChatService {
  final String _apiUrl = DbConfig.apiUrl;

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

      final response = await http.post(
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

      final response = await http.get(
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

      final response = await http.get(
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

      final response = await http.post(
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

      final response = await http.patch(
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
    // TODO: Implement when needed
    throw UnimplementedError('Attachment download not implemented yet');
  }

  Future<void> blockUser(String userId, String otherUserId) async {
    // TODO: Implement when needed
    throw UnimplementedError('Block user not implemented yet');
  }

  Future<void> unblockUser(String userId, String otherUserId) async {
    // TODO: Implement when needed
    throw UnimplementedError('Unblock user not implemented yet');
  }

  Future<void> reportConversation(String conversationId) async {
    // TODO: Implement when needed
    throw UnimplementedError('Report conversation not implemented yet');
  }

  Future<void> deleteConversation(String conversationId) async {
    // TODO: Implement when needed
    throw UnimplementedError('Delete conversation not implemented yet');
  }

  Future<String> sendImage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String imagePath,
  }) async {
    // TODO: Implement when needed
    throw UnimplementedError('Send image not implemented yet');
  }

  Future<String> sendDocument({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String documentPath,
  }) async {
    // TODO: Implement when needed
    throw UnimplementedError('Send document not implemented yet');
  }

  // Compatibility method - not needed for HTTP
  Future<void> ensureMatrixReady({required String userId}) async {
    print('[HttpChat] ensureMatrixReady called - not needed for HTTP API');
    // No-op for HTTP API
  }
}
