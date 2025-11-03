import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immosync/features/maintenance/domain/models/maintenance_request.dart';
import 'package:immosync/core/config/db_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MaintenanceService {
  final String _apiUrl = DbConfig.apiUrl;

  // Create a short-lived UI JWT signed with backend secret for exchange flow
  String? _buildUiJwt(String userId) {
    try {
      final secret = dotenv.dotenv.isInitialized
          ? (dotenv.dotenv.env['JWT_SECRET'] ?? '')
          : '';
      if (secret.isEmpty) return null;
      final header = {
        'alg': 'HS256',
        'typ': 'JWT',
      };
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final payload = {
        'sub': userId,
        'iat': now,
        'exp': now + 300, // 5 minutes
      };
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
          await prefs.setString('sessionToken', newToken);
          final prefix = newToken.substring(0, newToken.length < 8 ? newToken.length : 8);
          print('AUTH DEBUG: obtained backend session token via UI-JWT exchange; prefix=$prefix');
        }
      } else {
        print('AUTH DEBUG: UI-JWT exchange failed status=${ex.statusCode} body=${ex.body}');
      }
    } catch (e) {
      print('AUTH DEBUG: UI-JWT exchange error: $e');
    }
  }

  Future<Map<String, String>> _headers() async {
    final base = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('sessionToken');
      if (token != null && token.isNotEmpty) {
        final looksJwt = token.contains('.') && token.split('.').length == 3;
        final prefix = token.substring(0, token.length < 8 ? token.length : 8);
        print('AUTH DEBUG: token present; looksJwt=$looksJwt len=${token.length} prefix=$prefix');
      } else {
        print('AUTH DEBUG: no token in SharedPreferences');
      }
      // If token looks like a UI JWT (has dots), exchange it for backend session token
      if (token != null && token.contains('.')) {
        try {
          final ex = await http.post(
            Uri.parse('$_apiUrl/auth/login-exchange'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
          if (ex.statusCode == 200) {
            final data = json.decode(ex.body) as Map<String, dynamic>;
            final newToken = data['token'] as String?;
            if (newToken != null && newToken.isNotEmpty) {
              await prefs.setString('sessionToken', newToken);
              token = newToken;
              final prefix = token.substring(0, token.length < 8 ? token.length : 8);
              print('AUTH DEBUG: exchanged JWT for backend session token; len=${token.length} prefix=$prefix');
            }
          } else {
            print('AUTH DEBUG: login-exchange failed status=${ex.statusCode} body=${ex.body}');
            // keep original token; backend may still accept it on tolerant endpoints
          }
        } catch (_) {}
      }
      if (token != null && token.isNotEmpty) {
        base['Authorization'] = 'Bearer $token';
        base['x-access-token'] = token;
        base['x-session-token'] = token;
      }
    } catch (_) {}
    return base;
  }

  // Get recent maintenance requests for dashboard (last 5)
  Future<List<MaintenanceRequest>> getRecentMaintenanceRequests(
      String landlordId) async {
    try {
      final url = '$_apiUrl/maintenance/recent/$landlordId';
      print('DEBUG: Fetching recent maintenance from: $url');
      var response = await http.get(
        Uri.parse(url),
        headers: await _headers(),
      );

      if (response.statusCode == 401) {
        // Attempt to obtain/refresh backend session token and retry once
        await _tryLoginExchangeWithUiJwt();
        response = await http.get(
          Uri.parse(url),
          headers: await _headers(),
        );
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('DEBUG: recent maintenance count=${data.length}');
        return data.map((json) => MaintenanceRequest.fromMap(json)).toList();
      } else {
        print('DEBUG: Failed recent requests with status: ${response.statusCode}');
        print('DEBUG: Body: ${response.body}');
        throw Exception('Failed to load recent maintenance requests');
      }
    } catch (e) {
      print('Network error in getRecentMaintenanceRequests: $e');
      return []; // Return empty list when offline
    }
  }

  // Get all maintenance requests for a tenant
  Future<List<MaintenanceRequest>> getMaintenanceRequestsByTenant(
      String tenantId) async {
    try {
      final url = '$_apiUrl/maintenance/tenant/$tenantId';
      print('DEBUG: Fetching maintenance requests from: $url');
      print('DEBUG: Tenant ID: $tenantId');

      var response = await http.get(
        Uri.parse(url),
        headers: await _headers(),
      );

      if (response.statusCode == 401) {
        await _tryLoginExchangeWithUiJwt();
        response = await http.get(
          Uri.parse(url),
          headers: await _headers(),
        );
      }

      print('DEBUG: Response status code: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('DEBUG: Found ${data.length} maintenance requests');
        return data.map((json) => MaintenanceRequest.fromMap(json)).toList();
      } else {
        print('DEBUG: Failed with status code: ${response.statusCode}');
        throw Exception('Failed to load maintenance requests');
      }
    } catch (e) {
      print('Network error in getMaintenanceRequestsByTenant: $e');
      return []; // Return empty list when offline
    }
  }

  // Get all maintenance requests for a landlord
  Future<List<MaintenanceRequest>> getMaintenanceRequestsByLandlord(
      String landlordId) async {
    try {
      var response = await http.get(
        Uri.parse('$_apiUrl/maintenance/landlord/$landlordId'),
        headers: await _headers(),
      );

      if (response.statusCode == 401) {
        await _tryLoginExchangeWithUiJwt();
        response = await http.get(
          Uri.parse('$_apiUrl/maintenance/landlord/$landlordId'),
          headers: await _headers(),
        );
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => MaintenanceRequest.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load maintenance requests');
      }
    } catch (e) {
      print('Network error in getMaintenanceRequestsByLandlord: $e');
      return []; // Return empty list when offline
    }
  }

  // Create a new maintenance request
  Future<MaintenanceRequest> createMaintenanceRequest(
      MaintenanceRequest request) async {
    try {
      var response = await http.post(
        Uri.parse('$_apiUrl/maintenance'),
        headers: await _headers(),
        body: json.encode(request.toMap()),
      );

      if (response.statusCode == 401) {
        print('AUTH DEBUG [MaintenanceService]: create received 401, attempting login-exchange and retry');
        await _tryLoginExchangeWithUiJwt();
        response = await http.post(
          Uri.parse('$_apiUrl/maintenance'),
          headers: await _headers(),
          body: json.encode(request.toMap()),
        );
      }

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        // Handle the backend response format which wraps the ticket data
        final ticketData = data['ticket'] ?? data;
        return MaintenanceRequest.fromMap(ticketData);
      } else {
        throw Exception('Failed to create maintenance request');
      }
    } catch (e) {
      print('Network error in createMaintenanceRequest: $e');
      rethrow;
    }
  }

  // Update maintenance request status
  Future<MaintenanceRequest> updateMaintenanceRequestStatus(
      String id, String status,
      {String? notes, String? authorId}) async {
    try {
      var response = await http.patch(
        Uri.parse('$_apiUrl/maintenance/$id/status'),
        headers: await _headers(),
        body: json.encode({
          'status': status,
          'notes': notes,
          'authorId': authorId,
        }),
      );

      if (response.statusCode == 401) {
        await _tryLoginExchangeWithUiJwt();
        response = await http.patch(
          Uri.parse('$_apiUrl/maintenance/$id/status'),
          headers: await _headers(),
          body: json.encode({
            'status': status,
            'notes': notes,
            'authorId': authorId,
          }),
        );
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MaintenanceRequest.fromMap(data);
      } else {
        throw Exception('Failed to update maintenance request');
      }
    } catch (e) {
      print('Network error in updateMaintenanceRequestStatus: $e');
      rethrow;
    }
  }

  // Get a specific maintenance request
  Future<MaintenanceRequest> getMaintenanceRequestById(String id) async {
    try {
      final url = '$_apiUrl/maintenance/$id';
      print('DEBUG: Fetching maintenance request by ID from: $url');
      print('DEBUG: Request ID: $id');

      var response = await http.get(
        Uri.parse(url),
        headers: await _headers(),
      );

      if (response.statusCode == 401) {
        await _tryLoginExchangeWithUiJwt();
        response = await http.get(
          Uri.parse(url),
          headers: await _headers(),
        );
      }

      print('DEBUG: Response status code: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MaintenanceRequest.fromMap(data);
      } else {
        print('DEBUG: Failed with status code: ${response.statusCode}');
        throw Exception('Failed to load maintenance request');
      }
    } catch (e) {
      print('Network error in getMaintenanceRequestById: $e');
      rethrow;
    }
  }

  // Get maintenance requests by property
  Future<List<MaintenanceRequest>> getMaintenanceRequestsByProperty(
      String propertyId) async {
    try {
      var response = await http.get(
        Uri.parse('$_apiUrl/maintenance/property/$propertyId'),
        headers: await _headers(),
      );

      if (response.statusCode == 401) {
        await _tryLoginExchangeWithUiJwt();
        response = await http.get(
          Uri.parse('$_apiUrl/maintenance/property/$propertyId'),
          headers: await _headers(),
        );
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => MaintenanceRequest.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load maintenance requests');
      }
    } catch (e) {
      print('Network error in getMaintenanceRequestsByProperty: $e');
      return []; // Return empty list when offline
    }
  }

  // Update maintenance request (full update)
  Future<MaintenanceRequest> updateMaintenanceRequest(
      MaintenanceRequest request) async {
    try {
      var response = await http.put(
        Uri.parse('$_apiUrl/maintenance/${request.id}'),
        headers: await _headers(),
        body: json.encode(request.toMap()),
      );

      if (response.statusCode == 401) {
        await _tryLoginExchangeWithUiJwt();
        response = await http.put(
          Uri.parse('$_apiUrl/maintenance/${request.id}'),
          headers: await _headers(),
          body: json.encode(request.toMap()),
        );
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MaintenanceRequest.fromMap(data);
      } else {
        throw Exception('Failed to update maintenance request');
      }
    } catch (e) {
      print('Network error in updateMaintenanceRequest: $e');
      rethrow;
    }
  }

  // Add a note to maintenance request
  Future<MaintenanceRequest> addNoteToMaintenanceRequest(
      String requestId, String content, String authorId) async {
    try {
      var response = await http.post(
        Uri.parse('$_apiUrl/maintenance/$requestId/notes'),
        headers: await _headers(),
        body: json.encode({
          'content': content,
          'authorId': authorId,
        }),
      );

      if (response.statusCode == 401) {
        await _tryLoginExchangeWithUiJwt();
        response = await http.post(
          Uri.parse('$_apiUrl/maintenance/$requestId/notes'),
          headers: await _headers(),
          body: json.encode({
            'content': content,
            'authorId': authorId,
          }),
        );
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MaintenanceRequest.fromMap(data);
      } else {
        throw Exception('Failed to add note to maintenance request');
      }
    } catch (e) {
      print('Network error in addNoteToMaintenanceRequest: $e');
      rethrow;
    }
  }
}
