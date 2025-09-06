import 'package:flutter/foundation.dart' show kIsWeb;
import 'database_interface.dart';
import 'web_database_service.dart';
import 'mobile_database_service.dart';
import '../config/db_config.dart';

class DatabaseService {
  static final IDatabaseService _instance = _createInstance();

  static IDatabaseService _createInstance() {
    if (kIsWeb) {
      return WebDatabaseService(apiBaseUrl: DbConfig.apiUrl);
    }
    return MobileDatabaseService();
  }

  static IDatabaseService get instance => _instance;
}
