import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;
import 'database_interface.dart';
import 'web_database_service.dart';
import 'mobile_database_service.dart';
import '../config/db_config.dart';

class DatabaseService {
  static final IDatabaseService _instance = _createInstance();

  static IDatabaseService _createInstance() {
    // Force HTTP DB via env flag on any platform
    if (DbConfig.forceHttpDb) {
      debugPrint(
          '[DatabaseService] Using WebDatabaseService (forced by DB_FORCE_HTTP)');
      return WebDatabaseService(apiBaseUrl: DbConfig.apiUrl);
    }

    // Web and mobile platforms use the API proxy (WebDatabaseService)
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint(
          '[DatabaseService] Using WebDatabaseService (web/mobile platform)');
      return WebDatabaseService(apiBaseUrl: DbConfig.apiUrl);
    }

    // Desktop platforms: use direct MongoDB only if a URI is provided via env; otherwise use HTTP
    if (DbConfig.hasMongoEnv) {
      debugPrint(
          '[DatabaseService] Using MobileDatabaseService (desktop with Mongo env)');
      return MobileDatabaseService();
    }
    debugPrint(
        '[DatabaseService] Using WebDatabaseService (desktop without Mongo env)');
    return WebDatabaseService(apiBaseUrl: DbConfig.apiUrl);
  }

  static IDatabaseService get instance => _instance;
}
