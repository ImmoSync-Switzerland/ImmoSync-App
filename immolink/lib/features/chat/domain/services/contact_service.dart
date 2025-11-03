import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immosync/core/config/db_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:crypto/crypto.dart';
import '../models/contact_user.dart';

class ContactService {
  final String _apiUrl = DbConfig.apiUrl;

  String? _buildUiJwt(String userId) {
    try {
      final secret = dotenv.dotenv.isInitialized
          ? (dotenv.dotenv.env['JWT_SECRET'] ?? '')
          : '';
      if (secret.isEmpty) return null;
      final header = {'alg': 'HS256', 'typ': 'JWT'};
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final payload = {'sub': userId, 'iat': now, 'exp': now + 300};
      String b64Url(Map obj) {
        final jsonStr = json.encode(obj);
        final b64 = base64Url.encode(utf8.encode(jsonStr));
        return b64.replaceAll('=', '');
      }
      final h = b64Url(header);
      final p = b64Url(payload);
      final data = utf8.encode('$h.$p');
      final key = utf8.encode(secret);
      final sig = Hmac(sha256, key).convert(data);
      final s = base64Url.encode(sig.bytes).replaceAll('=', '');
      return '$h.$p.$s';
    } catch (_) {
      return null;
    }
  }

  Future<void> _tryLoginExchangeWithUiJwt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null || userId.isEmpty) return;
      final assertion = _buildUiJwt(userId);
      if (assertion == null) return;
      final ex = await http.post(
        Uri.parse('$_apiUrl/auth/login-exchange'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $assertion',
        },
      );
      if (ex.statusCode == 200) {
        final data = json.decode(ex.body) as Map<String, dynamic>;
        final newToken = data['token'] as String?;
        if (newToken != null && newToken.isNotEmpty) {
          await SharedPreferences.getInstance()
              .then((p) => p.setString('sessionToken', newToken));
          final prefix = newToken.substring(0, newToken.length < 8 ? newToken.length : 8);
          print('AUTH DEBUG [ContactService]: obtained token; prefix=$prefix');
        }
      } else {
        print('AUTH DEBUG [ContactService]: UI-JWT exchange failed ${ex.statusCode} ${ex.body}');
      }
    } catch (e) {
      print('AUTH DEBUG [ContactService]: UI-JWT exchange error: $e');
    }
  }

  Future<Map<String, String>> _headers() async {
    final base = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('sessionToken');
      if (token != null && token.isNotEmpty) {
        base['Authorization'] = 'Bearer $token';
        base['x-access-token'] = token;
      }
    } catch (_) {}
    return base;
  }

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

      var response = await http.get(
        Uri.parse(endpoint),
        headers: await _headers(),
      );
      if (response.statusCode == 401) {
        await _tryLoginExchangeWithUiJwt();
        response = await http.get(
          Uri.parse(endpoint),
          headers: await _headers(),
        );
      }

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
      var response = await http.get(
        Uri.parse('$_apiUrl/users'),
        headers: await _headers(),
      );
      if (response.statusCode == 401) {
        await _tryLoginExchangeWithUiJwt();
        response = await http.get(
          Uri.parse('$_apiUrl/users'),
          headers: await _headers(),
        );
      }

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
      var response = await http.get(
        Uri.parse('$_apiUrl/users/tenants'),
        headers: await _headers(),
      );
      if (response.statusCode == 401) {
        await _tryLoginExchangeWithUiJwt();
        response = await http.get(
          Uri.parse('$_apiUrl/users/tenants'),
          headers: await _headers(),
        );
      }

      print('getAllTenants response status: ${response.statusCode}');
      print('getAllTenants response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> tenantsData = responseData['tenants'] ?? [];

        return tenantsData.map((json) {
          final String? canonicalUrl = json['profileImageUrl']?.toString();
          final String? legacyRef = json['profileImage']?.toString();
          return ContactUser(
            id: json['_id']?.toString() ?? '',
            fullName: (json['fullName'] ?? json['name'] ?? '').toString(),
            email: (json['email'] ?? '').toString(),
            role: 'tenant',
            phone: (json['phone'] ?? '').toString(),
            properties: json['propertyId'] != null &&
                    json['propertyId'].toString().isNotEmpty
                ? [json['propertyId'].toString()]
                : [],
            profileImageUrl: canonicalUrl,
            profileImage: canonicalUrl ?? legacyRef,
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
