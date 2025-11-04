import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Central token management service to prevent race conditions
/// and duplicate token exchanges across multiple services
class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  static const String _tokenKey = 'sessionToken';
  static const String _userIdKey = 'userId';
  static const String _jwtSecret = 'z1xT7c!k9@Qs8Lm3^Rp5&Wn2#Vf6*Hj4';

  String? _cachedToken;
  DateTime? _lastRefresh;
  bool _isRefreshing = false;

  /// Get the current session token
  Future<String?> getToken() async {
    if (_cachedToken != null) {
      return _cachedToken;
    }

    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  /// Set a new session token
  Future<void> setToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _lastRefresh = DateTime.now();

    final prefix = token.substring(0, token.length < 8 ? token.length : 8);
    print('[TokenManager] Token updated; prefix=$prefix');
  }

  /// Clear the session token
  Future<void> clearToken() async {
    _cachedToken = null;
    _lastRefresh = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    print('[TokenManager] Token cleared');
  }

  /// Check if token needs refresh (older than 5 minutes)
  bool needsRefresh() {
    if (_lastRefresh == null) return true;
    final age = DateTime.now().difference(_lastRefresh!);
    return age.inMinutes > 5;
  }

  /// Refresh token using UI-JWT exchange (single execution, prevents race conditions)
  Future<bool> refreshToken(String apiUrl) async {
    // Prevent concurrent refresh attempts
    if (_isRefreshing) {
      print('[TokenManager] Refresh already in progress, waiting...');
      // Wait for ongoing refresh to complete
      while (_isRefreshing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedToken != null;
    }

    _isRefreshing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);

      if (userId == null || userId.isEmpty) {
        print('[TokenManager] No userId available for token refresh');
        return false;
      }

      final assertion = _buildUiJwt(userId);
      if (assertion == null) {
        print('[TokenManager] Failed to build UI-JWT');
        return false;
      }

      print('[TokenManager] Requesting token exchange for userId: $userId');
      
      final response = await http.post(
        Uri.parse('$apiUrl/auth/login-exchange'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $assertion',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final newToken = data['token'] as String?;

        if (newToken != null && newToken.isNotEmpty) {
          await setToken(newToken);
          print('[TokenManager] Token refresh successful');
          return true;
        } else {
          print('[TokenManager] Token refresh response missing token');
          return false;
        }
      } else {
        print('[TokenManager] Token refresh failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      print('[TokenManager] Token refresh error: $e');
      print(stackTrace);
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Build UI-JWT for token exchange
  String? _buildUiJwt(String userId) {
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final header = {'alg': 'HS256', 'typ': 'JWT'};
      final payload = {
        'userId': userId,
        'iat': now,
        'exp': now + 3600,
      };

      String b64Url(Map<String, dynamic> obj) {
        final str = json.encode(obj);
        return base64Url.encode(utf8.encode(str)).replaceAll('=', '');
      }

      final h = b64Url(header);
      final p = b64Url(payload);
      final data = utf8.encode('$h.$p');
      final key = utf8.encode(_jwtSecret);
      final sig = Hmac(sha256, key).convert(data);
      final s = base64Url.encode(sig.bytes).replaceAll('=', '');
      
      return '$h.$p.$s';
    } catch (e) {
      print('[TokenManager] Error building UI-JWT: $e');
      return null;
    }
  }

  /// Ensure a valid token is available, refreshing if necessary
  Future<void> ensureTokenAvailable(String apiUrl) async {
    final token = await getToken();
    
    // If no token or needs refresh, try to refresh
    if (token == null || token.isEmpty || needsRefresh()) {
      print('[TokenManager] Token unavailable or expired, refreshing...');
      await refreshToken(apiUrl);
    }
  }

  /// Get headers with current token
  Future<Map<String, String>> getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      
      final looksJwt = token.contains('.') && token.split('.').length == 3;
      final prefix = token.substring(0, token.length < 8 ? token.length : 8);
      print('[TokenManager] Adding token to headers; looksJwt=$looksJwt prefix=$prefix');
    } else {
      print('[TokenManager] No token available');
    }

    return headers;
  }
}
