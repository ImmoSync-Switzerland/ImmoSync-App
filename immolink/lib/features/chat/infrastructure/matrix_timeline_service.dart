import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:immosync/features/chat/domain/models/chat_message.dart';
import 'package:immosync/bridge.dart' as frb;
import 'mobile_matrix_client.dart';

/// MatrixTimelineService
///
/// Provides a per-room timeline stream for ChatMessage items.
/// This is an in-memory stream that supports optimistic inserts now and
/// is designed to be wired to the FRB Matrix event stream when available.
class MatrixTimelineService {
  static final MatrixTimelineService instance = MatrixTimelineService._();
  MatrixTimelineService._();

  final Map<String, StreamController<List<ChatMessage>>> _controllers = {};
  final Map<String, List<ChatMessage>> _buffers = {};
  final Map<String, bool> _historyLoaded =
      {}; // Track which rooms have loaded history

  /// Check if the current platform supports the Matrix Rust bridge
  bool get _isRustBridgeSupported {
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Stream<List<ChatMessage>> watchRoom(String roomId) {
    final ctrl = _controllers.putIfAbsent(
      roomId,
      StreamController<List<ChatMessage>>.broadcast,
    );
    _buffers.putIfAbsent(roomId, () => <ChatMessage>[]);

    // Load historical messages if not already loaded
    if (!_historyLoaded.containsKey(roomId)) {
      _historyLoaded[roomId] = true;
      _loadHistoricalMessages(roomId);
    }

    // Emit current buffer on new subscription
    scheduleMicrotask(() {
      if (!ctrl.isClosed) ctrl.add(List.unmodifiable(_buffers[roomId]!));
    });
    return ctrl.stream;
  }

  /// Load historical messages from Matrix room
  Future<void> _loadHistoricalMessages(String roomId,
      {bool immediate = false}) async {
    try {
      debugPrint('[MatrixTimeline] Loading history for room: $roomId');

      // Wait a bit for sync to complete before querying (shorter/skip on manual refresh)
      if (!immediate) {
        await Future.delayed(const Duration(seconds: 2));
      } else {
        await Future.delayed(const Duration(milliseconds: 200));
      }

      debugPrint('[MatrixTimeline] Calling getRoomMessages...');

      // Use appropriate client based on platform
      String jsonStr;
      if (_isRustBridgeSupported) {
        jsonStr = await frb.getRoomMessages(roomId: roomId, limit: 50);
      } else {
        // Use mobile client
        final mobileClient = MobileMatrixClient.instance;
        jsonStr = await mobileClient.getRoomMessages(roomId, 50);
      }

      debugPrint('[MatrixTimeline] getRoomMessages returned: $jsonStr');

      final List<dynamic> messages = jsonDecode(jsonStr);

      debugPrint(
          '[MatrixTimeline] Loaded ${messages.length} historical messages');

      if (messages.isEmpty) {
        debugPrint(
            '[MatrixTimeline] No messages found - room might be new or user not synced yet');
        return;
      }

      for (final msgData in messages) {
        try {
          // Extract user ID from Matrix MXID format: @userid:homeserver -> userid
          String extractUserId(String mxid) {
            if (mxid.startsWith('@') && mxid.contains(':')) {
              return mxid.substring(1, mxid.indexOf(':'));
            }
            return mxid;
          }

          // Timestamp is in seconds from Rust, convert to milliseconds
          final timestampSecs = msgData['timestamp'] as int;
          final senderMxid = msgData['sender'] as String;
          final senderId = extractUserId(senderMxid);

          final ts = DateTime.fromMillisecondsSinceEpoch(timestampSecs * 1000,
              isUtc: true);

          final message = ChatMessage(
            id: msgData['eventId'] as String,
            conversationId: roomId,
            senderId: senderId,
            receiverId: '', // Will be determined by context
            content: msgData['body'] as String,
            timestamp: ts,
            deliveredAt:
                ts, // Historical messages were already delivered to server
            isEncrypted:
                true, // Matrix rooms use encryption, content is auto-decrypted by SDK
            messageType: 'text',
          );

          debugPrint(
              '[MatrixTimeline] Ingesting message from $senderMxid -> $senderId: ${message.content}');

          // If message already exists (e.g., placeholder from live event), replace with full content
          final list = _buffers.putIfAbsent(roomId, () => <ChatMessage>[]);
          final existingIdx = list.indexWhere((m) => m.id == message.id);
          if (existingIdx >= 0) {
            // Prefer non-empty/non-placeholder content, but replace regardless to normalize timestamps
            list[existingIdx] = message;
            _controllers[roomId]?.add(List.unmodifiable(
                list..sort((a, b) => a.timestamp.compareTo(b.timestamp))));
          } else {
            ingestMatrixEvent(roomId, message);
          }
        } catch (e) {
          debugPrint('[MatrixTimeline] Failed to parse message: $e');
        }
      }

      debugPrint(
          '[MatrixTimeline] History loaded successfully for $roomId: ${messages.length} messages');
    } catch (e) {
      debugPrint('[MatrixTimeline] Failed to load history for $roomId: $e');
      // Continue gracefully - new messages will still work via event stream
    }
  }

  /// Public method to force a quick history refresh (used when live events lack plaintext content)
  Future<void> refreshHistory(String roomId) =>
      _loadHistoricalMessages(roomId, immediate: true);

  void pushLocal(String roomId, ChatMessage msg) {
    final list = _buffers.putIfAbsent(roomId, () => <ChatMessage>[]);
    list.add(msg);
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _controllers[roomId]?.add(List.unmodifiable(list));
  }

  void replaceById(String roomId, String id, ChatMessage replacement) {
    final list = _buffers[roomId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m.id == id);
    if (idx >= 0) {
      list[idx] = replacement;
      _controllers[roomId]?.add(List.unmodifiable(list));
    }
  }

  void ingestMatrixEvent(String roomId, ChatMessage msg) {
    // Avoid duplicates
    final list = _buffers.putIfAbsent(roomId, () => <ChatMessage>[]);
    final dup = list.any((m) => m.id == msg.id);
    if (!dup) {
      list.add(msg);
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _controllers[roomId]?.add(List.unmodifiable(list));
    }
  }
}

final matrixTimelineServiceProvider = Provider<MatrixTimelineService>((ref) {
  return MatrixTimelineService.instance;
});
