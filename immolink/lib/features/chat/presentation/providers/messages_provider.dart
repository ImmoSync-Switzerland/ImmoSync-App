import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/services/chat_service.dart';

// Provider for chat service
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

// StateNotifier for managing chat messages
class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ChatService _chatService;
  final String _conversationId;

  ChatMessagesNotifier(this._chatService, this._conversationId) 
      : super(const AsyncValue.loading()) {
    _loadMessages();
  }
  Future<void> _loadMessages() async {    try {
  final messages = await _chatService.getMessages(_conversationId);
      // Messages are already sorted chronologically from backend
  state = AsyncValue.data(messages);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      await _chatService.sendMessage(
        conversationId: _conversationId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
      );
        // Refresh messages after sending
      await _loadMessages();
    } catch (error, _) {
      // Handle error but don't change the state to error
      // as we still want to show existing messages
      print('Error sending message: $error');
      rethrow;
    }
  }

  // Optimistic insertion for WS send (sender doesn't get broadcast echo)
  void addOptimisticMessage(ChatMessage msg) {
  final List<ChatMessage> current = List<ChatMessage>.from(state.asData?.value ?? const <ChatMessage>[]);
  state = AsyncValue.data([...current, msg]);
  }

  // Apply incoming WS message or ack
  void applyWsMessage(Map<String, dynamic> data, {bool isAck = false}) {
    try {
      if (data['conversationId'] != _conversationId) return;
      final msg = ChatMessage.fromMap(data);
  final List<ChatMessage> current = List<ChatMessage>.from(state.asData?.value ?? const <ChatMessage>[]);
      // For ack, try to replace optimistic (match by content + sender + timestamp within 5s window)
      if (isAck) {
        final idx = current.indexWhere((m) =>
          m.content == msg.content &&
          m.senderId == msg.senderId &&
          (msg.timestamp.difference(m.timestamp).inSeconds).abs() < 5 &&
          (m.id.startsWith('temp_'))
        );
        if (idx >= 0) {
          current[idx] = msg; // replace temp
          state = AsyncValue.data(current);
          return;
        }
      }
      // Avoid duplicates (id or same sender+timestamp+content)
      final dup = current.any((m) => m.id == msg.id || (m.content == msg.content && m.senderId == msg.senderId && (m.timestamp.difference(msg.timestamp).inSeconds).abs() < 2));
      if (!dup) {
        current.add(msg);
        current.sort((a,b)=> a.timestamp.compareTo(b.timestamp));
        state = AsyncValue.data(current);
      }
    } catch (e) {
      // ignore parsing issues
    }
  }

  void applyDeliveryOrRead(Map<String, dynamic> data) {
    if (data['conversationId'] != _conversationId) return;
    final id = data['_id']?.toString();
    if (id == null) return;
  final List<ChatMessage> current = List<ChatMessage>.from(state.asData?.value ?? const <ChatMessage>[]);
    final idx = current.indexWhere((m) => m.id == id);
    if (idx >= 0) {
      final old = current[idx];
      current[idx] = ChatMessage(
        id: old.id,
        senderId: old.senderId,
        receiverId: old.receiverId,
        content: old.content,
        timestamp: old.timestamp,
        isRead: data['type'] == 'read' ? true : old.isRead,
        deliveredAt: data['type'] == 'delivered' && data['deliveredAt'] != null ? DateTime.tryParse(data['deliveredAt']) ?? old.deliveredAt : old.deliveredAt,
        readAt: data['type'] == 'read' && data['readAt'] != null ? DateTime.tryParse(data['readAt']) ?? old.readAt : old.readAt,
      );
      state = AsyncValue.data(current);
    }
  }

  void refresh() {
    _loadMessages();
  }
}

// Provider factory for chat messages
final conversationMessagesProvider = StateNotifierProvider.family<ChatMessagesNotifier, AsyncValue<List<ChatMessage>>, String>((ref, conversationId) {
  final chatService = ref.watch(chatServiceProvider);
  return ChatMessagesNotifier(chatService, conversationId);
});

// Provider for sending messages
class MessageSenderNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  MessageSenderNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      await _ref.read(conversationMessagesProvider(conversationId).notifier)
          .sendMessage(
            senderId: senderId,
            receiverId: receiverId,
            content: content,
          );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final messageSenderProvider = StateNotifierProvider<MessageSenderNotifier, AsyncValue<void>>((ref) {
  return MessageSenderNotifier(ref);
});
