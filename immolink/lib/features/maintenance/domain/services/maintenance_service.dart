import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immolink/features/maintenance/domain/models/maintenance_request.dart';
import 'package:immolink/core/config/db_config.dart';

class MaintenanceService {
  final String _apiUrl = DbConfig.apiUrl;

  // Get recent maintenance requests for dashboard (last 5)
  Future<List<MaintenanceRequest>> getRecentMaintenanceRequests(String landlordId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/maintenance/recent/$landlordId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => MaintenanceRequest.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load recent maintenance requests');
      }
    } catch (e) {
      print('Network error in getRecentMaintenanceRequests: $e');
      return []; // Return empty list when offline
    }
  }

  // Get all maintenance requests for a tenant
  Future<List<MaintenanceRequest>> getMaintenanceRequestsByTenant(String tenantId) async {
    try {
      final url = '$_apiUrl/maintenance/tenant/$tenantId';
      print('DEBUG: Fetching maintenance requests from: $url');
      print('DEBUG: Tenant ID: $tenantId');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

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
  Future<List<MaintenanceRequest>> getMaintenanceRequestsByLandlord(String landlordId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/maintenance/landlord/$landlordId'),
        headers: {'Content-Type': 'application/json'},
      );

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
  Future<MaintenanceRequest> createMaintenanceRequest(MaintenanceRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/maintenance'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(request.toMap()),
      );

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
  Future<MaintenanceRequest> updateMaintenanceRequestStatus(String id, String status, {String? notes, String? authorId}) async {
    try {
      final response = await http.patch(
        Uri.parse('$_apiUrl/maintenance/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'status': status,
          'notes': notes,
          'authorId': authorId,
        }),
      );

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
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

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
  Future<List<MaintenanceRequest>> getMaintenanceRequestsByProperty(String propertyId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/maintenance/property/$propertyId'),
        headers: {'Content-Type': 'application/json'},
      );

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
  Future<MaintenanceRequest> updateMaintenanceRequest(MaintenanceRequest request) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/maintenance/${request.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(request.toMap()),
      );

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
  Future<MaintenanceRequest> addNoteToMaintenanceRequest(String requestId, String content, String authorId) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/maintenance/$requestId/notes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'content': content,
          'authorId': authorId,
        }),
      );

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
