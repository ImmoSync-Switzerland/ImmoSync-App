import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'database_interface.dart';
import 'web_database_service.dart';
import 'mobile_database_service.dart';
import '../config/db_config.dart';

class DatabaseService {
  static final IDatabaseService _instance = _createInstance();

  static IDatabaseService _createInstance() {
    // Web and mobile platforms use the API proxy (WebDatabaseService)
    // Only desktop platforms (Windows/Linux/macOS) can use direct MongoDB connection
    if (kIsWeb || 
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return WebDatabaseService(apiBaseUrl: DbConfig.apiUrl);
    }
    // Desktop platforms can use direct MongoDB connection
    return MobileDatabaseService();
  }

  static IDatabaseService get instance => _instance;
}
