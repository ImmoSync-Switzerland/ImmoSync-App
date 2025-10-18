import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../domain/models/chat_message.dart';
import '../../domain/services/chat_service.dart';
import '../../../../core/crypto/e2ee_service.dart';
import 'package:flutter/foundation.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../infrastructure/matrix_timeline_service.dart';

// Provider for chat service (with Matrix support)
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

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
    _initMatrixTimeline();
  }

  Future<void> _initMatrixTimeline() async {
    try {
      // Wait for user to be loaded (with timeout)
      String currentUserId = _ref.read(currentUserProvider)?.id ?? '';
      
      // Also try authState userId as fallback
      if (currentUserId.isEmpty || currentUserId == 'null') {
        final authUserId = _ref.read(authProvider).userId;
        if (authUserId != null && authUserId != 'null') {
          currentUserId = authUserId;
        }
      }
      
      if (currentUserId.isEmpty || currentUserId == 'null') {
        debugPrint('[MessagesProvider] Waiting for user to be loaded...');
        for (int i = 0; i < 10 && (currentUserId.isEmpty || currentUserId == 'null'); i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          currentUserId = _ref.read(currentUserProvider)?.id ?? '';
          if (currentUserId.isEmpty || currentUserId == 'null') {
            final authUserId = _ref.read(authProvider).userId;
            if (authUserId != null && authUserId != 'null') {
              currentUserId = authUserId;
            }
          }
        }
      }
      
      if (currentUserId.isEmpty || currentUserId == 'null') {
        debugPrint('[MessagesProvider] WARNING: User ID still empty/null after waiting, Matrix will not be initialized');
      } else {
        try {
          debugPrint('[MessagesProvider] Ensuring Matrix ready for user $currentUserId');
          await _ref.read(chatServiceProvider).ensureMatrixReady(userId: currentUserId);
          debugPrint('[MessagesProvider] Matrix ready, waiting for initial sync...');
          // Give sync a moment to start and connect
          await Future.delayed(const Duration(seconds: 3));
          debugPrint('[MessagesProvider] Initial sync delay complete');
        } catch (e) {
          debugPrint('[MessagesProvider] Failed to ensure Matrix ready: $e');
        }
      }
      
      // Resolve Matrix roomId for this conversation via backend mapping
      String? roomId;
      try {
        roomId = await _ref
            .read(chatServiceProvider)
            .getMatrixRoomIdForConversation(
                conversationId: _conversationId,
                currentUserId: currentUserId,
                otherUserId: '');
      } catch (_) {
        // Fallback: try to fetch via conversationId mapping
        debugPrint(
            '[MessagesProvider] Failed to resolve roomId, will retry on send');
      }

      // Use roomId if found, otherwise use conversationId as key (will be updated on first send)
      _roomId = roomId ?? _conversationId;

      debugPrint(
          '[MessagesProvider] Subscribing to Matrix timeline roomId=$_roomId conversationId=$_conversationId');

      // Subscribe to matrix timeline stream keyed by roomId
      final timeline = _ref.read(matrixTimelineServiceProvider);
      _sub?.cancel();
      _sub = timeline.watchRoom(_roomId!).listen((messages) {
        // ensure sorted by timestamp
        final sorted = List<ChatMessage>.from(messages)
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        debugPrint(
            '[MessagesProvider] Timeline update: ${sorted.length} messages for $_roomId');
        state = AsyncValue.data(sorted);
      });

      // CRITICAL: Load initial messages from backend HTTP API
      // Matrix timeline only provides new messages, not history
      debugPrint('[MessagesProvider] Loading initial messages from backend...');
      await _loadMessages();
      debugPrint('[MessagesProvider] Initial messages loaded, timeline will update on new messages');
      
    } catch (e, st) {
      debugPrint('[MessagesProvider] Timeline init error: $e');
      state = AsyncValue.error(e, st);
      
      // Even if Matrix fails, try to load from backend
      try {
        debugPrint('[MessagesProvider] Matrix failed, trying backend fallback...');
        await _loadMessages();
      } catch (backendError) {
        debugPrint('[MessagesProvider] Backend fallback also failed: $backendError');
      }
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
        isEncrypted: false,
      );
      
      addOptimisticMessage(tempMessage);
      debugPrint('[MessagesProvider] Added optimistic message to UI');
      
      // 2. Send via Matrix + Backend
      final messageId = await _chatService.sendMessage(
        conversationId: _conversationId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        ref: _ref,
      );

      debugPrint('[MessagesProvider] Message sent successfully with ID: $messageId');
      
      // 3. Poll for the message to appear in backend (with retries)
      bool messageFound = false;
      for (int i = 0; i < 6; i++) {
        await Future.delayed(Duration(milliseconds: 500 * (i + 1))); // 500ms, 1s, 1.5s, 2s, 2.5s, 3s
        
        debugPrint('[MessagesProvider] Polling attempt ${i + 1}/6 for new message');
        final messages = await _chatService.getMessages(_conversationId, ref: _ref);
        
        // Check if the message we just sent is in the response
        final foundMessage = messages.any((m) => 
          m.content == content && 
          m.senderId == senderId &&
          DateTime.now().difference(m.timestamp).inSeconds < 10
        );
        
        if (foundMessage) {
          debugPrint('[MessagesProvider] Message found in backend on attempt ${i + 1}');
          state = AsyncValue.data(messages);
          messageFound = true;
          break;
        }
      }
      
      if (!messageFound) {
        debugPrint('[MessagesProvider] WARNING: Message not found in backend after 6 retries, keeping optimistic message');
        // Keep the optimistic message if backend hasn't confirmed
      }
      
    } catch (error, _) {
      debugPrint('[MessagesProvider] Error sending message: $error');
      
      // Remove optimistic message on error
      final current = List<ChatMessage>.from(state.asData?.value ?? []);
      current.removeWhere((m) => m.id.startsWith('temp_'));
      state = AsyncValue.data(current);
      
      rethrow;
    }
  }

  Future<void> _loadMessages() async {
    try {
      debugPrint('[MessagesProvider] Loading messages for conversation: $_conversationId');
      final messages = await _chatService.getMessages(_conversationId, ref: _ref);
      
      // Preserve optimistic messages if they're not in the backend yet
      final current = state.asData?.value ?? [];
      final optimisticMessages = current.where((m) => m.id.startsWith('temp_')).toList();
      
      if (optimisticMessages.isNotEmpty) {
        debugPrint('[MessagesProvider] Preserving ${optimisticMessages.length} optimistic messages');
        
        // Merge: remove optimistic messages that now have real counterparts
        final filteredOptimistic = optimisticMessages.where((opt) {
          return !messages.any((real) =>
            real.content == opt.content &&
            real.senderId == opt.senderId &&
            real.timestamp.difference(opt.timestamp).inSeconds.abs() < 10
          );
        }).toList();
        
        final mergedMessages = [...messages, ...filteredOptimistic]
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        state = AsyncValue.data(mergedMessages);
        debugPrint('[MessagesProvider] Loaded ${messages.length} backend messages + ${filteredOptimistic.length} optimistic messages');
      } else {
        state = AsyncValue.data(messages);
        debugPrint('[MessagesProvider] Loaded ${messages.length} messages from backend');
      }
    } catch (error, stackTrace) {
      debugPrint('[MessagesProvider] Error loading messages: $error');
      debugPrint('[MessagesProvider] Stack trace: $stackTrace');
      state = AsyncValue.error(error, stackTrace);
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

  void refresh() {}

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
