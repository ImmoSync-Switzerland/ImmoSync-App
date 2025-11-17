import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immosync/core/config/db_config.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:immosync/core/services/token_manager.dart';

class UserService {
  final String _apiUrl = DbConfig.apiUrl;
  final TokenManager _tokenManager = TokenManager();

  Stream<List<User>> getAvailableTenants({String? propertyId}) async* {
    print('Fetching available tenants for property: $propertyId');

    String url = '$_apiUrl/users/available-tenants';
    if (propertyId != null) {
      url += '?propertyId=$propertyId';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final tenants = data.map((json) => User.fromMap(json)).toList();
      print('Found ${tenants.length} available tenants');
      yield tenants;
    }
  }

  Future<User> updateProfile({
    required String userId,
    required String fullName,
    required String email,
    required String phone,
    String? address,
    String? profileImage,
  }) async {
    try {
      // Include session token if available for backend-side identification
      final headers = <String, String>{'Content-Type': 'application/json'};

      // Read token from SharedPreferences
      String? token;
      try {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('sessionToken');
      } catch (e) {
        print('[UserService] Failed to get token from SharedPreferences: $e');
      }

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] =
            'Bearer $token'; // Backend expects Bearer prefix
        print('[UserService] Authorization header set with token');
      } else {
        print('[UserService] No token available for update profile request');
      }

      print('[UserService] Updating profile for user $userId');
      print('[UserService] Request URL: $_apiUrl/users/$userId');

      final response = await http.patch(
        Uri.parse('$_apiUrl/users/$userId'),
        headers: headers,
        body: json.encode({
          'fullName': fullName,
          'email': email,
          'phone': phone,
          if (address != null) 'address': address,
          if (profileImage != null) 'profileImage': profileImage,
        }),
      );

      print('[UserService] Response status: ${response.statusCode}');
      print('[UserService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromMap(data);
      } else {
        final error = json.decode(response.body);
        final errorMessage = error['message'] ?? 'Profile update failed';
        print('[UserService] Error from backend: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[UserService] Update profile error: $e');
      rethrow; // Re-throw to preserve error message
    }
  }

  Future<User?> fetchCurrentUser() async {
    try {
      // Use JWT token instead of session token
      final headers = await _tokenManager.getHeaders();
      headers['Content-Type'] = 'application/json';

      print('[UserService] Fetching current user from $_apiUrl/users/me');
      final resp =
          await http.get(Uri.parse('$_apiUrl/users/me'), headers: headers);
      print('[UserService] Response status: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        print('[UserService] User data keys: ${data.keys.toList()}');
        print(
            '[UserService] profileImageUrl in response: ${data['profileImageUrl']}');
        print(
            '[UserService] profileImage in response: ${data['profileImage']}');

        final user = User.fromMap(data);
        print(
            '[UserService] User.fromMap - profileImageUrl: ${user.profileImageUrl}');
        print(
            '[UserService] User.fromMap - profileImage: ${user.profileImage}');
        return user;
      }
      print('[UserService] Failed to fetch user: ${resp.body}');
      return null;
    } catch (e, stackTrace) {
      print('[UserService] Error fetching current user: $e');
      print('[UserService] Stack trace: $stackTrace');
      return null;
    }
  }

  Future<User?> fetchUserById(String userId) async {
    try {
      final headers = await _tokenManager.getHeaders();
      headers['Content-Type'] = 'application/json';

      final resp = await http.get(Uri.parse('$_apiUrl/users/by-id/$userId'),
          headers: headers);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        return User.fromMap(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
