import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/chat_message.dart';
import '../../infrastructure/matrix_timeline_service.dart';
import '../../domain/services/chat_service.dart';

class ChatPreviewNotifier extends StateNotifier<Map<String, String>> {
  ChatPreviewNotifier(this._ref) : super(const {});

  final Ref _ref;
  final _subs = <String, StreamSubscription<List<ChatMessage>>>{};
  final _roomByConversation = <String, String>{};
  final _chatService = ChatService();
  final _backendFallback =
      <String, bool>{}; // Track if we need backend fallback

  Future<void> ensureWatching({
    required String conversationId,
    required String currentUserId,
    required String otherUserId,
  }) async {
    if (_subs.containsKey(conversationId)) return;

    // Load preview from backend FIRST (instant display)
    _loadBackendPreview(conversationId);

    // Then subscribe to Matrix updates
    // Resolve roomId
    String roomId;
    if (_roomByConversation.containsKey(conversationId)) {
      roomId = _roomByConversation[conversationId]!;
    } else {
      try {
        final rid = await _chatService.getMatrixRoomIdForConversation(
            conversationId: conversationId,
            currentUserId: currentUserId,
            otherUserId: otherUserId);
        roomId = rid ?? conversationId;
        _roomByConversation[conversationId] = roomId;
      } catch (e) {
        print('[ChatPreviewNotifier] Failed to resolve roomId: $e');
        _backendFallback[conversationId] = true;
        return; // Stay with backend preview
      }
    }
    final timeline = _ref.read(matrixTimelineServiceProvider);
    final sub = timeline.watchRoom(roomId).listen((messages) {
      if (messages.isEmpty) {
        // Keep backend preview if Matrix is empty
        return;
      }
      final last = messages.last;
      String preview;
      if (last.content.isNotEmpty && last.content != '[encrypted]') {
        preview = last.content;
      } else if (last.messageType == 'image') {
        preview = '📷 Photo';
      } else if (last.messageType == 'file') {
        final meta = last.metadata;
        String name = '';
        if (meta is Map<String, dynamic>) {
          final v = meta['fileName'];
          if (v != null) name = v.toString();
        }
        preview = name.isNotEmpty ? '📎 $name' : '📎 File';
      } else {
        preview = 'Encrypted message';
      }
      final copy = Map<String, String>.from(state);
      copy[conversationId] = preview;
      state = copy;
    });
    _subs[conversationId] = sub;
  }

  Future<void> _loadBackendPreview(String conversationId) async {
    try {
      final messages =
          await _chatService.getMessages(conversationId, ref: _ref);
      if (messages.isEmpty) return;

      final last = messages.last;
      String preview;
      if (last.content.isNotEmpty && last.content != '[encrypted]') {
        preview = last.content;
      } else if (last.messageType == 'image') {
        preview = '📷 Photo';
      } else if (last.messageType == 'file') {
        final meta = last.metadata;
        String name = '';
        if (meta is Map<String, dynamic>) {
          final v = meta['fileName'];
          if (v != null) name = v.toString();
        }
        preview = name.isNotEmpty ? '📎 $name' : '📎 File';
      } else {
        preview = 'Encrypted message';
      }

      final copy = Map<String, String>.from(state);
      copy[conversationId] = preview;
      state = copy;
    } catch (e) {
      print('[ChatPreviewNotifier] Failed to load backend preview: $e');
    }
  }

  @override
  void dispose() {
    for (final s in _subs.values) {
      s.cancel();
    }
    _subs.clear();
    super.dispose();
  }
}

final chatPreviewProvider =
    StateNotifierProvider<ChatPreviewNotifier, Map<String, String>>((ref) {
  return ChatPreviewNotifier(ref);
});
