import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../firebase_options.dart';
import 'package:immosync/core/config/api_config.dart';

/// Top-level background handler (required by Firebase Messaging)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // ignore if already initialized or platform not supported
  }
  // Optionally process message.data for silent updates.
  debugPrint('[FCM][BG] message: ${message.messageId} data=${message.data}');
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  final svc = FcmService(ref);
  svc.ensureInitialized();
  return svc;
});

class FcmService {
  FcmService(Ref ref);
  final _messaging = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();
  bool _started = false;
  String? _currentUserId;
  String? _lastTokenSent;

  Future<void> ensureInitialized() async {
    if (_started) return;
    _started = true;

    // Register background handler (no-op on web)
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('[FCM] Background handler registration failed: $e');
    }

    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (isMobile) {
      await _initLocalNotifications();
      await _requestPermissionIfNeeded();
      await _obtainAndSendToken();

      _messaging.onTokenRefresh.listen((t) {
        debugPrint('[FCM] Token refresh: $t');
        _sendTokenToBackend(t);
      });

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint(
            '[FCM][FG] message ${message.messageId} title=${message.notification?.title}');
        _showForegroundNotification(message);
      });
    } else {
      debugPrint('[FCM] Skipping push init on non-mobile platform');
    }
  }

  void updateUserId(String? userId) async {
    if (userId == _currentUserId) return;
    _currentUserId = userId;
    // Only attempt token retrieval on supported mobile platforms
    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (userId != null && isMobile) {
      try {
        final token = await _messaging.getToken();
        if (token != null) {
          _sendTokenToBackend(token, force: true);
        }
      } catch (e) {
        debugPrint('[FCM] updateUserId getToken failed: $e');
      }
    } else if (userId != null) {
      debugPrint(
          '[FCM] updateUserId: skip real getToken on non-mobile platform');
      // Dev fallback: register a mock desktop token so backend flows (notification storage) can be tested.
      if (kDebugMode) {
        final mockToken = 'desktop-$userId';
        debugPrint('[FCM] Registering mock desktop token $mockToken');
        _sendTokenToBackend(mockToken, force: true, allowNonMobileMock: true);
      }
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    try {
      await _local.initialize(initSettings);
    } catch (e) {
      debugPrint('[FCM] Local notifications init failed: $e');
    }
    // Create a basic channel
    const channel = AndroidNotificationChannel(
      'default_channel',
      'General Notifications',
      description: 'General notifications',
      importance: Importance.defaultImportance,
    );
    try {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint('[FCM] Channel creation failed: $e');
    }
  }

  Future<void> _requestPermissionIfNeeded() async {
    if (kIsWeb) return; // web prompts automatically / or handled differently
    final settings = await _messaging.requestPermission();
    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');
  }

  Future<void> _obtainAndSendToken() async {
    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!isMobile) return; // guard
    try {
      final token = await _messaging.getToken();
      debugPrint('[FCM] Initial token: $token');
      if (token != null) {
        _sendTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('[FCM] getToken failed: $e');
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null)
      return; // Only show if normal notification payload
    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'General Notifications',
          channelDescription: 'General notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _sendTokenToBackend(String token,
      {bool force = false, bool allowNonMobileMock = false}) async {
    if (_currentUserId == null) {
      debugPrint('[FCM] Skipping token send (no user id yet)');
      return;
    }
    if (!force && token == _lastTokenSent) return;
    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!isMobile && !allowNonMobileMock) {
      debugPrint(
          '[FCM] Skip token backend send on non-mobile platform (not a mock)');
      return;
    }
    try {
      final baseUrl = ApiConfig.baseUrl;
      final uri = Uri.parse('$baseUrl/notifications/register-token');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': _currentUserId, 'token': token}),
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        _lastTokenSent = token;
        debugPrint('[FCM] Token registered');
      } else {
        debugPrint(
            '[FCM][WARN] Token send failed: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('[FCM][ERR] Token send exception: $e');
    }
  }
}
