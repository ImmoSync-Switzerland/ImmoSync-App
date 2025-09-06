import 'dart:js_interop';

/// JavaScript interop for Stripe Connect
@JS('StripeConnect')
external JSFunction? get stripeConnect;

/// Stripe Connect configuration
@JS()
@anonymous
extension type StripeConnectConfig._(JSObject _) implements JSObject {
  external StripeConnectConfig({
    required String publishableKey,
    required JSFunction fetchClientSecret,
    JSObject? appearance,
    String? locale,
  });
}

/// Stripe Connect appearance configuration
@JS()
@anonymous
extension type StripeConnectAppearance._(JSObject _) implements JSObject {
  external StripeConnectAppearance({
    String? overlays,
    JSObject? variables,
  });
}

/// Stripe Connect variables
@JS()
@anonymous
extension type StripeConnectVariables._(JSObject _) implements JSObject {
  external StripeConnectVariables({
    String? fontFamily,
    String? colorPrimary,
    String? colorBackground,
    String? colorText,
    String? borderRadius,
  });
}

/// Stripe Connect component
@JS()
@anonymous
extension type StripeConnectComponent._(JSObject _) implements JSObject {
  external void mount(String elementId);
  external void unmount();
  external void update(JSObject? options);
  external void destroy();
}

/// Service for managing Stripe Connect JavaScript integration (web)
class StripeConnectJSService {
  static bool _isInitialized = false;
  static StripeConnectConfig? _config;
  static JSObject? _connectInstance;

  /// Check if initialized
  static bool get isInitialized => _isInitialized;

  /// Initialize Stripe Connect with configuration
  static Future<bool> initialize({
    required String publishableKey,
    required Future<String> Function() fetchClientSecret,
    Map<String, String>? appearance,
    String? locale,
  }) async {
    if (_isInitialized) return true;

    try {
      // Wait for StripeConnect to be available
      await _waitForStripeConnect();

      _config = StripeConnectConfig(
        publishableKey: publishableKey,
        fetchClientSecret: ((JSAny? _) async {
          final clientSecret = await fetchClientSecret();
          return clientSecret.toJS;
        }.toJS),
        appearance: appearance != null ? _createAppearance(appearance) : null,
        locale: locale,
      );

      // Initialize the Connect instance
      final result = stripeConnect!.callAsFunction(null, _config);
      _connectInstance = result as JSObject?;
      _isInitialized = true;

      return true;
    } catch (e) {
      print('Error initializing Stripe Connect: $e');
      return false;
    }
  }

  /// Create a Connect component
  static StripeConnectComponent? createComponent(String componentType,
      {String? elementId}) {
    if (!_isInitialized || _connectInstance == null) {
      print('Stripe Connect not initialized');
      return null;
    }

    try {
      // For now, create a mock component for testing
      // This will be implemented properly when we test with actual Stripe Connect
      print('Creating component: $componentType');

      // Return null for now - the actual implementation will depend on
      // the exact structure of the Stripe Connect JS library
      return null;
    } catch (e) {
      print('Error creating component $componentType: $e');
      return null;
    }
  }

  /// Create and mount component to specific element
  static StripeConnectComponent? createAndMountComponent(
      String componentType, String elementId,
      {Map<String, dynamic>? options}) {
    return createComponent(componentType, elementId: elementId);
  }

  /// Destroy all components and cleanup
  static void cleanup() {
    _connectInstance = null;
    _config = null;
    _isInitialized = false;
  }

  /// Wait for StripeConnect to be available in the global scope
  static Future<void> _waitForStripeConnect() async {
    var attempts = 0;
    const maxAttempts = 50; // 5 seconds max wait

    while (stripeConnect == null && attempts < maxAttempts) {
      await Future.delayed(Duration(milliseconds: 100));
      attempts++;
    }

    if (stripeConnect == null) {
      throw Exception('StripeConnect library not loaded after 5 seconds');
    }
  }

  /// Create appearance configuration
  static StripeConnectAppearance _createAppearance(
      Map<String, String> appearance) {
    return StripeConnectAppearance(
      overlays: appearance['overlays'] ?? 'dialog',
      variables: StripeConnectVariables(
        fontFamily: appearance['fontFamily'],
        colorPrimary: appearance['colorPrimary'],
        colorBackground: appearance['colorBackground'],
        colorText: appearance['colorText'],
        borderRadius: appearance['borderRadius'],
      ),
    );
  }
}

/// Available Stripe Connect component types
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
