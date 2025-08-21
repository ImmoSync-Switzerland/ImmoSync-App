import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/chat_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});
