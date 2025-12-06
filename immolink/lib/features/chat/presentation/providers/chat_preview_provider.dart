import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/chat_message.dart';
import '../../domain/services/chat_service.dart';
import '../../infrastructure/matrix_timeline_service.dart';
import 'chat_provider.dart';

class ChatPreviewNotifier extends StateNotifier<Map<String, String>> {
  ChatPreviewNotifier(this._ref) : super(const {});

  final Ref _ref;
  final _subs = <String, StreamSubscription<List<ChatMessage>>>{};
  final _roomByConversation = <String, String>{};

  ChatService get _chatService => _ref.read(chatServiceProvider);

  Future<void> ensureWatching({
    required String conversationId,
    required String currentUserId,
    required String otherUserId,
    String? fallbackPreview,
  }) async {
    if (!_subs.containsKey(conversationId)) {
      final normalized = _normalizePreview(fallbackPreview);
      if (normalized != null && normalized.isNotEmpty) {
        final next = Map<String, String>.from(state);
        next[conversationId] = normalized;
        state = next;
      }
    } else {
      // Already watching; no need to rewire subscription
      return;
    }

    final roomId = await _resolveRoomId(
      conversationId: conversationId,
      currentUserId: currentUserId,
      otherUserId: otherUserId,
    );

    final timeline = _ref.read(matrixTimelineServiceProvider);
    final snapshot = timeline.snapshot(roomId);
    if (snapshot != null && snapshot.isNotEmpty) {
      _setPreview(conversationId, snapshot.last);
    }

    final sub = timeline.watchRoom(roomId).listen((messages) {
      if (messages.isEmpty) return;
      _setPreview(conversationId, messages.last);
    });
    _subs[conversationId] = sub;

    unawaited(timeline.refreshHistory(roomId));
  }

  Future<String> _resolveRoomId({
    required String conversationId,
    required String currentUserId,
    required String otherUserId,
  }) async {
    if (_roomByConversation.containsKey(conversationId)) {
      return _roomByConversation[conversationId]!;
    }

    String roomId;
    try {
      final resolved = await _chatService.getMatrixRoomIdForConversation(
        conversationId: conversationId,
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      );
      roomId =
          (resolved != null && resolved.isNotEmpty) ? resolved : conversationId;
    } catch (e, st) {
      print('[ChatPreviewNotifier] Failed to resolve roomId: $e');
      print(st);
      roomId = conversationId;
    }

    _roomByConversation[conversationId] = roomId;
    return roomId;
  }

  void _setPreview(String conversationId, ChatMessage message) {
    final preview = _previewText(message);
    if (preview == null) return;
    final next = Map<String, String>.from(state);
    next[conversationId] = preview;
    state = next;
  }

  String? _previewText(ChatMessage message) =>
      _normalizePreview(message.content, message);

  String? _normalizePreview(String? raw, [ChatMessage? message]) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed == '[encrypted]') return 'Encrypted message';

    if (message != null && message.messageType == 'image') {
      return '[Photo]';
    }
    if (message != null && message.messageType == 'file') {
      final meta = message.metadata;
      String name = '';
      if (meta is Map<String, dynamic>) {
        final value = meta['fileName'];
        if (value != null) {
          name = value.toString();
        }
      }
      return name.isNotEmpty ? '[File] $name' : '[File]';
    }

    return trimmed;
  }

  @override
  void dispose() {
    for (final sub in _subs.values) {
      sub.cancel();
    }
    _subs.clear();
    super.dispose();
  }
}

final chatPreviewProvider =
    StateNotifierProvider<ChatPreviewNotifier, Map<String, String>>((ref) {
  return ChatPreviewNotifier(ref);
});
