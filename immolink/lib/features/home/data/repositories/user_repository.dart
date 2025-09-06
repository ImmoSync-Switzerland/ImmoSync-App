import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/database_service.dart';
import '../models/user_model.dart';

class UserRepository {
  static const String collectionName = 'users';
  final _db = DatabaseService.instance;

  Future<UserModel?> getUser(ObjectId id) async {
    final map = await _db.query(collectionName, where.id(id).map);
    return map != null ? UserModel.fromMap(map) : null;
  }

  Future<UserModel?> getCurrentUser() async {
    final userId = await _getCurrentUserId();
    if (userId == null) return null;

    return getUser(userId);
  }

  Future<ObjectId?> _getCurrentUserId() async {
    final storage = await SharedPreferences.getInstance();
    final userIdStr = storage.getString('userId');
    return userIdStr != null ? ObjectId.parse(userIdStr) : null;
  }
}
