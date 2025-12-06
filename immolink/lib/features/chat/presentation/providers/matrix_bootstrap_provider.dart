import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import 'chat_provider.dart';

/// Keeps the Matrix client warm once the user opens the app so that
/// conversations load instantly when navigating to chat screens.
final matrixBootstrapProvider = Provider<void>((ref) {
  final chatService = ref.read(chatServiceProvider);
  bool ensuring = false;
  String? ensuredUserId;

  Future<void> ensureFor(String userId) async {
    if (ensuring) return;
    ensuring = true;
    try {
      debugPrint('[MatrixBootstrap] ensureMatrixReady -> $userId');
      await chatService.ensureMatrixReady(userId: userId, required: false);
      ensuredUserId = userId;
      debugPrint('[MatrixBootstrap] Matrix ready for $userId');
    } catch (e, st) {
      debugPrint('[MatrixBootstrap] ensureMatrixReady failed: $e');
      debugPrint(st.toString());
      // Allow retry on next auth change
    } finally {
      ensuring = false;
    }
  }

  final sub = ref.listen<AuthState>(authProvider, (previous, next) {
    final userId = next.userId;
    if (next.isAuthenticated &&
        userId != null &&
        userId.isNotEmpty &&
        ensuredUserId != userId) {
      Future.microtask(() => ensureFor(userId));
    } else if (!next.isAuthenticated) {
      ensuredUserId = null;
    }
  }, fireImmediately: true);

  ref.onDispose(sub.close);
});
