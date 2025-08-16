import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immolink/core/config/db_config.dart';

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

      return {
        'userId': user['userId'],
        'token': data['token'] ?? '', // Handle optional token
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
}

