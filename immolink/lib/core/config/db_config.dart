import 'package:flutter_dotenv/flutter_dotenv.dart';

class DbConfig {
  static String get connectionUri => dotenv.env['MONGODB_URI'] ?? 'mongodb://localhost:27017';
  static String get dbName => dotenv.env['MONGODB_DB_NAME'] ?? 'immolink';
  static String get apiUrl => dotenv.env['API_URL'] ?? 'https://backend.immosync.ch/api';
  static String get wsUrl {
    final raw = dotenv.env['WS_URL'];
    if (raw != null && raw.isNotEmpty) return raw;
    // Derive from apiUrl
    try {
      final uri = Uri.parse(apiUrl);
      final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
      final withoutApi = uri.path.endsWith('/api') ? uri.replace(path: uri.path.replaceFirst(RegExp(r'/api$'), '')) : uri;
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
  static String get primaryHost => dotenv.env['PRIMARY_HOST'] ?? 'https://immosync.ch';
  
  static void printConfig() {
    print('DbConfig loaded:');
    print('  connectionUri: $connectionUri');
    print('  dbName: $dbName');
    print('  apiUrl: $apiUrl');
  print('  wsUrl: $wsUrl');
  print('  primaryHost: $primaryHost');
    print('  env loaded: ${dotenv.env.isNotEmpty}');
    print('  API_URL from env: ${dotenv.env['API_URL']}');
    
    // Verify services will use correct URL
    print('Services will use API URL: $apiUrl');
  }
}
