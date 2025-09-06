import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../models/property.dart';
import 'package:immosync/core/config/db_config.dart';
import '../../../chat/domain/services/chat_service.dart';

class PropertyService {
  final String _apiUrl = DbConfig.apiUrl;

  PropertyService() {
    print('PropertyService initialized with API URL: $_apiUrl');
  }

  Future<void> addProperty(Property property) async {
    final prefs = await SharedPreferences.getInstance();

    // Debug session state
    print('Session variables:');
    print('userId: ${prefs.getString('userId')}');
    print('authToken: ${prefs.getString('authToken')}');
    print('userRole: ${prefs.getString('userRole')}');
    print('email: ${prefs.getString('email')}');

    final userId = prefs.getString('userId') ??
        (throw Exception('User not authenticated'));

    final propertyData = {
      ...property.toMap(),
      'landlordId': userId,
    };

    print('Property data to send: ${json.encode(propertyData)}');

    // Continue with property creation...
    final response = await http.post(
      Uri.parse('$_apiUrl/properties'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(propertyData),
    );

    if (response.statusCode != 201) {
      print('Server response: ${response.body}');
      throw Exception('Failed to add property: ${response.statusCode}');
    }
  }

  Future<void> inviteTenant(String propertyId, String tenantId) async {
    final prefs = await SharedPreferences.getInstance();
    final landlordId = prefs.getString('userId');

    if (landlordId == null) {
      throw Exception('User not authenticated');
    }

    // Use the chat service to send invitation and create conversation
    final chatService = ChatService();

    try {
      await chatService.inviteTenant(
        propertyId: propertyId,
        landlordId: landlordId,
        tenantId: tenantId,
        message:
            'Hello! I would like to invite you to rent my property. Please let me know if you are interested.',
      );

      print(
          'Invitation sent successfully to tenant $tenantId for property $propertyId');
    } catch (e) {
      print('Error sending invitation: $e');
      throw Exception('Failed to send invitation: $e');
    }
  }

  Future<void> removeTenant(String propertyId, String tenantId) async {
    final prefs = await SharedPreferences.getInstance();
    final landlordId = prefs.getString('userId');

    if (landlordId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/properties/$propertyId/remove-tenant'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'tenantId': tenantId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to remove tenant: ${response.statusCode}');
      }

      print('Tenant $tenantId removed successfully from property $propertyId');
    } catch (e) {
      print('Error removing tenant: $e');
      throw Exception('Failed to remove tenant: $e');
    }
  }

  Stream<List<Property>> getLandlordProperties(String landlordId) async* {
    final idString =
        landlordId.toString().replaceAll('ObjectId("', '').replaceAll('")', '');

    final response = await http.get(
      Uri.parse('$_apiUrl/properties/landlord/$idString'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> properties = responseData['properties'];
      print('Found ${properties.length} properties');
      yield properties.map((json) => Property.fromMap(json)).toList();
    }
  }

  Stream<List<Property>> getTenantProperties(String tenantId) async* {
    final idString =
        tenantId.toString().replaceAll('ObjectId("', '').replaceAll('")', '');

    final response = await http.get(
      Uri.parse('$_apiUrl/properties/tenant/$idString'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> properties = responseData['properties'];
      print('Found ${properties.length} properties for tenant');
      yield properties.map((json) => Property.fromMap(json)).toList();
    }
  }

  Stream<List<Property>> getAllProperties() async* {
    final response = await http.get(
      Uri.parse('$_apiUrl/properties'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      yield data.map((json) => Property.fromMap(json)).toList();
    } else {
      throw Exception('Failed to load properties');
    }
  }

  Stream<Property> getPropertyById(String propertyId) async* {
    print('Fetching property with ID: $propertyId');

    final response = await http.get(
      Uri.parse('$_apiUrl/properties/$propertyId'),
      headers: {'Content-Type': 'application/json'},
    );

    print('API Response status: ${response.statusCode}');
    print('API Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      yield Property.fromMap(data);
    } else {
      throw Exception(
          'Failed to load property details: ${response.statusCode}');
    }
  }

  // Future-based method for tenant dashboard
  Future<List<Property>> getAllPropertiesFuture() async {
    final response = await http.get(
      Uri.parse('$_apiUrl/properties'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Property.fromMap(json)).toList();
    } else {
      throw Exception('Failed to load properties');
    }
  }

  Future<void> updateProperty(Property property) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ??
        (throw Exception('User not authenticated'));

    final propertyData = {
      ...property.toMap(),
      'landlordId': userId,
    };

    print('Updating property: ${property.id}');
    print('Property data to send: ${json.encode(propertyData)}');

    final response = await http.put(
      Uri.parse('$_apiUrl/properties/${property.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(propertyData),
    );

    if (response.statusCode != 200) {
      print('Server response: ${response.body}');
      throw Exception('Failed to update property: ${response.statusCode}');
    }
  }

  // Upload image to MongoDB and return the file ID
  Future<String?> uploadImage(PlatformFile file) async {
    try {
      print('Starting image upload for: ${file.name}');
      print('API URL: $_apiUrl');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_apiUrl/images/upload'),
      );
      if (file.bytes != null) {
        // For web platform
        print('Uploading image from bytes (web)');

        // Determine content type from file extension
        String? contentType;
        if (file.name.toLowerCase().endsWith('.png')) {
          contentType = 'image/png';
        } else if (file.name.toLowerCase().endsWith('.jpg') ||
            file.name.toLowerCase().endsWith('.jpeg')) {
          contentType = 'image/jpeg';
        } else if (file.name.toLowerCase().endsWith('.gif')) {
          contentType = 'image/gif';
        } else if (file.name.toLowerCase().endsWith('.webp')) {
          contentType = 'image/webp';
        } else if (file.name.toLowerCase().endsWith('.bmp')) {
          contentType = 'image/bmp';
        } else {
          contentType = 'image/png'; // Default fallback
        }

        print('Setting content type: $contentType');

        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            file.bytes!,
            filename: file.name,
            contentType: MediaType.parse(contentType),
          ),
        );
      } else if (file.path != null) {
        // For mobile platforms
        print('Uploading image from path (mobile): ${file.path}');
        request.files.add(
          await http.MultipartFile.fromPath('image', file.path!),
        );
      } else {
        throw Exception('File has no data');
      }

      print('Sending upload request to: $_apiUrl/images/upload');
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      print('Upload response status: ${response.statusCode}');
      print('Upload response data: $responseData');

      if (response.statusCode == 200) {
        final data = json.decode(responseData);
        final fileId = data['fileId'];
        print('Upload successful! File ID: $fileId');
        // Return the fileId, not the full URL - we'll construct the URL in the UI
        return fileId;
      } else {
        print('Image upload failed: ${response.statusCode} - $responseData');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Upload multiple images
  Future<List<String>> uploadImages(List<PlatformFile> files) async {
    final urls = <String>[];

    for (final file in files) {
      final url = await uploadImage(file);
      if (url != null) {
        urls.add(url);
      }
    }

    return urls;
  }
}
