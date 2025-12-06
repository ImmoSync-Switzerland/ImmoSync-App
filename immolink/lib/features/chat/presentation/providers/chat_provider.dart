import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/chat/domain/services/chat_service.dart';

/// Shared provider that exposes the Matrix-backed [ChatService].
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});
