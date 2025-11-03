import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/token_manager.dart';

/// Provider for the centralized token manager
final tokenManagerProvider = Provider<TokenManager>((ref) {
  return TokenManager();
});
