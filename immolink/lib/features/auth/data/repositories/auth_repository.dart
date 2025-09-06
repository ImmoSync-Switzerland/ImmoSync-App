import 'package:shared_preferences/shared_preferences.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../../../../core/services/database_service.dart';

class AuthRepository {
  static const String _userIdKey = 'user_id';
  final _db = DatabaseService.instance;
  final _prefs = SharedPreferences.getInstance();

  Future<ObjectId?> getCurrentUserId() async {
    final prefs = await _prefs;
    final storedId = prefs.getString(_userIdKey);
    return storedId != null ? ObjectId.fromHexString(storedId) : null;
  }

  Future<bool> login(String email, String password) async {
    try {
      final result = await _db.query('users', {
        'email': email,
        'password': password // In production, use hashed passwords
      });

      if (result != null) {
        final prefs = await _prefs;
        await prefs.setString(_userIdKey, result['_id'].toHexString());
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await _prefs;
    await prefs.remove(_userIdKey);
  }

  Future<bool> isLoggedIn() async {
    final userId = await getCurrentUserId();
    return userId != null;
  }
}
