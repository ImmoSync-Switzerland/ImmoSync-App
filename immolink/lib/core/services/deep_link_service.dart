import 'dart:async';
import 'dart:io' show Platform;
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/payment/presentation/providers/payment_providers.dart';

/// Service to handle deep links in the app
class DeepLinkService {
  StreamSubscription? _sub;
  final AppLinks _appLinks = AppLinks();

  /// Check if deep links are supported on this platform
  bool get isSupported {
    if (kIsWeb) return false;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
      return false;
    return true; // Android and iOS
  }

  /// Initialize deep link handling
  Future<void> initialize(WidgetRef ref) async {
    // Skip deep link initialization on unsupported platforms
    if (!isSupported) {
      print('[DeepLink] Deep links not supported on this platform');
      return;
    }

    // Handle the initial link if the app was opened via deep link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        print('[DeepLink] App opened with initial link: $initialLink');
        _handleDeepLink(initialLink, ref);
      }
    } on PlatformException catch (e) {
      print('[DeepLink][ERROR] Failed to get initial link: $e');
    }

    // Listen for deep links while app is running
    _sub = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        print('[DeepLink] Received deep link: $uri');
        _handleDeepLink(uri, ref);
      },
      onError: (err) {
        print('[DeepLink][ERROR] Deep link error: $err');
      },
    );
  }

  /// Handle incoming deep link
  void _handleDeepLink(Uri uri, WidgetRef ref) {
    print('[DeepLink] Handling: ${uri.scheme}://${uri.host}${uri.path}');

    // Check scheme
    if (uri.scheme != 'immosync') {
      print('[DeepLink] Unknown scheme: ${uri.scheme}');
      return;
    }

    // Handle different deep link types
    switch (uri.host) {
      case 'stripe-return':
        _handleStripeReturn(uri, ref);
        break;
      case 'stripe-refresh':
        _handleStripeRefresh(uri, ref);
        break;
      default:
        print('[DeepLink] Unknown host: ${uri.host}');
    }
  }

  /// Handle Stripe Connect return (after completing onboarding)
  void _handleStripeReturn(Uri uri, WidgetRef ref) {
    print('[DeepLink] Stripe onboarding completed');

    // Trigger a refresh of the Stripe Connect account status
    try {
      // Invalidate the Stripe Connect account provider to force a refresh
      ref.invalidate(stripeConnectAccountProvider);

      print(
          '[DeepLink] Stripe account status invalidated, will refresh on next view');

      // Show success notification when payment page becomes active
    } catch (e) {
      print('[DeepLink][ERROR] Error handling Stripe return: $e');
    }
  }

  /// Handle Stripe Connect refresh (when onboarding link expired)
  void _handleStripeRefresh(Uri uri, WidgetRef ref) {
    print('[DeepLink] Stripe onboarding link expired, needs refresh');

    // The app should regenerate the onboarding link
    try {
      // Invalidate the account provider to trigger re-creation of onboarding link
      ref.invalidate(stripeConnectAccountProvider);

      print('[DeepLink] Stripe account provider invalidated');
      print('[DeepLink] User should restart onboarding from payment page');

      // The payment page will detect the invalidation and offer to restart onboarding
    } catch (e) {
      print('[DeepLink][ERROR] Error handling Stripe refresh: $e');
    }
  }

  /// Dispose the service
  void dispose() {
    _sub?.cancel();
  }
}

/// Provider for the deep link service
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final service = DeepLinkService();
  ref.onDispose(() => service.dispose());
  return service;
});
