import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immosync/core/config/db_config.dart';

class AuthService {
  final String _apiUrl = DbConfig.apiUrl;

  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    required String phone,
    required bool isCompany,
    String? companyName,
    String? companyAddress,
    String? taxId,
    String? address,
    DateTime? birthDate,
  }) async {
    final Map<String, dynamic> requestBody = {
      'email': email,
      'password': password,
      'fullName': fullName,
      'role': role,
      'phone': phone,
      'isCompany': isCompany,
    };

    if (isCompany) {
      requestBody['companyName'] = companyName;
      requestBody['companyAddress'] = companyAddress;
      requestBody['taxId'] = taxId;
    } else {
      requestBody['address'] = address;
      requestBody['birthDate'] = birthDate?.toIso8601String();
    }

    final response = await http.post(
      Uri.parse('$_apiUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody),
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
    print('AuthService: Making login request to: $_apiUrl/auth/login');
    print('AuthService: Login email: $email');

    final response = await http.post(
      Uri.parse('$_apiUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    print('AuthService: Login response status: ${response.statusCode}');
    print('AuthService: Login response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final user = data['user'];
      // Normalize userId returned from backend (string or {"$oid": "..."})
      dynamic rawId = user['userId'];
      String userIdStr;
      if (rawId is String) {
        userIdStr = rawId;
      } else if (rawId is Map && rawId[r'$oid'] != null) {
        userIdStr = rawId[r'$oid'].toString();
      } else {
        userIdStr = rawId.toString();
      }
      // Debug: log keys to verify sessionToken presence
      try {
        // ignore: avoid_print
        print('AuthService: user keys=${(user as Map).keys}');
        // ignore: avoid_print
        print('AuthService: sessionToken raw=${user['sessionToken']}');
      } catch (_) {}
      // Backend /auth/login returns { message, user: { userId, email, role, fullName, sessionToken } }
      return {
        'userId': userIdStr,
        'sessionToken': user['sessionToken'],
        'email': user['email'],
        'role': user['role'],
        'fullName': user['fullName']
      };
    }

    // Parse error message from response
    String errorMessage = 'Login failed';
    try {
      final errorData = json.decode(response.body);
      errorMessage = errorData['message'] ?? 'Login failed';
    } catch (e) {
      print('AuthService: Error parsing error response: $e');
      errorMessage = 'Login failed - Invalid response';
    }

    print('AuthService: Throwing exception: $errorMessage');
    throw Exception(errorMessage);
  }

  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$_apiUrl/auth/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Password change failed');
      }
    } catch (e) {
      print('AuthService: Change password error: $e');
      throw Exception('Failed to change password');
    }
  }

  Future<void> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Password reset request failed');
      }
    } catch (e) {
      print('AuthService: Forgot password error: $e');
      throw Exception('Failed to send password reset email');
    }
  }

  Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String idToken,
  }) async {
    final response = await http.post(
      Uri.parse('$_apiUrl/auth/social-login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'provider': provider, 'idToken': idToken}),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data; // contains success, needCompletion, missingFields or user
    }
    throw Exception(data['message'] ?? 'Social login failed');
  }

  Future<Map<String, dynamic>> completeSocialProfile({
    required String userId,
    String? fullName,
    String? role,
    String? phone,
    bool? isCompany,
    String? companyName,
    String? companyAddress,
    String? taxId,
    String? address,
    DateTime? birthDate,
  }) async {
    final body = <String, dynamic>{
      'userId': userId,
      if (fullName != null) 'fullName': fullName,
      if (role != null) 'role': role,
      if (phone != null) 'phone': phone,
      if (isCompany != null) 'isCompany': isCompany,
      if (companyName != null) 'companyName': companyName,
      if (companyAddress != null) 'companyAddress': companyAddress,
      if (taxId != null) 'taxId': taxId,
      if (address != null) 'address': address,
      if (birthDate != null) 'birthDate': birthDate.toIso8601String(),
    };

    final response = await http.post(
      Uri.parse('$_apiUrl/auth/social-complete'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data;
    }
    throw Exception(data['message'] ?? 'Profile completion failed');
  }
}
