import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/service.dart';
import '../../../../core/config/db_config.dart';

class ServiceService {
  final String _baseUrl = DbConfig.apiUrl;

  ServiceService() {
    print('ServiceService initialized with base URL: $_baseUrl');
  }

  // Get all services with optional filters
  Future<List<Service>> getServices({
    String? category,
    String? availability,
    String? landlordId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (category != null) queryParams['category'] = category;
      if (availability != null) queryParams['availability'] = availability;
      if (landlordId != null) queryParams['landlordId'] = landlordId;

      final uri =
          Uri.parse('$_baseUrl/services').replace(queryParameters: queryParams);

      print('ServiceService: Fetching services from $uri');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('ServiceService: Response status: ${response.statusCode}');
      print('ServiceService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> servicesData = data['value'] ?? [];
        return servicesData.map((json) => Service.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load services: ${response.statusCode}');
      }
    } catch (e) {
      print('ServiceService: Error fetching services: $e');
      throw Exception('Network error: $e');
    }
  }

  // Get services for a specific landlord
  Future<List<Service>> getServicesForLandlord(String landlordId) async {
    return getServices(landlordId: landlordId);
  }

  // Get services available to a tenant (for a specific landlord)
  Future<List<Service>> getServicesForTenant(String landlordId) async {
    print(
        'ServiceService: getServicesForTenant called with landlordId: $landlordId');
    final result = await getServices(
      landlordId: landlordId,
      availability: 'available',
    );
    print(
        'ServiceService: getServicesForTenant returning ${result.length} services');
    return result;
  }

  // Create a new service
  Future<Service> createService(Service service) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/services'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': service.name,
          'description': service.description,
          'category': service.category,
          'availability': service.availability,
          'landlordId': service.landlordId,
          'price': service.price,
          'contactInfo': service.contactInfo,
        }),
      );

      print('ServiceService: Create response status: ${response.statusCode}');
      print('ServiceService: Create response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Service.fromMap(data['service']);
      } else {
        throw Exception('Failed to create service: ${response.statusCode}');
      }
    } catch (e) {
      print('ServiceService: Error creating service: $e');
      throw Exception('Network error: $e');
    }
  }

  // Update an existing service
  Future<Service> updateService(Service service) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/services/${service.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': service.name,
          'description': service.description,
          'category': service.category,
          'availability': service.availability,
          'price': service.price,
          'contactInfo': service.contactInfo,
        }),
      );

      print('ServiceService: Update response status: ${response.statusCode}');
      print('ServiceService: Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Service.fromMap(data['service']);
      } else {
        throw Exception('Failed to update service: ${response.statusCode}');
      }
    } catch (e) {
      print('ServiceService: Error updating service: $e');
      throw Exception('Network error: $e');
    }
  }

  // Delete a service
  Future<void> deleteService(String serviceId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/services/$serviceId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('ServiceService: Delete response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete service: ${response.statusCode}');
      }
    } catch (e) {
      print('ServiceService: Error deleting service: $e');
      throw Exception('Network error: $e');
    }
  }
}
