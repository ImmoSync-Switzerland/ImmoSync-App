import '../config/db_config.dart';

/// Resolve a stored reference (ObjectId, legacy path, document raw path, full URL) to a fetchable URL.
/// Priority:
/// 1. Full URL -> return as-is
/// 2. /api/* absolute API path -> prepend host (strip duplicate /api)
/// 3. Document raw paths (/api/documents/:id/raw or documents/:id/raw) -> map to backend documents endpoint
/// 4. Legacy uploads paths -> map to base host + uploads path
/// 5. Pure 24-char hex -> treat as image id via /api/images/:id
/// 6. Fallback -> treat as image id
String resolvePropertyImage(String ref) {
  if (ref.isEmpty) return '';
  final api = DbConfig.apiUrl; // may end with /api
  final baseHost = api.endsWith('/api') ? api.substring(0, api.length - 4) : api; // backend host
  final publicHost = DbConfig.primaryHost; // https://immosync.ch

  // Full URL already
  if (ref.startsWith('http://') || ref.startsWith('https://')) return ref;

  // If stored with leading /api/... keep that path exactly once
  if (ref.startsWith('/api/')) {
    // Avoid duplicating /api if apiUrl already includes /api
  // Serve through API host for authenticated endpoints
  return baseHost + ref;
  }

  // Document raw endpoints (possible forms): 'documents/<id>/raw', '/documents/<id>/raw'
  if (ref.contains('/documents/') || ref.startsWith('documents/')) {
    String path = ref.startsWith('/') ? ref : '/$ref';
    // Ensure it has /api prefix once
    if (!path.startsWith('/api/')) {
      path = '/api' + path;
    }
  // Documents raw should use public host to avoid mixed host issues
  return publicHost + path;
  }

  // Legacy uploads path or file name inside uploads/documents or uploads/
  if (ref.contains('uploads/')) {
    // Normalize to starting at /uploads
    final idx = ref.indexOf('uploads/');
    final normalized = '/' + ref.substring(idx);
  return publicHost + normalized; // prefer public host
  }

  // Local file reference (not loadable remotely)
  if (ref.startsWith('file:')) return '';

  // Raw ObjectId for GridFS image
  final isHex24 = ref.length == 24 && RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(ref);
  if (isHex24) {
    // Treat plain IDs as document-backed image assets
  return '$publicHost/api/documents/$ref/raw';
  }

  // Fallback treat as ID
  return '$publicHost/api/documents/$ref/raw';
}
