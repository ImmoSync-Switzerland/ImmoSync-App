import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// A custom ImageProvider that includes authentication headers
class AuthenticatedNetworkImageProvider extends ImageProvider<AuthenticatedNetworkImageProvider> {
  const AuthenticatedNetworkImageProvider(
    this.url, {
    this.scale = 1.0,
    this.headers,
  });

  final String url;
  final double scale;
  final Map<String, String>? headers;

  @override
  Future<AuthenticatedNetworkImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AuthenticatedNetworkImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(AuthenticatedNetworkImageProvider key, ImageDecoderCallback decode) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode, chunkEvents),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<AuthenticatedNetworkImageProvider>('Image key', key),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    AuthenticatedNetworkImageProvider key,
    ImageDecoderCallback decode,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    try {
      // Get session token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('sessionToken');

      // Build headers with authentication
      final requestHeaders = <String, String>{
        ...?headers,
      };
      
      if (token != null && token.isNotEmpty) {
        requestHeaders['Authorization'] = 'Bearer $token';
      }

      // Make authenticated request
      final response = await http.get(
        Uri.parse(key.url),
        headers: requestHeaders,
      );

      if (response.statusCode != 200) {
        throw NetworkImageLoadException(
          statusCode: response.statusCode,
          uri: Uri.parse(key.url),
        );
      }

      final bytes = response.bodyBytes;
      if (bytes.isEmpty) {
        throw Exception('Image is empty');
      }

      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      return decode(buffer);
    } catch (e) {
      // Log error for debugging
      debugPrint('[AuthenticatedNetworkImageProvider] Failed to load image: $e');
      
      // Re-throw as appropriate exception
      if (e is NetworkImageLoadException) {
        rethrow;
      }
      throw NetworkImageLoadException(
        statusCode: -1,
        uri: Uri.parse(key.url),
      );
    } finally {
      await chunkEvents.close();
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is AuthenticatedNetworkImageProvider &&
        other.url == url &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() => '${objectRuntimeType(this, 'AuthenticatedNetworkImageProvider')}("$url", scale: $scale)';
}

/// Widget wrapper for easier usage
class AuthenticatedNetworkImage extends StatelessWidget {
  const AuthenticatedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: AuthenticatedNetworkImageProvider(imageUrl),
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        if (frame == null && placeholder != null) return placeholder!;
        return child;
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('[AuthenticatedNetworkImage] Error loading image: $error');
        return errorWidget ?? Icon(Icons.error, size: width ?? height ?? 50);
      },
    );
  }
}
