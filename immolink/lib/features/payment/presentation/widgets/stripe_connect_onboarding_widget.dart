import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/core/providers/dynamic_colors_provider.dart';
import 'package:immosync/features/payment/domain/services/stripe_connect_js_service.dart';
import 'package:immosync/features/payment/domain/services/connect_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/web_wrapper.dart' as web;

class StripeConnectOnboardingWidget extends ConsumerStatefulWidget {
  final String accountId;
  final String? returnUrl;
  final String? refreshUrl;
  final Map<String, String>? customAppearance;

  const StripeConnectOnboardingWidget({
    super.key,
    required this.accountId,
    this.returnUrl,
    this.refreshUrl,
    this.customAppearance,
  });

  @override
  ConsumerState<StripeConnectOnboardingWidget> createState() =>
      _StripeConnectOnboardingWidgetState();
}

class _StripeConnectOnboardingWidgetState
    extends ConsumerState<StripeConnectOnboardingWidget> {
  final ConnectService _connectService = ConnectService();
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  String? _componentId;

  @override
  void initState() {
    super.initState();
    _initializeComponent();
  }

  @override
  void dispose() {
    _cleanupComponent();
    super.dispose();
  }

  Future<void> _initializeComponent() async {
    if (!kIsWeb) {
      // Fall back to hosted onboarding for non-web platforms
      _fallbackToHostedOnboarding();
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Initialize Stripe Connect if not already done
      final initialized = await StripeConnectJSService.initialize(
        publishableKey:
            'pk_test_LMUiQyn0mBZPsUIhVrVMblov', // Replace with your key
        fetchClientSecret: () => _connectService.createAccountSession(
          accountId: widget.accountId,
          components: {
            'account_onboarding': {'enabled': true},
          },
        ),
        appearance: widget.customAppearance ?? _getDefaultAppearance(),
      );

      if (!initialized) {
        throw Exception('Failed to initialize Stripe Connect');
      }

      // Create and mount the onboarding component
      await _createAndMountComponent();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing embedded onboarding: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });

      // Fall back to hosted onboarding
      _fallbackToHostedOnboarding();
    }
  }

  Future<void> _createAndMountComponent() async {
    final componentId = 'stripe-onboarding-${widget.accountId}';
    _componentId = componentId;

    // Create container element
    final container = web.HTMLDivElement()
      ..id = componentId
      ..style.width = '100%'
      ..style.height = '600px'
      ..style.minHeight = '400px';

    // Find the Flutter widget container and append our element
    final flutterView = web.document.querySelector('flt-glass-pane');
    if (flutterView != null) {
      flutterView.appendChild(container);
    } else {
      web.document.body?.appendChild(container);
    }

    // Create the Stripe component
    final component = StripeConnectJSService.createComponent(
      StripeConnectComponents.accountOnboarding,
    );

    if (component != null) {
      print('Onboarding component created successfully');
      setState(() {
        _isLoading = false;
      });

      // Mount the component
      component.mount(componentId);
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to create onboarding component';
        _isLoading = false;
      });
    }
  }

  void _cleanupComponent() {
    if (_componentId != null) {
      final element = web.document.getElementById(_componentId!);
      element?.remove();
    }
  }

  Future<void> _fallbackToHostedOnboarding() async {
    try {
      final onboardingUrl = await _connectService.createOnboardingLink(
        accountId: widget.accountId,
        returnUrl: widget.returnUrl ?? 'immolink://connect/return',
        refreshUrl: widget.refreshUrl ?? 'immolink://connect/refresh',
      );

      final uri = Uri.parse(onboardingUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to create onboarding link: $e';
      });
    }
  }

  Map<String, String> _getDefaultAppearance() {
    final colors = ref.read(dynamicColorsProvider);
    return {
      'colorPrimary':
          '#${(colors.primaryAccent.r * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.primaryAccent.g * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.primaryAccent.b * 255).round().toRadixString(16).padLeft(2, '0')}',
      'colorBackground':
          '#${(colors.primaryBackground.r * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.primaryBackground.g * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.primaryBackground.b * 255).round().toRadixString(16).padLeft(2, '0')}',
      'colorText':
          '#${(colors.textPrimary.r * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.textPrimary.g * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.textPrimary.b * 255).round().toRadixString(16).padLeft(2, '0')}',
      'borderRadius': '12px',
      'fontFamily': 'system-ui, -apple-system, sans-serif',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(dynamicColorsProvider);

    if (!kIsWeb) {
      // Mobile fallback UI
      return _buildMobileFallback(colors);
    }

    if (_hasError) {
      return _buildErrorState(colors);
    }

    if (_isLoading) {
      return _buildLoadingState(colors);
    }

    // The embedded component will be rendered in the DOM
    return Container(
      width: double.infinity,
      height: 600,
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryAccent.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance,
                  color: colors.primaryAccent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Complete Account Setup',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: kIsWeb
                  ? const Text(
                      'Stripe onboarding component will appear here',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    )
                  : const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(DynamicAppColors colors) {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colors.primaryAccent),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading account setup...',
            style: TextStyle(
              fontSize: 16,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(DynamicAppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: colors.error,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load embedded setup',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Please try the alternative setup method',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fallbackToHostedOnboarding,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Continue with Browser Setup'),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFallback(DynamicAppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance,
            color: colors.primaryAccent,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Complete Account Setup',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set up your payment account to start receiving rent payments',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fallbackToHostedOnboarding,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.launch, size: 20),
                SizedBox(width: 8),
                Text(
                  'Start Setup',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
