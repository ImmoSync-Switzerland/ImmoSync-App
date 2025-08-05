import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immolink/core/config/db_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final String _apiUrl = DbConfig.apiUrl;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String fullName,
    required DateTime birthDate,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$_apiUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'fullName': fullName,
        'birthDate': birthDate.toIso8601String(),
        'role': role,
      }),
    );

    print('Registration response: ${response.body}');

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['message']);
    }
  }

  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_apiUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final user = data['user'];

      return {
        'userId': user['userId'],
        'token': data['token'] ?? '', // Handle optional token
        'email': user['email'],
        'role': user['role'],
        'fullName': user['fullName']
      };
    }

    throw Exception(json.decode(response.body)['message'] ?? 'Login failed');
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final User? user = userCredential.user;
      
      if (user == null) {
        throw Exception('Failed to authenticate with Firebase');
      }

      // Get Firebase ID token
      final String? idToken = await user.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get Firebase token');
      }

      // Send token to backend
      return await _verifyFirebaseToken(idToken, 'google');
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  Future<Map<String, dynamic>> signInWithApple() async {
    try {
      // Sign in with Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create Firebase credential
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);
      final User? user = userCredential.user;
      
      if (user == null) {
        throw Exception('Failed to authenticate with Firebase');
      }

      // Get Firebase ID token
      final String? idToken = await user.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get Firebase token');
      }

      // Send token to backend
      return await _verifyFirebaseToken(idToken, 'apple');
    } catch (e) {
      throw Exception('Apple sign in failed: $e');
    }
  }

  Future<Map<String, dynamic>> _verifyFirebaseToken(String idToken, String provider) async {
    final response = await http.post(
      Uri.parse('$_apiUrl/auth/social-login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'idToken': idToken,
        'provider': provider,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final user = data['user'];

      return {
        'userId': user['userId'],
        'token': data['token'] ?? '',
        'email': user['email'],
        'role': user['role'],
        'fullName': user['fullName']
      };
    }

    throw Exception(json.decode(response.body)['message'] ?? 'Social login failed');
  }
}

