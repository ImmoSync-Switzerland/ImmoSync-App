import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:immosync/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/core/providers/dynamic_colors_provider.dart';
import 'package:immosync/features/payment/domain/services/stripe_connect_js_service.dart';
import 'package:immosync/features/payment/domain/services/connect_service.dart';
import '../../../../core/web_wrapper.dart' as web;

class StripeConnectPaymentsDashboard extends ConsumerStatefulWidget {
  final String accountId;
  final String componentType;
  final Map<String, String>? customAppearance;

  const StripeConnectPaymentsDashboard({
    super.key,
    required this.accountId,
    this.componentType = 'payments',
    this.customAppearance,
  });

  @override
  ConsumerState<StripeConnectPaymentsDashboard> createState() =>
      _StripeConnectPaymentsDashboardState();
}

class _StripeConnectPaymentsDashboardState
    extends ConsumerState<StripeConnectPaymentsDashboard> {
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
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Dashboard components are only available on web';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Initialize Stripe Connect
      final initialized = await StripeConnectJSService.initialize(
        publishableKey: 'pk_test_LMUiQyn0mBZPsUIhVrVMblov', // Replace with your key
        fetchClientSecret: () => _connectService.createAccountSession(
          accountId: widget.accountId,
          components: _getComponentsConfig(),
        ),
        appearance: widget.customAppearance ?? _getDefaultAppearance(),
      );

      if (!initialized) {
        throw Exception('Failed to initialize Stripe Connect');
      }

      // Create and mount the component
      await _createAndMountComponent();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing embedded dashboard: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Map<String, dynamic> _getComponentsConfig() {
    switch (widget.componentType) {
      case 'payments':
        return {
          'payments': {
            'enabled': true,
            'features': {
              'refund_management': true,
              'dispute_management': true,
              'capture_payments': true,
            },
          },
        };
      case 'payouts':
        return {
          'payouts': {
            'enabled': true,
            'features': {
              'instant_payouts': true,
              'standard_payouts': true,
              'payout_schedule': true,
            },
          },
        };
      case 'balances':
        return {
          'balances': {'enabled': true},
        };
      case 'account_management':
        return {
          'account_management': {'enabled': true},
        };
      default:
        return {
          'payments': {'enabled': true},
        };
    }
  }

  Future<void> _createAndMountComponent() async {
    final componentId = 'stripe-${widget.componentType}-${widget.accountId}';
    _componentId = componentId;

    // Create container element
    final container = web.HTMLDivElement()
      ..id = componentId
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.minHeight = '400px';

    // Find the Flutter widget container and append our element
    final flutterView = web.document.querySelector('flt-glass-pane');
    if (flutterView != null) {
      flutterView.appendChild(container);
    } else {
      web.document.body?.appendChild(container);
    }

    // Create the Stripe component
    final component = StripeConnectJSService.createComponent(widget.componentType);

    if (component != null) {
      print('Dashboard component created successfully');
      setState(() {
        _isLoading = false;
      });

      // Mount the component
      component.mount(componentId);
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to create dashboard component';
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

  Map<String, String> _getDefaultAppearance() {
    final colors = ref.read(dynamicColorsProvider);
    return {
      'colorPrimary': '#${(colors.primaryAccent.r * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.primaryAccent.g * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.primaryAccent.b * 255).round().toRadixString(16).padLeft(2, '0')}',
      'colorBackground': '#${(colors.primaryBackground.r * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.primaryBackground.g * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.primaryBackground.b * 255).round().toRadixString(16).padLeft(2, '0')}',
      'colorText': '#${(colors.textPrimary.r * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.textPrimary.g * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.textPrimary.b * 255).round().toRadixString(16).padLeft(2, '0')}',
      'borderRadius': '12px',
      'fontFamily': 'system-ui, -apple-system, sans-serif',
    };
  }

  String _getComponentTitle() {
    switch (widget.componentType) {
      case 'payments':
        return 'Payment Management';
      case 'payouts':
        return 'Payouts & Balance';
      case 'balances':
        return 'Account Balance';
      case 'account_management':
        return 'Account Settings';
      default:
        return 'Dashboard';
    }
  }

  IconData _getComponentIcon() {
    switch (widget.componentType) {
      case 'payments':
        return Icons.payment;
      case 'payouts':
        return Icons.account_balance_wallet;
      case 'balances':
        return Icons.account_balance;
      case 'account_management':
        return Icons.settings;
      default:
        return Icons.dashboard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(dynamicColorsProvider);

    if (_hasError) {
      return _buildErrorState(colors);
    }

    if (_isLoading) {
      return _buildLoadingState(colors);
    }

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
                  _getComponentIcon(),
                  color: colors.primaryAccent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  _getComponentTitle(),
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
                    'Stripe dashboard component will appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  )
                : _buildMobileNotice(colors),
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
            'Loading ${_getComponentTitle().toLowerCase()}...',
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
            AppLocalizations.of(context)!.errorLoadingProperties, // placeholder mapping
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? AppLocalizations.of(context)!.dashboardComponentsRequireBrowser,
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _initializeComponent,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileNotice(DynamicAppColors colors) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.web,
            color: colors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.dashboardAvailableOnWeb,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.visitWebForFullDashboard(_getComponentTitle().toLowerCase()),
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
