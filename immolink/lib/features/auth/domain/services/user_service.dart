import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immosync/core/config/db_config.dart';
import '../models/user.dart';

class UserService {
  final String _apiUrl = DbConfig.apiUrl;

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
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$_apiUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fullName': fullName,
          'email': email,
          'phone': phone,
          if (address != null) 'address': address,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromMap(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Profile update failed');
      }
    } catch (e) {
      print('UserService: Update profile error: $e');
      throw Exception('Failed to update profile');
    }
  }
}
