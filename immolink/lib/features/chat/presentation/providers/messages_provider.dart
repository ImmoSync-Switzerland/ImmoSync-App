import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/crypto/e2ee_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/conversation.dart';
import '../../domain/services/chat_service.dart';
import '../../infrastructure/matrix_timeline_service.dart';
import 'chat_provider.dart';

// StateNotifier for managing chat messages
class ChatMessagesNotifier
    extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ChatService _chatService;
  final String _conversationId;
  final Ref _ref;
  StreamSubscription<List<ChatMessage>>? _sub;
  String? _roomId;

  ChatMessagesNotifier(this._chatService, this._conversationId, this._ref)
      : super(const AsyncValue.loading()) {
    _initMessages();
  }

  Future<void> _initMessages() async {
    await _configureMatrixPipeline();
  }

  Future<void> _configureMatrixPipeline() async {
    try {
      final currentUserId = await _resolveCurrentUserId();

      await _ref
          .read(chatServiceProvider)
          .ensureMatrixReady(userId: currentUserId, required: false);

      final otherUserId = await _resolveOtherUserId(currentUserId);
      final roomId = await _resolveMatrixRoomId(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      );

      _roomId = roomId;

      final timeline = _ref.read(matrixTimelineServiceProvider);
      _sub?.cancel();
      _sub = timeline.watchRoom(roomId).listen((messages) {
        final sorted = List<ChatMessage>.from(messages)
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        state = AsyncValue.data(sorted);
      });

      final snapshot = timeline.snapshot(roomId);
      if (snapshot != null) {
        final sorted = List<ChatMessage>.from(snapshot)
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        state = AsyncValue.data(sorted);
      } else if (!state.hasValue) {
        state = const AsyncValue.data(<ChatMessage>[]);
      }

      await timeline.refreshHistory(roomId);
    } catch (e, st) {
      debugPrint('[MessagesProvider] Matrix init failed: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<String> _resolveCurrentUserId() async {
    String currentUserId = _ref.read(currentUserProvider)?.id ?? '';

    if (currentUserId.isEmpty || currentUserId == 'null') {
      final authUserId = _ref.read(authProvider).userId;
      if (authUserId != null && authUserId.isNotEmpty && authUserId != 'null') {
        currentUserId = authUserId;
      }
    }

    if (currentUserId.isEmpty || currentUserId == 'null') {
      for (int attempt = 0; attempt < 10; attempt++) {
        await Future.delayed(const Duration(milliseconds: 500));
        currentUserId = _ref.read(currentUserProvider)?.id ?? '';
        if (currentUserId.isNotEmpty && currentUserId != 'null') {
          break;
        }
        final authUserId = _ref.read(authProvider).userId;
        if (authUserId != null &&
            authUserId.isNotEmpty &&
            authUserId != 'null') {
          currentUserId = authUserId;
          break;
        }
      }
    }

    if (currentUserId.isEmpty || currentUserId == 'null') {
      throw Exception('Benutzer nicht eingeloggt - bitte erneut anmelden');
    }

    return currentUserId;
  }

  Future<String?> _resolveOtherUserId(String currentUserId) async {
    try {
      final conversations =
          await _chatService.getConversationsForUser(currentUserId);
      if (conversations.isEmpty) {
        return null;
      }

      Conversation conversation;
      try {
        conversation = conversations.firstWhere((c) => c.id == _conversationId);
      } catch (_) {
        conversation = conversations.first;
      }

      final direct = conversation.otherParticipantId ??
          conversation.getOtherParticipantId(currentUserId);
      if (direct != null &&
          direct.isNotEmpty &&
          direct != 'null' &&
          direct != currentUserId) {
        return direct;
      }
    } catch (e, st) {
      debugPrint('[MessagesProvider] Failed to resolve other user: $e');
      debugPrint(st.toString());
    }
    return null;
  }

  Future<String> _resolveMatrixRoomId({
    required String currentUserId,
    String? otherUserId,
  }) async {
    if (_roomId != null && _roomId!.isNotEmpty) {
      return _roomId!;
    }

    if (otherUserId != null && otherUserId.isNotEmpty) {
      try {
        final resolved = await _chatService.getMatrixRoomIdForConversation(
          conversationId: _conversationId,
          currentUserId: currentUserId,
          otherUserId: otherUserId,
        );
        if (resolved != null && resolved.isNotEmpty) {
          return resolved;
        }
      } catch (e, st) {
        debugPrint('[MessagesProvider] Room resolve failed: $e');
        debugPrint(st.toString());
      }
    }

    return _conversationId;
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
      debugPrint('[MessagesProvider] Sending message via ChatService');

      // 1. Optimistic UI Update - show message immediately
      final tempMessage = ChatMessage(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
        messageType: 'text',
        conversationId: _conversationId,
        // Optimistic assumptions: Matrix DM rooms are encrypted and server will deliver
        isEncrypted: true,
        deliveredAt: DateTime.now(),
      );

      addOptimisticMessage(tempMessage);
      debugPrint('[MessagesProvider] Added optimistic message to UI');

      // 2. Send via Matrix
      final messageId = await _chatService.sendMessage(
        conversationId: _conversationId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        ref: _ref,
      );

      debugPrint(
          '[MessagesProvider] Message sent successfully with ID: $messageId');

      // Matrix-only mode: Do not poll HTTP backend for confirmation.
      // The live Matrix timeline already contains the event and UI is updated.
    } catch (error, _) {
      debugPrint('[MessagesProvider] Error sending message: $error');

      // Remove optimistic message on error
      final current = List<ChatMessage>.from(state.asData?.value ?? []);
      current.removeWhere((m) => m.id.startsWith('temp_'));
      state = AsyncValue.data(current);

      rethrow;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // Optimistic insertion for WS send (sender doesn't get broadcast echo)
  void addOptimisticMessage(ChatMessage msg) {
    final List<ChatMessage> current =
        List<ChatMessage>.from(state.asData?.value ?? const <ChatMessage>[]);
    state = AsyncValue.data([...current, msg]);
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
