import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/auth/domain/services/auth_service.dart';
import 'package:immosync/features/auth/presentation/providers/register_provider.dart';

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

  LoginNotifier(this._authService) : super(LoginState());

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
        userData: userData['user'],
      );
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
  (ref) => LoginNotifier(ref.read(authServiceProvider)),
);
