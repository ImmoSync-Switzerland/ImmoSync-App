import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/chat/domain/models/chat_message.dart';
import 'package:immosync/features/chat/domain/services/chat_service.dart';

final chatServiceProvider = Provider((ref) => ChatService());

final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>(
  (ref, conversationId) async* {
    final chatService = ref.read(chatServiceProvider);
    
    while (true) {
      try {
        final messages = await chatService.getMessages(conversationId);
        yield messages;
      } catch (e) {
        yield [];
      }
      
      await Future.delayed(const Duration(seconds: 2));
    }
  },
);

