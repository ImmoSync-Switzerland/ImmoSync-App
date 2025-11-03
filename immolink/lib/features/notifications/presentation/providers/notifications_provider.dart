import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:crypto/crypto.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:immosync/core/config/api_config.dart';
import '../../domain/models/app_notification.dart';

final notificationsProvider = StateNotifierProvider<NotificationsNotifier,
    AsyncValue<List<AppNotification>>>((ref) {
  final auth = ref.watch(authProvider);
  return NotificationsNotifier(ref, auth.userId);
});

class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final Ref ref;
  String? _userId;
  NotificationsNotifier(this.ref, this._userId) : super(const AsyncLoading()) {
    _maybeLoad();
  }

  static String get _baseUrl => ApiConfig.baseUrl;

  String? _buildUiJwt(String userId) {
    try {
      final secret = dotenv.dotenv.isInitialized
          ? (dotenv.dotenv.env['JWT_SECRET'] ?? '')
          : '';
      if (secret.isEmpty) return null;
      final header = {'alg': 'HS256', 'typ': 'JWT'};
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final payload = {'sub': userId, 'iat': now, 'exp': now + 300};
      String b64Url(Map obj) {
        final jsonStr = json.encode(obj);
        final b64 = base64Url.encode(utf8.encode(jsonStr));
        return b64.replaceAll('=', '');
      }
      final h = b64Url(header);
      final p = b64Url(payload);
      final data = utf8.encode('$h.$p');
      final key = utf8.encode(secret);
      final sig = Hmac(sha256, key).convert(data);
      final s = base64Url.encode(sig.bytes).replaceAll('=', '');
      return '$h.$p.$s';
    } catch (_) {
      return null;
    }
  }

  Future<void> _tryLoginExchangeWithUiJwt() async {
    if (_userId == null || _userId!.isEmpty) return;
    try {
      final assertion = _buildUiJwt(_userId!);
      if (assertion == null) return;
      final ex = await http.post(
        Uri.parse('$_baseUrl/auth/login-exchange'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $assertion',
        },
      );
      if (ex.statusCode == 200) {
        final data = json.decode(ex.body) as Map<String, dynamic>;
        final newToken = data['token'] as String?;
        if (newToken != null && newToken.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('sessionToken', newToken);
        }
      }
    } catch (_) {}
  }

  Future<Map<String, String>> _headers() async {
    final base = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('sessionToken');
      // If token looks like a UI JWT, proactively exchange
      if (token != null && token.contains('.')) {
        try {
          final ex = await http.post(
            Uri.parse('$_baseUrl/auth/login-exchange'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
          if (ex.statusCode == 200) {
            final data = json.decode(ex.body) as Map<String, dynamic>;
            final newToken = data['token'] as String?;
            if (newToken != null && newToken.isNotEmpty) {
              await prefs.setString('sessionToken', newToken);
              token = newToken;
            }
          }
        } catch (_) {}
      }
      if (token != null && token.isNotEmpty) {
        base['Authorization'] = 'Bearer $token';
        base['x-access-token'] = token;
        base['x-session-token'] = token;
      }
    } catch (_) {}
    return base;
  }

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

  Future<bool> refresh() async {
    if (_userId == null) return true; // nothing to load
    state = const AsyncLoading();
    try {
      var resp = await http.get(
        Uri.parse('$_baseUrl/notifications/list/$_userId?limit=100'),
        headers: await _headers(),
      );
      if (resp.statusCode == 401) {
        await _tryLoginExchangeWithUiJwt();
        resp = await http.get(
          Uri.parse('$_baseUrl/notifications/list/$_userId?limit=100'),
          headers: await _headers(),
        );
      }
      if (resp.statusCode == 200) {
        final jsonBody = jsonDecode(resp.body) as Map<String, dynamic>;
        final list = (jsonBody['notifications'] as List<dynamic>)
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
        state = AsyncData(list);
        return true;
      } else {
        state = AsyncError('HTTP ${resp.statusCode}', StackTrace.current);
        return false;
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<int> markAllRead() async {
    if (_userId == null) return 0;
    try {
      var resp = await http.post(
        Uri.parse('$_baseUrl/notifications/mark-read'),
        headers: await _headers(),
        body: jsonEncode({'userId': _userId, 'all': true}),
      );
      if (resp.statusCode == 401) {
        await _tryLoginExchangeWithUiJwt();
        resp = await http.post(
          Uri.parse('$_baseUrl/notifications/mark-read'),
          headers: await _headers(),
          body: jsonEncode({'userId': _userId, 'all': true}),
        );
      }
      int updated = 0;
      try {
        final body = jsonDecode(resp.body);
        updated = (body is Map && body['updated'] is num)
            ? (body['updated'] as num).toInt()
            : 0;
      } catch (_) {}
      final current = state.value ?? [];
      state = AsyncData(current
          .map((n) => AppNotification(
                id: n.id,
                title: n.title,
                body: n.body,
                type: n.type,
                data: n.data,
                timestamp: n.timestamp,
                read: true,
              ))
          .toList());
      return updated;
    } catch (_) {
      return 0;
    }
  }

  // Internal helper for UI single-tap marking (local only for now)
  Future<void> markNotificationRead(String id) async {
    if (_userId == null) return;
    // Optimistic local update first
    final current = state.value;
    if (current != null) {
      final updated = current
          .map((n) => n.id == id
              ? AppNotification(
                  id: n.id,
                  title: n.title,
                  body: n.body,
                  type: n.type,
                  data: n.data,
                  timestamp: n.timestamp,
                  read: true,
                )
              : n)
          .toList();
      state = AsyncData(updated);
    }
    try {
      var resp = await http.post(
        Uri.parse('$_baseUrl/notifications/mark-read'),
        headers: await _headers(),
        body: jsonEncode({
          'userId': _userId,
          'ids': [id]
        }),
      );
      if (resp.statusCode == 401) {
        await _tryLoginExchangeWithUiJwt();
        await http.post(
          Uri.parse('$_baseUrl/notifications/mark-read'),
          headers: await _headers(),
          body: jsonEncode({
            'userId': _userId,
            'ids': [id]
          }),
        );
      }
    } catch (_) {
      // silently ignore
    }
  }

  // Backward compatibility name used by popup
  void markSingleRead(String id) {
    markNotificationRead(id);
  }
}
