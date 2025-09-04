import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immosync/core/config/db_config.dart';
import 'package:immosync/features/chat/domain/models/chat_message.dart';
import 'package:immosync/features/chat/domain/models/conversation.dart';
import 'dart:io';
import 'package:immosync/core/crypto/e2ee_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  }  // Create a new conversation (now uses find-or-create to preserve history)
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

  // Send document/file message
  Future<void> sendDocument({
    required String conversationId,
    required String senderId,
    required String fileName,
    required String filePath,
    String? fileSize,
    String? otherUserId,
    WidgetRef? ref,
  }) async {
    try {
      Map<String,dynamic>? encMeta;
      if (ref != null && otherUserId != null) {
        try {
          final e2ee = ref.read(e2eeServiceProvider);
          final bytes = await File(filePath).readAsBytes();
            final enc = await e2ee.encryptAttachment(conversationId: conversationId, otherUserId: otherUserId, bytes: bytes);
            if (enc != null) {
              encMeta = enc;
            }
        } catch (_) {}
      }
      final body = {
        'senderId': senderId,
        'messageType': 'file',
        'content': fileName,
        'metadata': {
          'fileName': fileName,
          'filePath': filePath,
          'fileSize': fileSize,
          'fileType': fileName.split('.').last,
          if (encMeta != null) 'ciphertext': encMeta['ciphertext'],
          if (encMeta != null) 'iv': encMeta['iv'],
          if (encMeta != null) 'tag': encMeta['tag'],
          if (encMeta != null) 'encVersion': encMeta['v'],
        },
        if (encMeta != null) 'e2ee': {
          'ciphertext': encMeta['ciphertext'],
          'iv': encMeta['iv'],
          'tag': encMeta['tag'],
          'v': encMeta['v'],
          'type': 'file'
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
      final response = await http.post(
        Uri.parse('$_apiUrl/chat/$conversationId/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to send document');
      }
    } catch (e) {
      print('Error sending document: $e');
      throw Exception('Failed to send document: $e');
    }
  }

  // Send image message
  Future<void> sendImage({
    required String conversationId,
    required String senderId,
    required String fileName,
    required String imagePath,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/chat/$conversationId/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'senderId': senderId,
          'messageType': 'image',
          'content': fileName,
          'metadata': {
            'fileName': fileName,
            'imagePath': imagePath,
            'fileType': 'image',
          },
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to send image');
      }
    } catch (e) {
      print('Error sending image: $e');
      throw Exception('Failed to send image: $e');
    }
  }
}
