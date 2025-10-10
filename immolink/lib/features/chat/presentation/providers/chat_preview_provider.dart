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

  Future<void> ensureWatching({
    required String conversationId,
    required String currentUserId,
    required String otherUserId,
  }) async {
    if (_subs.containsKey(conversationId)) return;
    // Resolve roomId
    String roomId;
    if (_roomByConversation.containsKey(conversationId)) {
      roomId = _roomByConversation[conversationId]!;
    } else {
      final rid = await _chatService.getMatrixRoomIdForConversation(
          conversationId: conversationId,
          currentUserId: currentUserId,
          otherUserId: otherUserId);
      roomId = rid ?? conversationId;
      _roomByConversation[conversationId] = roomId;
    }
    final timeline = _ref.read(matrixTimelineServiceProvider);
    final sub = timeline.watchRoom(roomId).listen((messages) {
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
    });
    _subs[conversationId] = sub;
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
