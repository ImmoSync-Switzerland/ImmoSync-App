import '../config/db_config.dart';

class ApiConstants {
  static String get baseUrl => DbConfig.apiUrl;

  // Endpoints
  static const String properties = '/properties';
  static const String users = '/users';
  static const String conversations = '/conversations';
  static const String invitations = '/invitations';
  static const String chat = '/chat';
  static const String auth = '/auth';
}
