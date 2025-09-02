import 'db_config.dart';
import 'package:flutter/foundation.dart';

/// Central API configuration wrapper so all services share identical base URL logic.
class ApiConfig {
  /// Primary base URL sourced from env (falls back to production backend).
  static String get baseUrl => DbConfig.apiUrl;

  /// Convenience for composing full endpoint paths.
  static Uri endpoint(String path, {Map<String, dynamic>? query}) {
    final q = query?.map((k, v) => MapEntry(k, v.toString()));
    return Uri.parse('$baseUrl$path').replace(queryParameters: q);
  }

  /// Helpful debug print.
  static void debugPrintConfig() {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[ApiConfig] baseUrl=$baseUrl');
    }
  }
}
