import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/auth/domain/services/auth_service.dart';
import 'auth_provider.dart';

class LoginState {
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final Map<String, dynamic>? userData;

  LoginState({
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.userData,
  });

  LoginState copyWith({
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    Map<String, dynamic>? userData,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userData: userData ?? this.userData,
    );
  }
}

class LoginNotifier extends StateNotifier<LoginState> {
  final AuthService _authService;
  final Ref _ref;

  LoginNotifier(this._authService, this._ref) : super(LoginState());

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userData = await _authService.loginUser(
        email: email,
        password: password,
      );

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        userData: userData,
      );
      // ignore: avoid_print
      print(
          'LoginProvider: received sessionToken? ${userData['sessionToken'] != null}');
      // ignore: avoid_print
      print('LoginProvider: raw userData map = $userData');
      // Sync into primary auth provider so rest of app (including WS) gets token
      if (userData['sessionToken'] != null) {
        try {
          Future.microtask(() =>
              _ref.read(authProvider.notifier).applyExternalLogin(userData));
        } catch (_) {}
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isAuthenticated: false,
      );
    }
  }
}

final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>(
  (ref) => LoginNotifier(ref.read(authServiceProvider), ref),
);
