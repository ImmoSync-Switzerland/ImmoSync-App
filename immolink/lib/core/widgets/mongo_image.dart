import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:immosync/l10n/app_localizations.dart';

import '../config/db_config.dart';
import '../services/token_manager.dart';

class _MongoImageCacheEntry {
  final Uint8List? bytes;
  final String? dataUrl;
  final DateTime fetchedAt;

  _MongoImageCacheEntry({this.bytes, this.dataUrl})
      : fetchedAt = DateTime.now();

  bool get isValid => bytes != null || (dataUrl != null && dataUrl!.isNotEmpty);
}

class _MongoImageCache {
  static const Duration _ttl = Duration(minutes: 5);
  static final Map<String, _MongoImageCacheEntry> _cache = {};
  static final Map<String, Future<_MongoImageCacheEntry?>> _inFlight = {};

  static _MongoImageCacheEntry? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.fetchedAt) > _ttl) {
      _cache.remove(key);
      return null;
    }
    return entry;
  }

  static void put(String key, _MongoImageCacheEntry entry) {
    if (entry.isValid) {
      _cache[key] = entry;
    }
  }

  static void invalidate(String key) {
    _cache.remove(key);
  }

  static Future<_MongoImageCacheEntry?> join(
      String key, Future<_MongoImageCacheEntry?> Function() loader) {
    final existing = _inFlight[key];
    if (existing != null) {
      return existing;
    }
    final future = loader();
    _inFlight[key] = future;
    return future.whenComplete(() {
      _inFlight.remove(key);
    });
  }
}

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
  final TokenManager _tokenManager = TokenManager();
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

      final cacheKey = widget.imageId;
      if (!widget.forceReload) {
        final cached = _MongoImageCache.get(cacheKey);
        if (cached != null) {
          if (!mounted) return;
          _applyCacheEntry(cached);
          return;
        }
      } else {
        _MongoImageCache.invalidate(cacheKey);
      }

      Future<_MongoImageCacheEntry?> fetcher() async {
        if (kIsWeb) {
          return _loadImageAsBase64();
        } else {
          return _loadImageAsBytes();
        }
      }

      final entry = widget.forceReload
          ? await fetcher()
          : await _MongoImageCache.join(cacheKey, fetcher);

      if (!mounted) return;

      if (entry != null) {
        _MongoImageCache.put(cacheKey, entry);
        _applyCacheEntry(entry);
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[MongoImage] Error loading image ${widget.imageId}: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _applyCacheEntry(_MongoImageCacheEntry entry) {
    setState(() {
      _imageBytes = entry.bytes;
      _dataUrl = entry.dataUrl;
      _isLoading = false;
    });
  }

  Future<Map<String, String>> _headers() async {
    return await _tokenManager.getHeaders();
  }

  Future<_MongoImageCacheEntry?> _loadImageAsBase64() async {
    // Add cache buster to ensure fresh load
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    var response = await http.get(
      Uri.parse(
          '${DbConfig.apiUrl}/images/base64/${widget.imageId}?v=$cacheBuster'),
      headers: await _headers(),
    );
    if (response.statusCode == 401) {
      await _tokenManager.refreshToken(DbConfig.apiUrl);
      response = await http.get(
        Uri.parse(
            '${DbConfig.apiUrl}/images/base64/${widget.imageId}?v=$cacheBuster'),
        headers: await _headers(),
      );
    }

    if (kDebugMode) {
      debugPrint(
          'Loading base64 image for ID: ${widget.imageId}, Status: ${response.statusCode}');
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final url = data['dataUrl']?.toString();
      if (url == null || url.isEmpty) {
        throw Exception('Base64 response missing dataUrl');
      }
      if (kDebugMode) {
        debugPrint('Base64 image loaded successfully');
      }
      return _MongoImageCacheEntry(dataUrl: url);
    } else {
      throw Exception('Failed to load image: ${response.statusCode}');
    }
  }

  Future<_MongoImageCacheEntry?> _loadImageAsBytes() async {
    // Add cache buster to ensure fresh load
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    // Accept raw ID or full URL; if widget.imageId already looks like a URL keep it
    String url;
    if (widget.imageId.startsWith('http://') ||
        widget.imageId.startsWith('https://')) {
      // Normalize HTTP to HTTPS for security
      url = widget.imageId.replaceFirst('http://', 'https://');
    } else {
      // Ensure we don't double append /api when constructing base
      final api = DbConfig.apiUrl; // e.g. https://backend.immosync.ch/api
      url = '$api/images/${widget.imageId}?v=$cacheBuster';
    }
    var response = await http.get(Uri.parse(url), headers: await _headers());
    if (response.statusCode == 401) {
      await _tokenManager.refreshToken(DbConfig.apiUrl);
      response = await http.get(Uri.parse(url), headers: await _headers());
    }

    if (kDebugMode) {
      debugPrint(
          'Loading image bytes for ID: ${widget.imageId}, Status: ${response.statusCode}');
    }

    if (response.statusCode == 200) {
      if (kDebugMode) {
        debugPrint('Image bytes loaded successfully');
      }
      return _MongoImageCacheEntry(bytes: response.bodyBytes);
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
          debugPrint('Data URL image error: $error');
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
          debugPrint('Memory image error: $error');
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
