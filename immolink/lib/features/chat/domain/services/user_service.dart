import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class UserService {
  static String getCurrentUserId(Ref ref) {
    final currentUser = ref.read(currentUserProvider);
    return currentUser?.id ?? 'current-user-id';
  }

  static String? getCurrentUserIdOrNull(Ref ref) {
    final currentUser = ref.read(currentUserProvider);
    return currentUser?.id;
  }
}

final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});
