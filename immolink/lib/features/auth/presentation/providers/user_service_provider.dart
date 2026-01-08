import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/auth/domain/models/user.dart';
import '../../../auth/domain/services/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

final userByIdProvider = FutureProvider.family<User?, String>((ref, userId) {
  final id = userId.trim();
  if (id.isEmpty) return Future.value(null);
  return ref.watch(userServiceProvider).fetchUserById(id);
});
