// Compile-time configuration via --dart-define; fallback defaults remain.

class DbConfig {
  static const String connectionUri = String.fromEnvironment(
    'MONGODB_URI', defaultValue: 'mongodb://localhost:27017');
  static const String dbName =
    String.fromEnvironment('MONGODB_DB_NAME', defaultValue: 'immolink');
  static const String apiUrl = String.fromEnvironment(
    'API_URL', defaultValue: 'https://backend.immosync.ch/api');
  static String get wsUrl {
  const raw = String.fromEnvironment('WS_URL');
  if (raw.isNotEmpty) return raw;
    // Derive from apiUrl
    try {
      final uri = Uri.parse(apiUrl);
      final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
      final withoutApi = uri.path.endsWith('/api')
          ? uri.replace(path: uri.path.replaceFirst(RegExp(r'/api$'), ''))
          : uri;
      return Uri(
        scheme: scheme,
        host: withoutApi.host,
        port: withoutApi.hasPort ? withoutApi.port : null,
        path: '/',
      ).toString();
    } catch (_) {
      return 'ws://localhost:3000';
    }
  }

  // Primary public host (for CDN / user-facing asset links) can differ from API host
  static const String primaryHost = String.fromEnvironment(
    'PRIMARY_HOST', defaultValue: 'https://immosync.ch');

  static void printConfig() {
    print('DbConfig loaded:');
    print('  connectionUri: $connectionUri');
    print('  dbName: $dbName');
    print('  apiUrl: $apiUrl');
    print('  wsUrl: $wsUrl');
    print('  primaryHost: $primaryHost');
  print('  (dart-define) API_URL: $apiUrl');

    // Verify services will use correct URL
    print('Services will use API URL: $apiUrl');
  }
}
