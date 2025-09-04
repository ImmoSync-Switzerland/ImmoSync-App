import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:immosync/core/config/api_config.dart';
import '../../domain/models/app_notification.dart';

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<List<AppNotification>>>((ref) {
  final auth = ref.watch(authProvider);
  return NotificationsNotifier(ref, auth.userId);
});

class NotificationsNotifier extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final Ref ref;
  String? _userId;
  NotificationsNotifier(this.ref, this._userId) : super(const AsyncLoading()) {
    _maybeLoad();
  }

  static String get _baseUrl => ApiConfig.baseUrl;

  void updateUser(String? userId) {
    if (userId == _userId) return;
    _userId = userId;
    _maybeLoad();
  }

  Future<void> _maybeLoad() async {
    if (_userId == null) {
      state = const AsyncData([]);
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    if (_userId == null) return;
    state = const AsyncLoading();
    try {
  final resp = await http.get(Uri.parse('$_baseUrl/notifications/list/$_userId?limit=100'));
      if (resp.statusCode == 200) {
        final jsonBody = jsonDecode(resp.body) as Map<String, dynamic>;
        final list = (jsonBody['notifications'] as List<dynamic>)
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
        state = AsyncData(list);
      } else {
        state = AsyncError('HTTP ${resp.statusCode}', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> markAllRead() async {
    if (_userId == null) return;
    try {
      await http.post(
        Uri.parse('$_baseUrl/notifications/mark-read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': _userId, 'all': true}),
      );
      final current = state.value ?? [];
      state = AsyncData(current.map((n) => AppNotification(
            id: n.id,
            title: n.title,
            body: n.body,
            type: n.type,
            data: n.data,
            timestamp: n.timestamp,
            read: true,
          )).toList());
    } catch (_) {}
  }

  // Internal helper for UI single-tap marking (local only for now)
  Future<void> markNotificationRead(String id) async {
    if (_userId == null) return;
    // Optimistic local update first
    final current = state.value;
    if (current != null) {
      final updated = current.map((n) => n.id == id ? AppNotification(
        id: n.id,
        title: n.title,
        body: n.body,
        type: n.type,
        data: n.data,
        timestamp: n.timestamp,
        read: true,
      ) : n).toList();
      state = AsyncData(updated);
    }
    try {
      await http.post(
        Uri.parse('$_baseUrl/notifications/mark-read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': _userId, 'ids': [id]}),
      );
    } catch (_) {
      // silently ignore
    }
  }

  // Backward compatibility name used by popup
  void markSingleRead(String id) { markNotificationRead(id); }
}
