import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immolink/core/config/db_config.dart';
import 'package:immolink/features/chat/domain/models/chat_message.dart';
import 'package:immolink/features/chat/domain/models/conversation.dart';

class ChatService {
  final String _apiUrl = DbConfig.apiUrl;

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
      Uri.parse('$_apiUrl/conversations/user/current'), // Will need current user ID
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
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse('$_apiUrl/chat/$conversationId/messages'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
        'messageType': 'text',
        'isRead': false,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to send message: ${response.body}');
    }
    
    // Also update the conversation's last message
    await _updateConversationLastMessage(conversationId, content);
  }
  
  Future<void> _updateConversationLastMessage(String conversationId, String lastMessage) async {
    try {
      await http.put(
        Uri.parse('$_apiUrl/conversations/$conversationId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'lastMessage': lastMessage,
          'lastMessageTime': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      print('Error updating conversation: $e');
    }
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
  }  // Create a new conversation
  Future<String> createNewConversation({
    required String otherUserId,
    required String initialMessage,
    String? currentUserId,
  }) async {
    try {
      // Use provided currentUserId or fallback to a temp ID
      final actualCurrentUserId = currentUserId ?? 'current-user-id';
      
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
}
