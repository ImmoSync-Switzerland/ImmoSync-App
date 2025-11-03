import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:immosync/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/db_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:crypto/crypto.dart';

class MongoImage extends StatefulWidget {
  final String imageId;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final bool forceReload;

  const MongoImage({
    Key? key,
    required this.imageId,
    this.width,
    this.height,
    this.fit,
    this.errorWidget,
    this.loadingWidget,
    this.forceReload = false,
  }) : super(key: key);

  @override
  State<MongoImage> createState() => _MongoImageState();
}

class _MongoImageState extends State<MongoImage> {
  bool _isLoading = true;
  bool _hasError = false;
  Uint8List? _imageBytes;
  String? _dataUrl;
  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(MongoImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageId != widget.imageId || widget.forceReload) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      if (kIsWeb) {
        // For web, use the base64 endpoint
        await _loadImageAsBase64();
      } else {
        // For mobile, use direct HTTP request
        await _loadImageAsBytes();
      }
    } catch (e) {
      print('Error loading MongoDB image: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // ===== Auth Helpers =====
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

  Future<Map<String, String>> _headers() async {
    final base = <String, String>{
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

  Future<void> _tryLoginExchangeWithUiJwt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null || userId.isEmpty) return;
      final assertion = _buildUiJwt(userId);
      if (assertion == null) return;
      final ex = await http.post(
        Uri.parse('${DbConfig.apiUrl}/auth/login-exchange'),
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
          print('AUTH DEBUG [MongoImage]: obtained token; prefix=$prefix');
        }
      } else {
        print('AUTH DEBUG [MongoImage]: UI-JWT exchange failed ${ex.statusCode} ${ex.body}');
      }
    } catch (e) {
      print('AUTH DEBUG [MongoImage]: UI-JWT exchange error: $e');
    }
  }

  Future<void> _loadImageAsBase64() async {
    // Add cache buster to ensure fresh load
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    var response = await http.get(
      Uri.parse(
          '${DbConfig.apiUrl}/images/base64/${widget.imageId}?v=$cacheBuster'),
      headers: await _headers(),
    );
    if (response.statusCode == 401) {
      await _tryLoginExchangeWithUiJwt();
      response = await http.get(
        Uri.parse('${DbConfig.apiUrl}/images/base64/${widget.imageId}?v=$cacheBuster'),
        headers: await _headers(),
      );
    }

    print(
        'Loading base64 image for ID: ${widget.imageId}, Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (!mounted) return;
      setState(() {
        _dataUrl = data['dataUrl'];
        _isLoading = false;
      });
      print('Base64 image loaded successfully');
    } else {
      throw Exception('Failed to load image: ${response.statusCode}');
    }
  }

  Future<void> _loadImageAsBytes() async {
    // Add cache buster to ensure fresh load
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    // Accept raw ID or full URL; if widget.imageId already looks like a URL keep it
    String url;
    if (widget.imageId.startsWith('http://') ||
        widget.imageId.startsWith('https://')) {
      url = widget.imageId;
    } else {
      // Ensure we don't double append /api when constructing base
      final api = DbConfig.apiUrl; // e.g. https://backend.immosync.ch/api
      url = '$api/images/${widget.imageId}?v=$cacheBuster';
    }
    var response = await http.get(Uri.parse(url), headers: await _headers());
    if (response.statusCode == 401) {
      await _tryLoginExchangeWithUiJwt();
      response = await http.get(Uri.parse(url), headers: await _headers());
    }

    print(
        'Loading image bytes for ID: ${widget.imageId}, Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      if (!mounted) return;
      setState(() {
        _imageBytes = response.bodyBytes;
        _isLoading = false;
      });
      print('Image bytes loaded successfully');
    } else {
      throw Exception(
          'Failed to load image: ${response.statusCode} (${response.reasonPhrase})');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
    }

    if (_hasError) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[300],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.broken_image,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.failedToLoadImage,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
    }

    if (kIsWeb && _dataUrl != null) {
      // For web, use Image.network with data URL
      return Image.network(
        _dataUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          print('Data URL image error: $error');
          return widget.errorWidget ??
              Container(
                width: widget.width,
                height: widget.height,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
        },
      );
    } else if (_imageBytes != null) {
      // For mobile, use Image.memory
      return Image.memory(
        _imageBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          print('Memory image error: $error');
          return widget.errorWidget ??
              Container(
                width: widget.width,
                height: widget.height,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
        },
      );
    }

    return widget.errorWidget ??
        Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
  }
}
