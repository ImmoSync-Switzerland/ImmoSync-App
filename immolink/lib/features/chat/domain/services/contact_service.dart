import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immosync/core/config/db_config.dart';
import '../models/contact_user.dart';

class ContactService {
  final String _apiUrl = DbConfig.apiUrl;

  /// Get contacts for the current user based on their role
  /// Landlords get their tenants, tenants get their landlords
  Future<List<ContactUser>> getContactsForUser({
    required String userId,
    required String userRole,
  }) async {
    try {
      String endpoint;
      if (userRole == 'landlord') {
        // Get tenants for this landlord
        endpoint = '$_apiUrl/contacts/landlord/$userId/tenants';
      } else {
        // Get landlords for this tenant
        endpoint = '$_apiUrl/contacts/tenant/$userId/landlords';
      }

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
      );

      print('getContactsForUser response status: ${response.statusCode}');
      print('getContactsForUser response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ContactUser.fromMap(json)).toList();
      } else {
        print('Failed to load contacts: ${response.statusCode}');
        throw Exception('Failed to load contacts: ${response.statusCode}');
      }
    } catch (e) {
      print('Network error in getContactsForUser: $e');
      throw Exception('Network error: $e');
    }
  }
  /// Get all users (for admin or general contact list)
  Future<List<ContactUser>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/users'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ContactUser.fromMap(json)).toList();
      } else {
        print('Failed to load users: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Network error in getAllUsers: $e');
      return [];
    }
  }

  /// Get all tenants from the database
  Future<List<ContactUser>> getAllTenants() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/users/tenants'),
        headers: {'Content-Type': 'application/json'},
      );

      print('getAllTenants response status: ${response.statusCode}');
      print('getAllTenants response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> tenantsData = responseData['tenants'] ?? [];
        
        return tenantsData.map((json) {
          return ContactUser(
            id: json['_id'] ?? '',
            fullName: json['name'] ?? '',
            email: json['email'] ?? '',
            role: 'tenant',
            phone: json['phone'] ?? '',
            properties: json['propertyId'] != null && json['propertyId'].isNotEmpty 
                ? [json['propertyId']] 
                : [],
          );
        }).toList();
      } else {
        print('Failed to load tenants: ${response.statusCode}');
        throw Exception('Failed to load tenants: ${response.statusCode}');
      }
    } catch (e) {
      print('Network error in getAllTenants: $e');
      throw Exception('Network error: $e');
    }
  }
}
