import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/core/presence/presence_ws_service.dart';
import 'package:immosync/features/chat/domain/models/chat_message.dart';
import 'package:immosync/features/chat/infrastructure/matrix_timeline_service.dart';

/// Temporary adapter: bridges incoming WS chat events into the MatrixTimelineService.
///
/// Rationale: Until the native Matrix FRB events stream is wired, this ensures
/// the UI receives live updates. Once FRB events are available, swap the source
/// to ingest from the Matrix bridge and remove the WS dependency for chat.
class MatrixEventsAdapter {
  final MatrixTimelineService _timeline;
  final PresenceWsService _presence;
  StreamSubscription<Map<String, dynamic>>? _sub;

  MatrixEventsAdapter(this._timeline, this._presence) {
    _attach();
  }

  void _attach() {
    _sub?.cancel();
    _sub = _presence.chatStream.listen((evt) {
      try {
        final type = evt['type']?.toString();
        if (type == 'typing' || type == 'read' || type == 'delivered') {
          return; // presence/read receipts handled elsewhere
        }
        final convId = evt['conversationId']?.toString();
        if (convId == null || convId.isEmpty) return;

        // Map payload to ChatMessage
        final mapped = _toChatMessage(evt);
        if (mapped == null) return;

        // Note: We key timelines by conversationId for now.
        // When FRB Matrix events are ready, prefer matrix roomId as key.
        if (type == 'ack') {
          // Server ack may include canonical message id - replace optimistic
          if (mapped.id.isNotEmpty) {
            _timeline.replaceById(convId, mapped.id, mapped);
          } else {
            _timeline.ingestMatrixEvent(convId, mapped);
          }
        } else {
          _timeline.ingestMatrixEvent(convId, mapped);
        }
      } catch (_) {
        // ignore mapping errors to avoid crashing the stream
      }
    });
  }

  ChatMessage? _toChatMessage(Map data) {
    // Expected fields from WS: _id/id, senderId, receiverId, content or e2ee, timestamp, conversationId
    // presence service already attempts to decrypt and sets content when possible
    try {
      final tsRaw = data['timestamp']?.toString() ?? data['clientTime']?.toString();
      final ts = tsRaw != null ? DateTime.tryParse(tsRaw) ?? DateTime.now() : DateTime.now();
      final id = data['_id']?.toString() ?? data['id']?.toString() ?? '';
      final content = data['content']?.toString() ?? '[encrypted]';
      return ChatMessage(
        id: id,
        senderId: data['senderId']?.toString() ?? '',
        receiverId: data['receiverId']?.toString() ?? '',
        content: content,
        timestamp: ts,
        isRead: data['isRead'] == true,
        deliveredAt: data['deliveredAt'] != null
            ? DateTime.tryParse(data['deliveredAt'].toString())
            : null,
        readAt: data['readAt'] != null
            ? DateTime.tryParse(data['readAt'].toString())
            : null,
        messageType: data['messageType']?.toString() ?? 'text',
        metadata: data['metadata'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['metadata'])
            : null,
        conversationId: data['conversationId']?.toString(),
        isEncrypted: data['e2ee'] != null && data['content'] == null,
        e2ee: data['e2ee'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['e2ee'])
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}

final matrixEventsAdapterProvider = Provider<MatrixEventsAdapter>((ref) {
  final timeline = ref.read(matrixTimelineServiceProvider);
  final presence = ref.read(presenceWsServiceProvider);
  final adapter = MatrixEventsAdapter(timeline, presence);
  ref.onDispose(() => adapter.dispose());
  return adapter;
});
