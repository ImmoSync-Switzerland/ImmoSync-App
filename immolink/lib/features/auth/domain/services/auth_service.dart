import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immolink/core/config/db_config.dart';

class AuthService {
  final String _apiUrl = DbConfig.apiUrl;

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
}

