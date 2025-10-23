import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/support_request.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/db_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

final supportRequestServiceProvider =
    Provider((ref) => SupportRequestService(ref));

class SupportRequestService {
  final Ref ref;
  SupportRequestService(this.ref);
  
  String get _base => DbConfig.apiUrl;

  Future<List<SupportRequest>> list({String? status}) async {
    // Get userId from SharedPreferences to add to query
    String? userId;
    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId');
    } catch (e) {
      print('[SupportRequestService] Failed to get userId from prefs: $e');
    }
    
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (userId != null && userId.isNotEmpty) queryParams['userId'] = userId;
    
    final uri = Uri.parse('$_base/support-requests').replace(queryParameters: queryParams);
    print('[SupportRequestService] Fetching from: $uri');
    final resp = await http.get(uri, headers: await _headers());
    print('[SupportRequestService] Response status: ${resp.statusCode}');
    print('[SupportRequestService] Response body: ${resp.body}');
    if (resp.statusCode != 200) {
      throw Exception('Failed to load support requests (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    final list = (data['requests'] as List)
        .map((e) => SupportRequest.fromJson(e))
        .toList();
    return list;
  }

  Future<SupportRequest> fetch(String id) async {
    final uri = Uri.parse('$_base/support-requests/$id');
    final resp = await http.get(uri, headers: await _headers());
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch support request');
    }
    final data = jsonDecode(resp.body);
    return SupportRequest.fromJson(data['request']);
  }

  Future<String> create(
      {required String subject,
      required String message,
      required String category,
      required String priority}) async {
    final uri = Uri.parse('$_base/support-requests');
    final body = jsonEncode({
      'subject': subject,
      'message': message,
      'category': category,
      'priority': priority,
    });
    final resp = await http.post(uri, headers: await _headers(), body: body);
    if (resp.statusCode != 200) {
      throw Exception('Failed to create support request');
    }
    final data = jsonDecode(resp.body);
    return data['id'];
  }

  Future<void> addNote(String id, String note) async {
    final uri = Uri.parse('$_base/support-requests/$id');
    final resp = await http.put(uri,
        headers: await _headers(), body: jsonEncode({'note': note}));
    if (resp.statusCode != 200) {
      throw Exception('Failed to add note');
    }
  }

  Future<void> updateStatus(String id, String status) async {
    final uri = Uri.parse('$_base/support-requests/$id');
    final resp = await http.put(uri,
        headers: await _headers(), body: jsonEncode({'status': status}));
    if (resp.statusCode != 200) {
      throw Exception('Failed to update status');
    }
  }

  Future<Map<String, String>> _headers() async {
    final headers = {'Content-Type': 'application/json'};
    
    // Get token directly from SharedPreferences like user_service does
    String? token;
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('sessionToken');
      print('[SupportRequestService] Raw token from prefs: $token');
    } catch (e) {
      print('[SupportRequestService] Failed to get token from prefs: $e');
    }
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print('[SupportRequestService] Sending Authorization: Bearer ${token.substring(0, 20)}...');
    } else {
      print('[SupportRequestService] WARNING: No auth token in SharedPreferences');
    }
    
    return headers;
  }
}
