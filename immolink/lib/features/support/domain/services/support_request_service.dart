import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../domain/models/support_request.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/db_config.dart';
import '../../../../core/services/token_manager.dart';

final supportRequestServiceProvider =
    Provider((ref) => SupportRequestService(ref));

class SupportRequestService {
  final Ref ref;
  final TokenManager _tokenManager = TokenManager();
  SupportRequestService(this.ref);

  String get _base => DbConfig.apiUrl;

  Future<Map<String, String>> _headers() async {
    return await _tokenManager.getHeaders();
  }

  Future<List<SupportRequest>> list({String? status}) async {
    // Backend infers user from Authorization; avoid passing userId from client
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse('$_base/support-requests')
        .replace(queryParameters: queryParams);
    debugPrint('[SupportRequestService] Fetching from: $uri');
    var resp = await http.get(uri, headers: await _headers());
    if (resp.statusCode == 401) {
      await _tokenManager.refreshToken(_base);
      resp = await http.get(uri, headers: await _headers());
    }
    debugPrint('[SupportRequestService] Response status: ${resp.statusCode}');
    debugPrint('[SupportRequestService] Response body: ${resp.body}');
    if (resp.statusCode != 200) {
      // Fallback to Next.js proxy
      try {
        final primary = DbConfig.primaryHost;
        final nx = Uri.parse('$primary/api/support-tickets')
            .replace(queryParameters: queryParams);
        debugPrint('[SupportRequestService] Fallback GET to Next.js: $nx');
        var nxResp = await http.get(nx, headers: await _headers());
        if (nxResp.statusCode == 401) {
          await _tokenManager.refreshToken(_base);
          nxResp = await http.get(nx, headers: await _headers());
        }
        debugPrint(
            '[SupportRequestService] Next fallback status: ${nxResp.statusCode}');
        if (nxResp.statusCode == 200) {
          resp = nxResp;
        } else {
          throw Exception(
              'Failed to load support requests (${resp.statusCode}): ${resp.body}');
        }
      } catch (e) {
        rethrow;
      }
    }
    final data = jsonDecode(resp.body);
    List<dynamic> raw;
    if (data is Map<String, dynamic>) {
      raw = (data['requests'] ??
              data['supportRequests'] ??
              data['tickets'] ??
              data['items'] ??
              data['data'] ??
              data['results'] ??
              data['docs']) as List? ??
          const [];
    } else if (data is List) {
      raw = data;
    } else {
      raw = const [];
    }
    final list = raw
        .map((e) => SupportRequest.fromJson(e as Map<String, dynamic>))
        .toList();
    debugPrint(
        '[SupportRequestService] Parsed ${list.length} support requests');
    return list;
  }

  Future<SupportRequest> fetch(String id) async {
    final uri = Uri.parse('$_base/support-requests/$id');
    var resp = await http.get(uri, headers: await _headers());
    if (resp.statusCode == 401) {
      await _tokenManager.refreshToken(_base);
      resp = await http.get(uri, headers: await _headers());
    }
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
      'title': subject,
      // Backends differ on which field they read; provide all
      'description': message,
      'details': message,
      'body': message,
      'category': category,
      'priority': priority,
    });
    var resp = await http.post(uri, headers: await _headers(), body: body);
    if (resp.statusCode == 401) {
      debugPrint(
          'AUTH DEBUG [SupportRequestService]: create received 401, attempting login-exchange and retry');
      await _tokenManager.refreshToken(_base);
      resp = await http.post(uri, headers: await _headers(), body: body);
    }
    debugPrint(
        '[SupportRequestService] Create response status: ${resp.statusCode}');
    debugPrint('[SupportRequestService] Create response body: ${resp.body}');
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      // Fallback: try Next.js proxy if available
      try {
        final primary = DbConfig.primaryHost;
        final nxUri = Uri.parse('$primary/api/support-tickets');
        debugPrint('[SupportRequestService] Fallback POST to Next.js: $nxUri');
        var nx = await http.post(nxUri, headers: await _headers(), body: body);
        if (nx.statusCode == 401) {
          await _tokenManager.refreshToken(_base);
          nx = await http.post(nxUri, headers: await _headers(), body: body);
        }
        debugPrint(
            '[SupportRequestService] Next fallback status: ${nx.statusCode}');
        debugPrint('[SupportRequestService] Next fallback body: ${nx.body}');
        if (nx.statusCode == 200 || nx.statusCode == 201) {
          resp = nx;
        } else {
          throw Exception(
              'Failed to create support request (${resp.statusCode}): ${resp.body}');
        }
      } catch (e) {
        rethrow;
      }
    }
    final data = jsonDecode(resp.body);
    final id = (data is Map<String, dynamic>)
        ? (data['id'] ??
            data['_id'] ??
            (data['request'] != null
                ? (data['request']['id'] ?? data['request']['_id'])
                : null))
        : null;
    if (id == null || (id is String && id.isEmpty)) {
      // Some backends return the whole created object; try to infer
      final inferred = (data is Map<String, dynamic>)
          ? (data['supportRequest'] ?? data['ticket'] ?? data)
          : null;
      final inferredId = (inferred is Map<String, dynamic>)
          ? (inferred['_id'] ?? inferred['id'])
          : null;
      if (inferredId != null) {
        return inferredId.toString();
      }
    }
    return id.toString();
  }

  Future<void> addNote(String id, String note) async {
    final uri = Uri.parse('$_base/support-requests/$id');
    var resp = await http.put(uri,
        headers: await _headers(), body: jsonEncode({'note': note}));
    if (resp.statusCode == 401) {
      await _tokenManager.refreshToken(_base);
      resp = await http.put(uri,
          headers: await _headers(), body: jsonEncode({'note': note}));
    }
    if (resp.statusCode != 200) {
      throw Exception('Failed to add note');
    }
  }

  Future<void> updateStatus(String id, String status) async {
    final uri = Uri.parse('$_base/support-requests/$id');
    var resp = await http.put(uri,
        headers: await _headers(), body: jsonEncode({'status': status}));
    if (resp.statusCode == 401) {
      await _tokenManager.refreshToken(_base);
      resp = await http.put(uri,
          headers: await _headers(), body: jsonEncode({'status': status}));
    }
    if (resp.statusCode != 200) {
      throw Exception('Failed to update status');
    }
  }
}
