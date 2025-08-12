import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immolink/features/auth/domain/models/user.dart';
import 'package:immolink/features/auth/domain/services/auth_service.dart';
import 'package:immolink/features/auth/presentation/providers/user_role_provider.dart';
import 'package:immolink/features/property/domain/models/property.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final String? userId;

  AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.error,
    this.userId,
  });

  factory AuthState.initial() {
    return AuthState(isAuthenticated: false, isLoading: false);
  }

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    String? userId,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userId: userId ?? this.userId,
    );
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class CurrentUserNotifier extends StateNotifier<User?> {
  CurrentUserNotifier() : super(null);

  Future<void> setUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    
    state = User(
      id: userId,
      email: prefs.getString('email') ?? '',
      role: prefs.getString('userRole') ?? '',
      fullName: prefs.getString('fullName') ?? '',
      birthDate: DateTime.now(),
      isAdmin: false,
      isValidated: true,
      address: Address(
        street: '',
        city: '',
        postalCode: '',
        country: ''
      )
    );
  }

  void clearUser() {
    state = null;
  }
}

final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, User?>((ref) {
  return CurrentUserNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final Ref ref;

  AuthNotifier(this._authService, this.ref) : super(AuthState.initial()) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId != null) {
      await ref.read(currentUserProvider.notifier).setUser(userId);
      state = state.copyWith(isAuthenticated: true, userId: userId);
    }
  }

  Future<void> login(String email, String password) async {
    print('AuthProvider: Starting login for $email');
    state = state.copyWith(isLoading: true, error: null);
    print('AuthProvider: State set to loading=true, error=null');

    try {
      print('AuthProvider: Calling auth service...');
      final userData = await _authService.loginUser(email: email, password: password);
      print('AuthProvider: Login successful, userData: $userData');

      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString('userId', userData['userId']),
        prefs.setString('authToken', userData['token']),
        prefs.setString('email', userData['email']),
        prefs.setString('userRole', userData['role']),
        prefs.setString('fullName', userData['fullName'])
      ]);

      ref.read(userRoleProvider.notifier).setUserRole(userData['role']);
      await ref.read(currentUserProvider.notifier).setUser(userData['userId']);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        userId: userData['userId']
      );
      print('AuthProvider: Login state updated - authenticated: true');
    } catch (e) {
      print('AuthProvider: Login failed with error: $e');
      final errorMessage = e.toString();
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
        isAuthenticated: false
      );
      print('AuthProvider: Error state set - error: $errorMessage, loading: false, authenticated: false');
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      ref.read(currentUserProvider.notifier).clearUser();
      state = AuthState.initial();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthNotifier(authService, ref);
});
