import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/chat/domain/models/conversation.dart';
import 'package:immosync/features/chat/presentation/providers/chat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final conversationsProvider = StreamProvider<List<Conversation>>((ref) async* {
  final chatService = ref.read(chatServiceProvider);
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null) {
    yield [];
    return;
  }
  
  while (true) {
    try {
      final conversations = await chatService.getConversationsForUser(currentUser.id);
      yield conversations;
    } catch (e) {
      yield [];
    }
    await Future.delayed(const Duration(seconds: 2));
  }
});

