import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/http_chat_service.dart';

final chatServiceProvider = Provider<HttpChatService>((ref) {
  return HttpChatService();
});
