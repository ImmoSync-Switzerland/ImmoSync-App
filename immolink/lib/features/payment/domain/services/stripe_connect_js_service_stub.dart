// Native (non-web) stub for Stripe Connect JS service.
// Provides the API surface but no JS interop.

/// Lightweight stub for a Stripe Connect component on non-web platforms.
class StripeConnectComponent {
  void mount(String elementId) {}
  void unmount() {}
  void update(Object? options) {}
  void destroy() {}
}

class StripeConnectAppearance {
  final String? overlays;
  final Map<String, Object?>? variables;
  StripeConnectAppearance({this.overlays, this.variables});
}

class StripeConnectConfig {
  final String publishableKey;
  final Future<String> Function() fetchClientSecret;
  final StripeConnectAppearance? appearance;
  final String? locale;

  StripeConnectConfig({
    required this.publishableKey,
    required this.fetchClientSecret,
    this.appearance,
    this.locale,
  });
}

/// Service for managing Stripe Connect JavaScript integration on non-web.
class StripeConnectJSService {
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  /// Initialize is a no-op on native platforms and returns false.
  static Future<bool> initialize({
    required String publishableKey,
    required Future<String> Function() fetchClientSecret,
    Map<String, String>? appearance,
    String? locale,
  }) async {
    // JS integration not available on native platforms.
    _isInitialized = false;
    return false;
  }

  static StripeConnectComponent? createComponent(String componentType, {String? elementId}) {
    // Not available on native platforms.
    return null;
  }

  static StripeConnectComponent? createAndMountComponent(
    String componentType,
    String elementId,
    {Map<String, dynamic>? options}
  ) {
    return null;
  }

  static void cleanup() {
    _isInitialized = false;
  }
}

class StripeConnectComponents {
  static const String accountOnboarding = 'account_onboarding';
  static const String accountManagement = 'account_management';
  static const String payments = 'payments';
  static const String payouts = 'payouts';
  static const String balances = 'balances';
  static const String notificationBanner = 'notification_banner';
  static const String paymentDetails = 'payment_details';
  static const String payoutsList = 'payouts_list';
}
