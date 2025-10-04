import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/services/chat_service.dart';
import '../../../../core/crypto/e2ee_service.dart';
import 'package:flutter/foundation.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Provider for chat service
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

// StateNotifier for managing chat messages
class ChatMessagesNotifier
    extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ChatService _chatService;
  final String _conversationId;
  final Ref _ref;

  ChatMessagesNotifier(this._chatService, this._conversationId, this._ref)
      : super(const AsyncValue.loading()) {
    _loadMessages();
  }
  Future<void> _loadMessages() async {
    try {
      final messages = await _chatService.getMessages(_conversationId);
      // Messages are already sorted chronologically from backend
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      for (final m in messages) {
        debugPrint(
            '[MessagesProvider][load] id=${m.id} sender=${m.senderId} receiver=${m.receiverId} ts=${m.timestamp.toIso8601String()} enc=${m.isEncrypted} contentLen=${m.content.length}');
        if (m.receiverId.isNotEmpty && m.receiverId == m.senderId) {
          debugPrint(
              '[MessagesProvider][anomaly] message ${m.id} has receiver==sender (${m.senderId})');
        }
      }
      state = AsyncValue.data(messages);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Explicit history decryption called by UI once otherUserId is known (avoids sender heuristics)
  Future<void> decryptHistory(
      {required WidgetRef ref, required String otherUserId}) async {
    try {
      debugPrint(
          '[MessagesProvider][decryptHistory] start conversationId=$_conversationId otherUserId=$otherUserId');
      final current =
          List<ChatMessage>.from(state.asData?.value ?? const <ChatMessage>[]);
      if (current.isEmpty) return;
      final e2ee = ref.read(e2eeServiceProvider);
      bool changed = false;
      final currentUserId = ref.read(currentUserProvider)?.id;
      for (var i = 0; i < current.length; i++) {
        final m = current[i];
        if (m.isEncrypted &&
            (m.content.isEmpty || m.content == '[encrypted]') &&
            m.e2ee != null) {
          // Determine other party dynamically to avoid attributing all messages to same side
          final effectiveOther =
              (currentUserId != null && currentUserId == m.senderId)
                  ? (m.receiverId.isNotEmpty ? m.receiverId : otherUserId)
                  : m.senderId;
          debugPrint(
              '[MessagesProvider][decryptHistory] attempt messageId=${m.id} sender=${m.senderId} receiver=${m.receiverId} effectiveOther=$effectiveOther hasE2EE=${m.e2ee != null}');
          final clear = await e2ee.decryptMessage(
              conversationId: m.conversationId ?? _conversationId,
              otherUserId: effectiveOther,
              payload: m.e2ee!);
          if (clear != null) {
            debugPrint(
                '[MessagesProvider][decryptHistory] success messageId=${m.id} len=${clear.length}');
            // Rebuild message only changing content (preserve sender/receiver exactly)
            current[i] = ChatMessage(
              id: m.id,
              senderId: m.senderId,
              receiverId: m.receiverId,
              content: clear,
              timestamp: m.timestamp,
              isRead: m.isRead,
              deliveredAt: m.deliveredAt,
              readAt: m.readAt,
              messageType: m.messageType,
              metadata: m.metadata,
              conversationId: m.conversationId,
              isEncrypted: m.isEncrypted,
              e2ee: m.e2ee,
            );
            changed = true;
          }
        }
      }
      if (changed) {
        state = AsyncValue.data(current);
        debugPrint(
            '[MessagesProvider][decryptHistory] completed changed=true updatedCount=${current.where((m) => m.isEncrypted && m.content.isNotEmpty && m.content != '[encrypted]').length}');
      } else {
        debugPrint(
            '[MessagesProvider][decryptHistory] completed changed=false');
      }
    } catch (e) {
      debugPrint('[MessagesProvider] explicit history decrypt failed: $e');
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
        ref: _ref,
        otherUserId: receiverId,
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
    final List<ChatMessage> current =
        List<ChatMessage>.from(state.asData?.value ?? const <ChatMessage>[]);
    state = AsyncValue.data([...current, msg]);
  }

  // Apply incoming WS message or ack
  void applyWsMessage(Map<String, dynamic> data, {bool isAck = false}) {
    try {
      if (data['conversationId'] != _conversationId) return;
      final msg = ChatMessage.fromMap(data);
      final List<ChatMessage> current =
          List<ChatMessage>.from(state.asData?.value ?? const <ChatMessage>[]);
      // For ack, try to replace optimistic (match by content + sender + timestamp within 5s window)
      if (isAck) {
        int idx = current.indexWhere((m) =>
            m.content == msg.content &&
            m.senderId == msg.senderId &&
            (msg.timestamp.difference(m.timestamp).inSeconds).abs() < 5 &&
            (m.id.startsWith('temp_')));
        if (idx < 0) {
          // Fallback: if exactly one temp_* message pending in last 30s, treat it as the ack target
          final now = DateTime.now();
          final tempCandidates = <int>[];
          for (var i = 0; i < current.length; i++) {
            final m = current[i];
            if (m.id.startsWith('temp_') &&
                now.difference(m.timestamp).inSeconds < 30) {
              tempCandidates.add(i);
            }
          }
          if (tempCandidates.length == 1) {
            idx = tempCandidates.first;
          }
        }
        if (idx >= 0) {
          final optimistic = current[idx];
          // Preserve original senderId (in case backend echo differs) to avoid misattribution
          final fixed = ChatMessage(
            id: msg.id,
            senderId: optimistic.senderId,
            receiverId: optimistic.receiverId,
            content: msg.content.isNotEmpty ? msg.content : optimistic.content,
            timestamp: msg.timestamp,
            isRead: msg.isRead,
            deliveredAt: msg.deliveredAt,
            readAt: msg.readAt,
            messageType: msg.messageType,
            metadata: msg.metadata,
            conversationId: msg.conversationId ?? _conversationId,
            isEncrypted: msg.isEncrypted,
          );
          current[idx] = fixed;
          state = AsyncValue.data(current);
          return;
        }
      }
      // Avoid duplicates (id or same sender+timestamp+content)
      final dup = current.any((m) =>
          m.id == msg.id ||
          (m.content == msg.content &&
              m.senderId == msg.senderId &&
              (m.timestamp.difference(msg.timestamp).inSeconds).abs() < 2));
      if (!dup) {
        current.add(msg);
        current.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        state = AsyncValue.data(current);
      }
    } catch (e) {
      // ignore parsing issues
    }
  }

  void applyDeliveryOrRead(Map<String, dynamic> data) {
    if (data['conversationId'] != _conversationId) return;
    final List<ChatMessage> current =
        List<ChatMessage>.from(state.asData?.value ?? const <ChatMessage>[]);
    if (data['type'] == 'read' && data['messageIds'] is List) {
      final readAt = data['readAt'] != null
          ? DateTime.tryParse(data['readAt'].toString())
          : DateTime.now();
      final ids = (data['messageIds'] as List).map((e) => e.toString()).toSet();
      for (var i = 0; i < current.length; i++) {
        final old = current[i];
        if (ids.contains(old.id)) {
          current[i] = ChatMessage(
            id: old.id,
            senderId: old.senderId,
            receiverId: old.receiverId,
            content: old.content,
            timestamp: old.timestamp,
            isRead: true,
            deliveredAt: old.deliveredAt ?? readAt, // ensure delivered
            readAt: readAt,
            messageType: old.messageType,
            metadata: old.metadata,
            conversationId: old.conversationId,
            isEncrypted: old.isEncrypted,
          );
        }
      }
      state = AsyncValue.data(current);
      return;
    }
    final id = data['_id']?.toString();
    if (id == null) return;
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
        deliveredAt: data['type'] == 'delivered' && data['deliveredAt'] != null
            ? DateTime.tryParse(data['deliveredAt'].toString()) ??
                old.deliveredAt
            : old.deliveredAt,
        readAt: data['type'] == 'read' && data['readAt'] != null
            ? DateTime.tryParse(data['readAt'].toString()) ?? old.readAt
            : old.readAt,
        messageType: old.messageType,
        metadata: old.metadata,
        conversationId: old.conversationId,
        isEncrypted: old.isEncrypted,
      );
      state = AsyncValue.data(current);
    }
  }

  // Insert or replace message by id (used for optimistic attachment insertion)
  void addOrReplace(ChatMessage message) {
    final List<ChatMessage> current =
        List<ChatMessage>.from(state.asData?.value ?? const <ChatMessage>[]);
    final idx = current.indexWhere((m) => m.id == message.id);
    if (idx >= 0) {
      current[idx] = message;
    } else {
      current.add(message);
      current.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    state = AsyncValue.data(current);
  }

  void refresh() {
    _loadMessages();
  }

  // Optimistically mark a set of message IDs as read locally
  void bulkMarkRead(Iterable<String> ids) {
    final set = ids.toSet();
    final current =
        List<ChatMessage>.from(state.asData?.value ?? const <ChatMessage>[]);
    bool changed = false;
    for (var i = 0; i < current.length; i++) {
      final m = current[i];
      if (!m.isRead && set.contains(m.id)) {
        current[i] = ChatMessage(
          id: m.id,
          senderId: m.senderId,
          receiverId: m.receiverId,
          content: m.content,
          timestamp: m.timestamp,
          isRead: true,
          deliveredAt: m.deliveredAt ?? DateTime.now(),
          readAt: DateTime.now(),
          messageType: m.messageType,
          metadata: m.metadata,
          conversationId: m.conversationId,
          isEncrypted: m.isEncrypted,
        );
        changed = true;
      }
    }
    if (changed) {
      state = AsyncValue.data(current);
    }
  }
}

// Provider factory for chat messages
final conversationMessagesProvider = StateNotifierProvider.family<
    ChatMessagesNotifier,
    AsyncValue<List<ChatMessage>>,
    String>((ref, conversationId) {
  final chatService = ref.watch(chatServiceProvider);
  return ChatMessagesNotifier(chatService, conversationId, ref);
});

// Holder to inject a global ref for history decryption without refactoring constructor signature massively

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
      await _ref
          .read(conversationMessagesProvider(conversationId).notifier)
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

final messageSenderProvider =
    StateNotifierProvider<MessageSenderNotifier, AsyncValue<void>>((ref) {
  return MessageSenderNotifier(ref);
});
