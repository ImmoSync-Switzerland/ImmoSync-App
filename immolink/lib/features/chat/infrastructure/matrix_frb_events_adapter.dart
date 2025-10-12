import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/bridge.dart' as frb;
import 'package:immosync/bridge.dart' show MatrixEvent;
import 'package:immosync/features/chat/domain/models/chat_message.dart';
import 'package:immosync/features/chat/infrastructure/matrix_timeline_service.dart';

/// MatrixFrbEventsAdapter
///
/// Listens to the native Matrix FRB event stream and forwards message events
/// into the MatrixTimelineService. This will supersede the temporary WS adapter
/// once the native stream is generated and wired.
class MatrixFrbEventsAdapter {
  final MatrixTimelineService _timeline;
  StreamSubscription<MatrixEvent>? _sub;

  MatrixFrbEventsAdapter(this._timeline) {
    _attach();
  }

  void _attach() {
    _sub?.cancel();
    // Subscribe to native events. The FRB function should yield maps with keys:
    // room_id, event_id, sender, ts (ms or s), content (optional), is_encrypted
    _sub = frb.subscribeEvents().listen((evt) {
      try {
        final roomId = evt.roomId;
        if (roomId.isEmpty) return;
        // Timestamp is in seconds from Rust, convert to milliseconds
        final tsSecs = evt.ts.toInt();
        final ts = DateTime.fromMillisecondsSinceEpoch(tsSecs * 1000, isUtc: true);

        // Content should already be decrypted by the SDK if keys are available
        // If content is null/empty but marked encrypted, show placeholder
        final displayContent = (evt.content != null && evt.content!.isNotEmpty)
            ? evt.content!
            : (evt.isEncrypted ? '[encrypted]' : '');

        // Extract user ID from Matrix MXID format: @userid:homeserver -> userid
        // Example: @6838699baefe2c0213aba1c3:matrix.immosync.ch -> 6838699baefe2c0213aba1c3
        String extractUserId(String mxid) {
          if (mxid.startsWith('@') && mxid.contains(':')) {
            return mxid.substring(1, mxid.indexOf(':'));
          }
          return mxid; // fallback if format is unexpected
        }
        
        final senderId = extractUserId(evt.sender);

        final msg = ChatMessage(
          id: evt.eventId,
          senderId: senderId,
          receiverId: '',
          content: displayContent,
          timestamp: ts,
          isRead: false,
          deliveredAt: null,
          readAt: null,
          messageType: 'text',
          metadata: null,
          conversationId: roomId, // we will key timeline by roomId here
          isEncrypted: evt.isEncrypted &&
              displayContent ==
                  '[encrypted]', // only mark encrypted if we couldn't decrypt
          e2ee: null,
        );

        print(
            '[MatrixAdapter] Ingesting event roomId=$roomId eventId=${evt.eventId} sender=${evt.sender} extracted=$senderId encrypted=${evt.isEncrypted} hasContent=${evt.content != null} content=${displayContent.substring(0, displayContent.length > 50 ? 50 : displayContent.length)}');

        _timeline.ingestMatrixEvent(roomId, msg);
      } catch (e) {
        print('[MatrixAdapter] Error processing event: $e');
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
