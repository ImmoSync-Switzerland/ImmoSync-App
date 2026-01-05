import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/auth/domain/models/user.dart';
import 'package:immosync/features/auth/domain/services/auth_service.dart';
import 'package:immosync/features/auth/presentation/providers/user_role_provider.dart';
import 'package:immosync/features/property/domain/models/property.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/crypto/e2ee_service.dart';
import '../../../../core/presence/presence_ws_service.dart';
import 'package:immosync/features/auth/domain/services/user_service.dart';
import '../../../../core/services/token_manager.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final String? userId;
  final String? sessionToken;
  final bool needsProfileCompletion;
  final List<String> missingFields;
  final String? pendingSocialUserId;

  AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.error,
    this.userId,
    this.sessionToken,
    this.needsProfileCompletion = false,
    this.missingFields = const [],
    this.pendingSocialUserId,
  });

  factory AuthState.initial() {
    return AuthState(isAuthenticated: false, isLoading: false);
  }

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    String? userId,
    String? sessionToken,
    bool? needsProfileCompletion,
    List<String>? missingFields,
    String? pendingSocialUserId,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userId: userId ?? this.userId,
      sessionToken: sessionToken ?? this.sessionToken,
      needsProfileCompletion:
          needsProfileCompletion ?? this.needsProfileCompletion,
      missingFields: missingFields ?? this.missingFields,
      pendingSocialUserId: pendingSocialUserId ?? this.pendingSocialUserId,
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
        address: Address(street: '', city: '', postalCode: '', country: ''),
        profileImageUrl: prefs.getString('immosync-profileImageUrl-$userId'),
        profileImage: prefs.getString('immosync-profileImage-$userId'));
  }

  void clearUser() {
    state = null;
  }

  void setPropertyId(String propertyId) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(propertyId: propertyId);
  }

  void setUserModel(User user) {
    state = user;
  }
}

final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, User?>((ref) {
  return CurrentUserNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final Ref ref;

  AuthNotifier(this._authService, this.ref) : super(AuthState.initial()) {
    _restoreSession();
  }

  // Allow other flows (e.g., legacy loginProvider) to inject a successful login result
  Future<void> applyExternalLogin(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        if (data['userId'] != null) prefs.setString('userId', data['userId']),
        if (data['sessionToken'] != null)
          prefs.setString('sessionToken', data['sessionToken']),
        if (data['email'] != null) prefs.setString('email', data['email']),
        if (data['role'] != null) prefs.setString('userRole', data['role']),
        if (data['fullName'] != null)
          prefs.setString('fullName', data['fullName']),
        if (data['profileImage'] != null)
          prefs.setString(
              'immosync-profileImage-${data['userId']}', data['profileImage']),
        if (data['profileImageUrl'] != null)
          prefs.setString('immosync-profileImageUrl-${data['userId']}',
              data['profileImageUrl']),
      ]);

      // CRITICAL: Update TokenManager cache with new session token
      if (data['sessionToken'] != null) {
        await TokenManager().setToken(data['sessionToken']);
        debugPrint(
            '[AuthProvider] TokenManager updated with new session token');
      }

      if (data['role'] != null) {
        ref.read(userRoleProvider.notifier).setUserRole(data['role']);
      }
      if (data['userId'] != null) {
        await ref.read(currentUserProvider.notifier).setUser(data['userId']);
        // Hydrate cached profile image if API hasn't provided it yet
        try {
          final cached =
              prefs.getString('immosync-profileImage-${data['userId']}');
          if (cached != null &&
              (ref.read(currentUserProvider)?.profileImage?.isEmpty ?? true)) {
            final current = ref.read(currentUserProvider);
            if (current != null) {
              ref.read(currentUserProvider.notifier).setUserModel(
                    current.copyWith(profileImage: cached),
                  );
            }
          }
        } catch (_) {}
      }
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        userId: data['userId'],
        sessionToken: data['sessionToken'],
        error: null,
      );
      // Fetch full user profile (includes profileImage)
      try {
        debugPrint('[AuthProvider] Fetching full user profile...');
        final us = UserService();
        final userModel = await us.fetchCurrentUser();
        debugPrint(
            '[AuthProvider] fetchCurrentUser returned: ${userModel != null ? "User(${userModel.id})" : "null"}');
        if (userModel != null) {
          debugPrint(
              '[AuthProvider] User profileImage: ${userModel.profileImage}');
          debugPrint(
              '[AuthProvider] User profileImageUrl: ${userModel.profileImageUrl}');
          ref.read(currentUserProvider.notifier).setUserModel(userModel);
          // Cache profile image for offline/early hydration
          if (userModel.profileImage != null &&
              userModel.profileImage!.isNotEmpty) {
            try {
              prefs.setString('immosync-profileImage-${userModel.id}',
                  userModel.profileImage!);
              debugPrint(
                  '[AuthProvider] Cached profileImage to SharedPreferences');
            } catch (_) {}
          }
        } else {
          debugPrint(
              '[AuthProvider] fetchCurrentUser returned null - user profile not updated');
        }
      } catch (e, st) {
        debugPrint('[AuthProvider] Error fetching user profile: $e');
        debugPrint('[AuthProvider] Stack trace: $st');
      }
      // Fire-and-forget identity key publish
      if (data['userId'] != null) {
        _publishIdentityKey(data['userId']);
      }
      // ignore: avoid_print
      print(
          'AuthProvider: applyExternalLogin sessionToken present? ${data['sessionToken'] != null}');
    } catch (e) {
      // ignore: avoid_print
      print('AuthProvider: applyExternalLogin error $e');
    }
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    // Handle corrupted userId (string "null" instead of actual null)
    if (userId == 'null' || userId?.isEmpty == true) {
      userId = null;
    }

    // Normalize legacy persisted userId that might be in Extended JSON like '{"$oid":"..."}'
    if (userId != null) {
      final match = RegExp(r'\{\s*"?\$oid"?\s*:\s*"([a-fA-F0-9]{24})"\s*\}')
          .firstMatch(userId);
      if (match != null) {
        final normalized = match.group(1);
        if (normalized != null) {
          userId = normalized;
          await prefs.setString('userId', normalized);
        }
      }
    }
    final sessionToken = prefs.getString('sessionToken');
    // Debug: log restore status (helps diagnose missing sessionToken causing WS not to auth)
    // ignore: avoid_print
    print(
        'AuthProvider:_restoreSession userId=$userId sessionTokenPresent=${sessionToken != null}');

    if (userId != null) {
      await ref.read(currentUserProvider.notifier).setUser(userId);
      // Early hydrate cached profile image if present
      try {
        final cached = prefs.getString('immosync-profileImage-$userId');
        if (cached != null) {
          final current = ref.read(currentUserProvider);
          if (current != null &&
              (current.profileImage == null || current.profileImage!.isEmpty)) {
            ref
                .read(currentUserProvider.notifier)
                .setUserModel(current.copyWith(profileImage: cached));
          }
        }
      } catch (_) {}
      state = state.copyWith(
          isAuthenticated: true, userId: userId, sessionToken: sessionToken);
      // Fetch full user to populate fields like profileImage
      try {
        final us = UserService();
        final userModel = await us.fetchCurrentUser();
        if (userModel != null) {
          ref.read(currentUserProvider.notifier).setUserModel(userModel);
          if (userModel.profileImage != null &&
              userModel.profileImage!.isNotEmpty) {
            try {
              prefs.setString('immosync-profileImage-${userModel.id}',
                  userModel.profileImage!);
            } catch (_) {}
          }
        }
      } catch (_) {}
    }
  }

  Future<void> login(String email, String password) async {
    print('AuthProvider: Starting login for $email');
    state = state.copyWith(isLoading: true, error: null);
    print('AuthProvider: State set to loading=true, error=null');

    try {
      print('AuthProvider: Calling auth service...');
      final userData =
          await _authService.loginUser(email: email, password: password);
      print('AuthProvider: Login successful, userData: $userData');

      // Validate userId before storing
      final userId = userData['userId'];
      if (userId == null || userId == 'null' || userId.toString().isEmpty) {
        throw Exception('Invalid userId received from login: $userId');
      }

      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString('userId', userId),
        if (userData['sessionToken'] != null)
          prefs.setString('sessionToken', userData['sessionToken']),
        prefs.setString('email', userData['email']),
        prefs.setString('userRole', userData['role']),
        prefs.setString('fullName', userData['fullName']),
        if (userData['profileImage'] != null)
          prefs.setString(
              'immosync-profileImage-$userId', userData['profileImage']),
        if (userData['profileImageUrl'] != null)
          prefs.setString(
              'immosync-profileImageUrl-$userId', userData['profileImageUrl']),
      ]);

      // CRITICAL: Update TokenManager cache with new session token
      if (userData['sessionToken'] != null) {
        await TokenManager().setToken(userData['sessionToken']);
        debugPrint('[AuthProvider] TokenManager updated in login()');
      }

      ref.read(userRoleProvider.notifier).setUserRole(userData['role']);
      await ref.read(currentUserProvider.notifier).setUser(userId);
      // Hydrate cached profile image early
      try {
        final cached = prefs.getString('immosync-profileImage-$userId');
        if (cached != null) {
          final current = ref.read(currentUserProvider);
          if (current != null &&
              (current.profileImage == null || current.profileImage!.isEmpty)) {
            ref
                .read(currentUserProvider.notifier)
                .setUserModel(current.copyWith(profileImage: cached));
          }
        }
      } catch (_) {}

      state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          userId: userId,
          sessionToken: userData['sessionToken']);
      // Fetch full user profile (includes profileImage) and update provider
      try {
        debugPrint('[AuthProvider.login] Fetching full user profile...');
        final us = UserService();
        final userModel = await us.fetchCurrentUser();
        debugPrint(
            '[AuthProvider.login] fetchCurrentUser returned: ${userModel != null ? "User(${userModel.id})" : "null"}');
        if (userModel != null) {
          debugPrint(
              '[AuthProvider.login] User profileImage: ${userModel.profileImage}');
          debugPrint(
              '[AuthProvider.login] User profileImageUrl: ${userModel.profileImageUrl}');
          ref.read(currentUserProvider.notifier).setUserModel(userModel);
          if (userModel.profileImage != null &&
              userModel.profileImage!.isNotEmpty) {
            try {
              prefs.setString('immosync-profileImage-${userModel.id}',
                  userModel.profileImage!);
              debugPrint(
                  '[AuthProvider.login] Cached profileImage to SharedPreferences');
            } catch (_) {}
          }
        } else {
          debugPrint('[AuthProvider.login] fetchCurrentUser returned null');
        }
      } catch (e, st) {
        debugPrint('[AuthProvider.login] Error fetching user profile: $e');
        debugPrint('[AuthProvider.login] Stack trace: $st');
      }
      // E2EE: publish identity key (fire and forget)
      _publishIdentityKey(userData['userId']);
      print('AuthProvider: Login state updated - authenticated: true');
      print(
          'AuthProvider: sessionToken present? ${userData['sessionToken'] != null}');
    } catch (e) {
      print('AuthProvider: Login failed with error: $e');
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
          isLoading: false, error: errorMessage, isAuthenticated: false);
      print(
          'AuthProvider: Error state set - error: $errorMessage, loading: false, authenticated: false');

      // Add a small delay to ensure the error state is processed
      await Future.delayed(const Duration(milliseconds: 100));
      print(
          'AuthProvider: Error state after delay - error: ${state.error}, loading: ${state.isLoading}');
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      // Proactively reset WebSocket connections to avoid stale identity usage.
      try {
        ref.read(presenceWsServiceProvider).resetConnections();
      } catch (_) {}

      // CRITICAL: Clear TokenManager cache before clearing SharedPreferences
      await TokenManager().clearToken();
      debugPrint('[AuthProvider] TokenManager cleared on logout');

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      // Ensure sessionToken removed (prefs.clear should handle but explicit for clarity)
      // ignore: unused_result
      prefs.remove('sessionToken');
      ref.read(currentUserProvider.notifier).clearUser();
      state = AuthState.initial();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> socialLogin(
      {required String provider, required String idToken}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      debugPrint(
          '[AuthProvider] socialLogin start provider=$provider tokenLen=${idToken.length}');
      final data =
          await _authService.socialLogin(provider: provider, idToken: idToken);
      if (data['needCompletion'] == true) {
        debugPrint(
            '[AuthProvider] socialLogin needs profile completion missingFields=${(data['missingFields'] as List?)?.length ?? 0}');
        state = state.copyWith(
          isLoading: false,
          needsProfileCompletion: true,
          missingFields: List<String>.from(data['missingFields'] ?? []),
          pendingSocialUserId: data['userId'],
        );
      } else {
        debugPrint('[AuthProvider] socialLogin success (authenticated)');
        final user = data['user'];
        final prefs = await SharedPreferences.getInstance();
        await Future.wait([
          prefs.setString('userId', user['userId']),
          if (user['sessionToken'] != null)
            prefs.setString('sessionToken', user['sessionToken']),
          prefs.setString('email', user['email'] ?? ''),
          if (user['role'] != null) prefs.setString('userRole', user['role']),
          if (user['fullName'] != null)
            prefs.setString('fullName', user['fullName']),
        ]);

        // CRITICAL: Update TokenManager cache with new session token
        if (user['sessionToken'] != null) {
          await TokenManager().setToken(user['sessionToken']);
          debugPrint('[AuthProvider] TokenManager updated in socialLogin');
        }

        if (user['role'] != null) {
          ref.read(userRoleProvider.notifier).setUserRole(user['role']);
        }
        await ref.read(currentUserProvider.notifier).setUser(user['userId']);
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          userId: user['userId'],
          sessionToken: user['sessionToken'],
          needsProfileCompletion: false,
          missingFields: [],
          pendingSocialUserId: null,
        );
        // Fetch full user profile (includes profileImage)
        try {
          final us = UserService();
          final userModel = await us.fetchCurrentUser();
          if (userModel != null) {
            ref.read(currentUserProvider.notifier).setUserModel(userModel);
          }
        } catch (_) {}
        _publishIdentityKey(user['userId']);
      }
    } catch (e) {
      debugPrint('[AuthProvider] socialLogin failed: $e');
      state = state.copyWith(
          isLoading: false,
          error: e.toString().replaceFirst('Exception: ', ''),
          needsProfileCompletion: false);
    }
  }

  Future<void> _publishIdentityKey(String userId) async {
    try {
      final e2ee = ref.read(e2eeServiceProvider);
      await e2ee.ensureInitialized();
      final result = await e2ee.publishIdentityKey(userId);
      if (result != null) {
        debugPrint(
            '[AuthProvider] Identity key published successfully for user $userId');
      } else {
        debugPrint(
            '[AuthProvider] Failed to publish identity key for user $userId');
      }
    } catch (e) {
      debugPrint('[AuthProvider] Error publishing identity key: $e');
    }
  }

  Future<void> completeSocialProfile({
    required Map<String, dynamic> fields,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userId = state.pendingSocialUserId;
      if (userId == null) throw Exception('No pending social user');
      final resp = await _authService.completeSocialProfile(
        userId: userId,
        fullName: fields['fullName'],
        role: fields['role'],
        phone: fields['phone'],
        isCompany: fields['isCompany'],
        companyName: fields['companyName'],
        companyAddress: fields['companyAddress'],
        taxId: fields['taxId'],
        address: fields['address'],
        birthDate: fields['birthDate'],
      );
      final user = resp['user'];
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString('userId', user['userId']),
        if (user['sessionToken'] != null)
          prefs.setString('sessionToken', user['sessionToken']),
        prefs.setString('email', user['email'] ?? ''),
        if (user['role'] != null) prefs.setString('userRole', user['role']),
        if (user['fullName'] != null)
          prefs.setString('fullName', user['fullName']),
      ]);

      // CRITICAL: Update TokenManager cache with new session token
      if (user['sessionToken'] != null) {
        await TokenManager().setToken(user['sessionToken']);
        debugPrint(
            '[AuthProvider] TokenManager updated in completeSocialProfile');
      }

      if (user['role'] != null) {
        ref.read(userRoleProvider.notifier).setUserRole(user['role']);
      }
      await ref.read(currentUserProvider.notifier).setUser(user['userId']);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        userId: user['userId'],
        sessionToken: user['sessionToken'],
        needsProfileCompletion: false,
        missingFields: [],
        pendingSocialUserId: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthNotifier(authService, ref);
});
