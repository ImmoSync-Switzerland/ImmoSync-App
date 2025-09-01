import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide PaymentMethod;
import 'package:immosync/core/providers/dynamic_colors_provider.dart';
import 'package:immosync/features/payment/domain/services/connect_service.dart';
import 'package:immosync/features/property/domain/models/property.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class TenantPaymentPage extends ConsumerStatefulWidget {
  final Property property;
  final String paymentType;
  final double? customAmount;

  const TenantPaymentPage({
    super.key,
    required this.property,
    this.paymentType = 'rent',
    this.customAmount,
  });

  @override
  ConsumerState<TenantPaymentPage> createState() => _TenantPaymentPageState();
}

class _TenantPaymentPageState extends ConsumerState<TenantPaymentPage> {
  final ConnectService _connectService = ConnectService();
  bool _isLoading = false;
  String? _selectedPaymentMethod;
  List<PaymentMethod> _paymentMethods = [];
  double get _amount => widget.customAmount ?? widget.property.rentAmount;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final methods = await _connectService.getAvailablePaymentMethods('ch'); // Default to Switzerland
      setState(() {
        _paymentMethods = methods;
        if (methods.isNotEmpty) {
          _selectedPaymentMethod = methods.first.type;
        }
      });
    } catch (e) {
      // On mobile (APK) a common cause is an unreachable API_URL (e.g. pointing to localhost) or
      // network / TLS issues. Provide a safe fallback so user still sees at least "Card".
      debugPrint('Error loading payment methods: $e');
      if (mounted) {
        setState(() {
          _paymentMethods = [
            PaymentMethod(
              type: 'card',
              name: 'Credit/Debit Card',
              icon: 'credit_card',
              instant: true,
              description: 'Standard card payment',
            ),
          ];
          _selectedPaymentMethod = 'card';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Pay ${widget.paymentType.toUpperCase()}',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colors.surfaceCards,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property info card
            _buildPropertyCard(colors, l10n),
            const SizedBox(height: 24),
            
            // Payment amount
            _buildAmountSection(colors, l10n),
            const SizedBox(height: 24),
            
            // Payment methods
            _buildPaymentMethodsSection(colors, l10n),
            const SizedBox(height: 32),
            
            // Pay button
            _buildPayButton(colors, l10n, user),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(DynamicAppColors colors, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primaryAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.home,
                  color: colors.primaryAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.property.address.street,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      '${widget.property.address.city}, ${widget.property.address.postalCode}',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection(DynamicAppColors colors, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.paymentType.toUpperCase()} Payment',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                'CHF ${_amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: colors.borderLight),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Processing Fee',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
              Text(
                'CHF ${(_amount * 0.029 + 0.30).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: colors.borderLight),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                'CHF ${_amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection(DynamicAppColors colors, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (_paymentMethods.isEmpty) ...[
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: colors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No payment methods loaded. Check network/API configuration. Showing none.',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          ..._paymentMethods.map((method) => _buildPaymentMethodTile(method, colors)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method, DynamicAppColors colors) {
    final isSelected = _selectedPaymentMethod == method.type;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedPaymentMethod = method.type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryAccent.withValues(alpha: 0.1) : colors.primaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.primaryAccent : colors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? colors.primaryAccent : colors.textSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconForMethod(method.icon),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        method.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (method.instant) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.success,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Instant',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (method.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      method.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colors.primaryAccent,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForMethod(String iconName) {
    switch (iconName) {
      case 'credit_card':
        return Icons.credit_card;
      case 'account_balance':
        return Icons.account_balance;
      case 'flash_on':
        return Icons.flash_on;
      default:
        return Icons.payment;
    }
  }

  Widget _buildPayButton(DynamicAppColors colors, AppLocalizations l10n, user) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading || _selectedPaymentMethod == null || user == null 
          ? null 
          : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.success,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Pay CHF ${_amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Future<void> _processPayment() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Create payment intent
      final paymentData = await _connectService.createTenantPayment(
        tenantId: user.id,
        propertyId: widget.property.id,
        amount: _amount,
        paymentType: widget.paymentType,
        description: '${widget.paymentType} payment for ${widget.property.address.street}',
        preferredPaymentMethod: _selectedPaymentMethod,
      );

      // Configure payment sheet parameters based on payment method
      final paymentSheetParams = SetupPaymentSheetParameters(
        paymentIntentClientSecret: paymentData['clientSecret'],
        merchantDisplayName: 'ImmoSync',
        style: ThemeMode.system,
        billingDetails: BillingDetails(
          email: user.email,
          name: user.fullName,
        ),
        // Allow delayed payment methods like bank transfers
        allowsDelayedPaymentMethods: _selectedPaymentMethod != 'card',
      );
      debugPrint('[Stripe] Init sheet with method=${_selectedPaymentMethod} delayed=${_selectedPaymentMethod != 'card'}');

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: paymentSheetParams,
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Payment successful
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getSuccessMessage()),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back or to success page
        context.pop();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getSuccessMessage() {
    switch (_selectedPaymentMethod) {
      case 'bank_transfer':
      case 'sepa_debit':
        return 'Payment initiated! It will be processed within 1-3 business days.';
      case 'sofort':
      case 'ideal':
        return 'Payment completed successfully!';
      case 'card':
      default:
        return 'Payment successful!';
    }
  }
}
