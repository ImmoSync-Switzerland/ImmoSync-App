import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/chat/domain/models/chat_message.dart';

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

  Stream<List<ChatMessage>> watchRoom(String roomId) {
    final ctrl = _controllers.putIfAbsent(
      roomId,
      () => StreamController<List<ChatMessage>>.broadcast(),
    );
    _buffers.putIfAbsent(roomId, () => <ChatMessage>[]);
    // Emit current buffer on new subscription
    scheduleMicrotask(() {
      if (!ctrl.isClosed) ctrl.add(List.unmodifiable(_buffers[roomId]!));
    });
    return ctrl.stream;
  }

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
