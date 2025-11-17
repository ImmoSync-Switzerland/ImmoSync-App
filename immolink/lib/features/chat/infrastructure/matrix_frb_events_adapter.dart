import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/chat/domain/models/chat_message.dart';
import 'package:immosync/features/chat/infrastructure/matrix_timeline_service.dart';
import 'package:immosync/features/chat/infrastructure/matrix_chat_service.dart';
import 'mobile_matrix_client.dart';

/// MatrixFrbEventsAdapter
///
/// Listens to the native Matrix FRB event stream and forwards message events
/// into the MatrixTimelineService. This will supersede the temporary WS adapter
/// once the native stream is generated and wired.
class MatrixFrbEventsAdapter {
  final MatrixTimelineService _timeline;
  StreamSubscription? _sub;

  MatrixFrbEventsAdapter(this._timeline) {
    _attach();
  }

  /// Check if the current platform supports the Matrix Rust bridge
  bool get _isRustBridgeSupported {
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  void _attach() {
    _sub?.cancel();

    if (_isRustBridgeSupported) {
      // Subscribe to Rust bridge events on desktop platforms
      _attachRustBridgeEvents();
    } else {
      // Subscribe to mobile client events on mobile platforms
      _attachMobileClientEvents();
    }
  }

  void _attachRustBridgeEvents() {
    // Signal that we're listening to the Rust bridge event stream
    print('[MatrixAdapter] Attaching Rust bridge events subscription...');
    // Subscribe to the MatrixChatService event bus (single native subscription upstream)
    // The event exposes: room_id, event_id, sender, ts (secs), content (optional), is_encrypted
    _sub = MatrixChatService.instance.eventStream.listen((evt) {
      try {
        final roomId = evt.roomId;
        if (roomId.isEmpty) return;
        // Timestamp is in seconds from Rust, convert to milliseconds
        final tsSecs = evt.ts.toInt();
        final ts =
            DateTime.fromMillisecondsSinceEpoch(tsSecs * 1000, isUtc: true);

        // Content should already be decrypted by the SDK if keys are available
        // If content is null/empty but marked encrypted, show placeholder
        final hasPlain = (evt.content != null && evt.content!.isNotEmpty);
        final displayContent =
            hasPlain ? evt.content! : (evt.isEncrypted ? '[encrypted]' : '');

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
          deliveredAt:
              ts, // Message is delivered since we received it from server
          readAt: null,
          messageType: 'text',
          metadata: null,
          conversationId: roomId, // we will key timeline by roomId here
          // In our app, Matrix DM rooms are always E2EE; show lock consistently
          // Some SDKs may report decrypted timeline events as non-encrypted.
          isEncrypted: true,
          e2ee: null,
        );

        print(
            '[MatrixAdapter] Ingesting event roomId=$roomId eventId=${evt.eventId} sender=${evt.sender} extracted=$senderId encrypted=${evt.isEncrypted} hasContent=${evt.content != null} content=${displayContent.substring(0, displayContent.length > 50 ? 50 : displayContent.length)}');

        _timeline.ingestMatrixEvent(roomId, msg);

        // If plaintext was not available yet, trigger a quick history refresh
        // to backfill decrypted content and replace the placeholder.
        if (!hasPlain && evt.isEncrypted) {
          // Small delay allows crypto to catch up
          Future.delayed(const Duration(milliseconds: 300), () {
            _timeline.refreshHistory(roomId);
          });
        }
      } catch (e) {
        print('[MatrixAdapter] Error processing event: $e');
        // ignore malformed events
      }
    });
  }

  void _attachMobileClientEvents() {
    print(
        '[MatrixFrbEventsAdapter] Subscribing to mobile client events for ${defaultTargetPlatform.name}');

    final mobileClient = MobileMatrixClient.instance;
    _sub = mobileClient.eventStream.listen((evt) {
      try {
        final roomId = evt.roomId;
        if (roomId.isEmpty) return;

        // Timestamp is already in milliseconds from mobile client
        final ts = DateTime.fromMillisecondsSinceEpoch(evt.ts, isUtc: true);

        // Content should already be decrypted by the SDK if keys are available
        final displayContent = (evt.content != null && evt.content!.isNotEmpty)
            ? evt.content!
            : (evt.isEncrypted ? '[encrypted]' : '');

        // Extract user ID from Matrix MXID format: @userid:homeserver -> userid
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
          deliveredAt: ts,
          readAt: null,
          messageType: 'text',
          metadata: null,
          conversationId: roomId,
          // For mobile client too, treat DM rooms as encrypted for UI lock
          isEncrypted: true,
          e2ee: null,
        );

        print(
            '[MatrixAdapter] Mobile event ingested: roomId=$roomId eventId=${evt.eventId} sender=${evt.sender} content=${displayContent.substring(0, displayContent.length > 50 ? 50 : displayContent.length)}');

        _timeline.ingestMatrixEvent(roomId, msg);
      } catch (e) {
        print('[MatrixAdapter] Error processing mobile event: $e');
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
