import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presence/presence_ws_service.dart';

class ChatPreviewNotifier extends StateNotifier<Map<String, String>> {
  ChatPreviewNotifier(this._ref) : super(const {}) {
    final ws = _ref.read(presenceWsServiceProvider);
    _sub = ws.chatStream.listen((data) {
      try {
        final convId = data['conversationId']?.toString();
        if (convId == null || convId.isEmpty) return;
        String? preview;
        // Prefer decrypted preview when available
        if (data['decryptedPreview'] is String && (data['decryptedPreview'] as String).isNotEmpty) {
          preview = data['decryptedPreview'];
        } else if (data['content'] is String && (data['content'] as String).isNotEmpty) {
          preview = data['content'];
        } else {
          // Derive from messageType if set (attachments)
          final mt = (data['messageType'] ?? '').toString();
          if (mt == 'image') preview = '📷 Photo';
          if (mt == 'file') {
            final name = (data['metadata'] is Map) ? (data['metadata']['fileName']?.toString() ?? '') : '';
            preview = name.isNotEmpty ? '📎 $name' : '📎 File';
          }
        }
        if (preview != null && preview.isNotEmpty) {
          final copy = Map<String, String>.from(state);
          copy[convId] = preview;
          state = copy;
        }
      } catch (_) {}
    });
  }

  final Ref _ref;
  late final StreamSubscription<Map<String, dynamic>> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final chatPreviewProvider = StateNotifierProvider<ChatPreviewNotifier, Map<String, String>>((ref) {
  return ChatPreviewNotifier(ref);
});
