// Config with preference order: .env (runtime) > --dart-define (compile-time) > defaults.
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;

class DbConfig {
  // Whether to force using HTTP-based DB proxy even on desktop
  static bool get forceHttpDb {
    final env = (dotenv.dotenv.isInitialized
        ? dotenv.dotenv.env['DB_FORCE_HTTP']
        : null);
    if (env != null && env.isNotEmpty) {
      return env == '1' || env.toLowerCase() == 'true';
    }
    const dd = String.fromEnvironment('DB_FORCE_HTTP');
    if (dd.isNotEmpty) {
      return dd == '1' || dd.toLowerCase() == 'true';
    }
    return false;
  }

  // Whether a MongoDB URI is provided via env (to avoid localhost fallback on desktop)
  static bool get hasMongoEnv {
    final env = (dotenv.dotenv.isInitialized
        ? dotenv.dotenv.env['MONGODB_URI']
        : null);
    return env != null && env.isNotEmpty;
  }

  static String get connectionUri {
    final env =
        (dotenv.dotenv.isInitialized ? dotenv.dotenv.env['MONGODB_URI'] : null);
    if (env != null && env.isNotEmpty) return env;
    const dd = String.fromEnvironment('MONGODB_URI',
        defaultValue: 'mongodb://localhost:27017');
    return dd;
  }

  static String get dbName {
    final env = (dotenv.dotenv.isInitialized
        ? dotenv.dotenv.env['MONGODB_DB_NAME']
        : null);
    if (env != null && env.isNotEmpty) return env;
    const dd =
        String.fromEnvironment('MONGODB_DB_NAME', defaultValue: 'immolink');
    return dd;
  }

  static String get apiUrl {
    final env =
        (dotenv.dotenv.isInitialized ? dotenv.dotenv.env['API_URL'] : null);
    if (env != null && env.isNotEmpty) return env;
    const dd = String.fromEnvironment('API_URL',
        defaultValue: 'https://backend.immosync.ch/api');
    return dd;
  }

  static String get wsUrl {
    final env =
        (dotenv.dotenv.isInitialized ? dotenv.dotenv.env['WS_URL'] : null);
    if (env != null && env.isNotEmpty) return env;
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
  static String get primaryHost {
    final env = (dotenv.dotenv.isInitialized
        ? dotenv.dotenv.env['PRIMARY_HOST']
        : null);
    if (env != null && env.isNotEmpty) return env;
    const dd = String.fromEnvironment('PRIMARY_HOST',
        defaultValue: 'https://immosync.ch');
    return dd;
  }

  static void printConfig() {
    print('DbConfig loaded:');
    print('  connectionUri: $connectionUri');
    print('  dbName: $dbName');
    print('  apiUrl: $apiUrl');
    print('  wsUrl: $wsUrl');
    print('  primaryHost: $primaryHost');
    print('  (dart-define) API_URL: ${String.fromEnvironment('API_URL')}');

    // Verify services will use correct URL
    print('Services will use API URL: $apiUrl');
  }
}
