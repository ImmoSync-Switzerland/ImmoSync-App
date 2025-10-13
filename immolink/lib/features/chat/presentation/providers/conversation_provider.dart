import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/chat_service.dart';
import '../../domain/models/conversation.dart';
import 'chat_provider.dart'; // For chatServiceProvider

// Provider for finding or creating conversations
final conversationFinderProvider =
    StateNotifierProvider<ConversationFinderNotifier, AsyncValue<String?>>(
        (ref) {
  final chatService = ref.watch(chatServiceProvider);
  return ConversationFinderNotifier(chatService);
});

class ConversationFinderNotifier extends StateNotifier<AsyncValue<String?>> {
  final ChatService _chatService;

  ConversationFinderNotifier(this._chatService)
      : super(const AsyncValue.data(null));

  Future<String?> findOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final conversationId = await _chatService.findOrCreateConversation(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      );

      state = AsyncValue.data(conversationId);
      return conversationId;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

// Provider for user conversations (grouped by participant)
final userConversationsProvider = StateNotifierProvider.family<
    UserConversationsNotifier,
    AsyncValue<List<Conversation>>,
    String>((ref, userId) {
  final chatService = ref.watch(chatServiceProvider);
  return UserConversationsNotifier(chatService, userId);
});

class UserConversationsNotifier
    extends StateNotifier<AsyncValue<List<Conversation>>> {
  final ChatService _chatService;
  final String _userId;

  UserConversationsNotifier(this._chatService, this._userId)
      : super(const AsyncValue.loading()) {
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await _chatService.getConversationsForUser(_userId);

      // Group conversations by other participant to ensure only one per person
      final Map<String, Conversation> uniqueConversations = {};

      for (final conv in conversations) {
        final otherUserId = conv.otherParticipantId ?? '';

        // Keep the conversation with the most recent message
        if (!uniqueConversations.containsKey(otherUserId) ||
            conv.lastMessageTime
                .isAfter(uniqueConversations[otherUserId]!.lastMessageTime)) {
          uniqueConversations[otherUserId] = conv;
        }
      }

      // Sort by last message time (most recent first)
      final sortedConversations = uniqueConversations.values.toList()
        ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      state = AsyncValue.data(sortedConversations);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void refresh() {
    _loadConversations();
  }
}
