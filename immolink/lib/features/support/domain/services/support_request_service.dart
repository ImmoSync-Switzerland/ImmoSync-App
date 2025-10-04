import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/support_request.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final supportRequestServiceProvider = Provider((ref) => SupportRequestService(ref));

class SupportRequestService {
  final Ref ref;
  SupportRequestService(this.ref);
  static const _base = String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:3000/api');

  Future<List<SupportRequest>> list({String? status}) async {
    final uri = Uri.parse('$_base/support-requests${status != null ? '?status=$status' : ''}');
    final resp = await http.get(uri, headers: await _headers());
    if (resp.statusCode != 200) {
      throw Exception('Failed to load support requests');
    }
    final data = jsonDecode(resp.body);
    final list = (data['requests'] as List).map((e) => SupportRequest.fromJson(e)).toList();
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

  Future<String> create({required String subject, required String message, required String category, required String priority}) async {
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
    final resp = await http.put(uri, headers: await _headers(), body: jsonEncode({'note': note}));
    if (resp.statusCode != 200) {
      throw Exception('Failed to add note');
    }
  }

  Future<void> updateStatus(String id, String status) async {
    final uri = Uri.parse('$_base/support-requests/$id');
    final resp = await http.put(uri, headers: await _headers(), body: jsonEncode({'status': status}));
    if (resp.statusCode != 200) {
      throw Exception('Failed to update status');
    }
  }

  Future<Map<String, String>> _headers() async {
    final auth = ref.read(authProvider);
    final headers = {'Content-Type': 'application/json'};
    if (auth.sessionToken != null) {
      headers['Authorization'] = 'Bearer ${auth.sessionToken}';
    }
    return headers;
  }
}