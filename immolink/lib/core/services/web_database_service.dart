import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database_interface.dart';
import 'database_exception.dart';

class WebDatabaseService implements IDatabaseService {
  final String apiBaseUrl;
  
  WebDatabaseService({required this.apiBaseUrl});

  @override
  Future<void> connect() async {
    try {
      print('Connecting to API at: $apiBaseUrl');
      
      final response = await http.get(
        Uri.parse('$apiBaseUrl/health'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
      );
      
      print('Health check response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    
      if (response.statusCode != 200) {
        throw DatabaseException(
          'API connection failed: Status ${response.statusCode}\n'
          'Response: ${response.body}'
        );
      }
    } on http.ClientException catch (e) {
      print('Network error details: $e');
      throw DatabaseException('Network connection failed: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
      throw DatabaseException('Connection failed: $e');
    }
  }

  @override
  Future<void> disconnect() async => null;

  @override
  Future<dynamic> query(String collection, Map<String, dynamic> filter) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/$collection/query'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: json.encode(filter),
      );

      if (response.statusCode != 200) {
        throw DatabaseException(
          'Query failed: Status ${response.statusCode}\n'
          'Response: ${response.body}'
        );
      }

      return json.decode(response.body);
    } catch (e) {
      throw DatabaseException('Query operation failed: $e');
    }
  }
  
  @override
  Future<dynamic> insert(String collection, Map<String, dynamic> document) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/$collection'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: json.encode(document),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw DatabaseException(
          'Insert failed: Status ${response.statusCode}\n'
          'Response: ${response.body}'
        );
      }

      return json.decode(response.body);
    } catch (e) {
      throw DatabaseException('Insert operation failed: $e');
    }
  }
  
  @override
  Future<dynamic> update(String collection, Map<String, dynamic> filter, Map<String, dynamic> update) async {
    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/$collection'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: json.encode({'filter': filter, 'update': update}),
      );

      if (response.statusCode != 200) {
        throw DatabaseException(
          'Update failed: Status ${response.statusCode}\n'
          'Response: ${response.body}'
        );
      }

      return json.decode(response.body);
    } catch (e) {
      throw DatabaseException('Update operation failed: $e');
    }
  }
  
  @override
  Future<dynamic> delete(String collection, Map<String, dynamic> filter) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/$collection'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: json.encode(filter),
      );

      if (response.statusCode != 200) {
        throw DatabaseException(
          'Delete failed: Status ${response.statusCode}\n'
          'Response: ${response.body}'
        );
      }

      return json.decode(response.body);
    } catch (e) {
      throw DatabaseException('Delete operation failed: $e');
    }
  }
}
