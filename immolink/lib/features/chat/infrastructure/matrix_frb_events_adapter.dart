import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/bridge.dart' as frb;
import 'package:immosync/features/chat/domain/models/chat_message.dart';
import 'package:immosync/features/chat/infrastructure/matrix_timeline_service.dart';

/// MatrixFrbEventsAdapter
///
/// Listens to the native Matrix FRB event stream and forwards message events
/// into the MatrixTimelineService. This will supersede the temporary WS adapter
/// once the native stream is generated and wired.
class MatrixFrbEventsAdapter {
  final MatrixTimelineService _timeline;
  StreamSubscription<Map<String, dynamic>>? _sub;

  MatrixFrbEventsAdapter(this._timeline) {
    _attach();
  }

  void _attach() {
    _sub?.cancel();
    // Subscribe to native events. The FRB function should yield maps with keys:
    // room_id, event_id, sender, ts (ms or s), content (optional), is_encrypted
    _sub = frb.subscribeEvents().listen((evt) {
      try {
        final roomId = (evt['room_id'] ?? evt['roomId'])?.toString();
        if (roomId == null || roomId.isEmpty) return;
        final tsRaw = evt['ts'];
        DateTime ts;
        if (tsRaw is int) {
          // Heuristic: if it's large use ms, otherwise seconds
          ts = DateTime.fromMillisecondsSinceEpoch(
              tsRaw > 2000000000 ? tsRaw : tsRaw * 1000,
              isUtc: true);
        } else if (tsRaw is String) {
          ts = DateTime.tryParse(tsRaw) ?? DateTime.now();
        } else {
          ts = DateTime.now();
        }

        final msg = ChatMessage(
          id: evt['event_id']?.toString() ?? '',
          senderId: evt['sender']?.toString() ?? '',
          receiverId: '',
          content: (evt['content']?.toString() ?? '[encrypted]'),
          timestamp: ts,
          isRead: false,
          deliveredAt: null,
          readAt: null,
          messageType: 'text',
          metadata: null,
          conversationId: roomId, // we will key timeline by roomId here
          isEncrypted: evt['is_encrypted'] == true,
          e2ee: null,
        );
        _timeline.ingestMatrixEvent(roomId, msg);
      } catch (_) {
        // ignore malformed events
      }
    });
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}

final matrixFrbEventsAdapterProvider = Provider<MatrixFrbEventsAdapter>((ref) {
  final timeline = ref.read(matrixTimelineServiceProvider);
  final adapter = MatrixFrbEventsAdapter(timeline);
  ref.onDispose(() => adapter.dispose());
  return adapter;
});
