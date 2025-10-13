import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/bridge.dart' as frb;
import 'package:immosync/features/chat/domain/models/chat_message.dart';
import 'package:immosync/features/chat/infrastructure/matrix_timeline_service.dart';
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
          deliveredAt: ts, // Message is delivered since we received it from server
          readAt: null,
          messageType: 'text',
          metadata: null,
          conversationId: roomId, // we will key timeline by roomId here
          isEncrypted: true, // Matrix rooms use encryption, content is auto-decrypted by SDK
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

  void _attachMobileClientEvents() {
    print('[MatrixFrbEventsAdapter] Subscribing to mobile client events for ${defaultTargetPlatform.name}');
    
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
          isEncrypted: true,
          e2ee: null,
        );

        print('[MatrixAdapter] Mobile event ingested: roomId=$roomId eventId=${evt.eventId} sender=${evt.sender} content=${displayContent.substring(0, displayContent.length > 50 ? 50 : displayContent.length)}');

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
