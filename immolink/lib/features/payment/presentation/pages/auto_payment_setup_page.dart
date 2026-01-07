import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../domain/services/connect_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../property/presentation/providers/property_providers.dart';

class AutoPaymentSetupPage extends ConsumerStatefulWidget {
  const AutoPaymentSetupPage({super.key});

  @override
  ConsumerState<AutoPaymentSetupPage> createState() =>
      _AutoPaymentSetupPageState();
}

class _AutoPaymentSetupPageState extends ConsumerState<AutoPaymentSetupPage> {
  String _selectedPaymentMethod = 'bank';
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _landlordId;
  String? _tenantId;
  String? _propertyId;

  // Form controllers
  final _bankAccountController = TextEditingController();
  final _routingNumberController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTenantData();
  }

  Future<void> _loadTenantData() async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      _tenantId = currentUser.id;

      // Get tenant's property to find landlord
      final propertiesAsync = ref.read(tenantPropertiesProvider);
      propertiesAsync.whenData((properties) {
        if (properties.isNotEmpty) {
          final property = properties.first;
          setState(() {
            _landlordId = property.landlordId;
            _propertyId = property.id;
          });
        }
      });
    } catch (e) {
      print('[AutoPayment] Error loading tenant data: $e');
    }
  }

  @override
  void dispose() {
    _bankAccountController.dispose();
    _routingNumberController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ref.watch(dynamicColorsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(l10n, colors),
      bottomNavigationBar: const CommonBottomNav(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.primaryBackground,
              colors.surfaceSecondary,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(l10n, colors),
                  const SizedBox(height: 32),
                  _buildPaymentMethodSelector(l10n, colors),
                  const SizedBox(height: 24),
                  _buildPaymentForm(l10n, colors),
                  const SizedBox(height: 32),
                  _buildSetupButton(l10n, colors),
                  const SizedBox(height: 24),
                  _buildSecurityNote(l10n, colors),
                  const SizedBox(height: 100), // Extra padding for bottom nav
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      AppLocalizations l10n, DynamicAppColors colors) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary, size: 20),
        onPressed: () {
          HapticFeedback.lightImpact();
          context.pop();
        },
      ),
      title: Text(
        l10n.autoPaymentSetupTitle,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeader(AppLocalizations l10n, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E7D32), // Dunkleres Grün
            Color(0xFF66BB6A), // Helleres Grün
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.payment_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.automaticPayments,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.neverMissRentPayment,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.encryptedSecurePaymentProcessing,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.95),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector(
      AppLocalizations l10n, DynamicAppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.paymentMethod,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPaymentMethodCard(
                l10n.bankAccount,
                Icons.account_balance_outlined,
                'bank',
                l10n.achTransfer,
                colors,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPaymentMethodCard(
                l10n.creditDebitCard,
                Icons.credit_card_outlined,
                'card',
                l10n.instantPayment,
                colors,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(String title, IconData icon, String value,
      String subtitle, DynamicAppColors colors) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedPaymentMethod = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [
                    const Color(0xFF2E7D32), // Dunkleres Grün
                    const Color(0xFF66BB6A), // Helleres Grün
                  ]
                : [
                    colors.surfaceCards,
                    colors.surfaceCards.withValues(alpha: 0.8)
                  ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : colors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF2E7D32).withValues(alpha: 0.4)
                  : colors.shadowColor.withValues(alpha: 0.1),
              blurRadius: isSelected ? 16 : 8,
              offset: Offset(0, isSelected ? 6 : 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : colors.textSecondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : colors.textSecondary,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.9)
                    : colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm(AppLocalizations l10n, DynamicAppColors colors) {
    return _selectedPaymentMethod == 'bank'
        ? _buildBankForm(l10n, colors)
        : _buildCardForm(l10n, colors);
  }

  Widget _buildBankForm(AppLocalizations l10n, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.bankAccountInformation,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _bankAccountController,
            decoration: InputDecoration(
              labelText: l10n.accountNumber,
              hintText: l10n.enterBankAccountNumber,
              prefixIcon: const Icon(Icons.account_balance_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) return l10n.accountNumberIsRequired;
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _routingNumberController,
            decoration: InputDecoration(
              labelText: l10n.routingNumber,
              hintText: l10n.enterBankRoutingNumber,
              prefixIcon: const Icon(Icons.numbers_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) return l10n.routingNumberIsRequired;
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardForm(AppLocalizations l10n, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.cardInformation,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _cardHolderController,
            decoration: InputDecoration(
              labelText: l10n.cardholderName,
              hintText: l10n.enterNameOnCard,
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return l10n.cardholderNameIsRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cardNumberController,
            decoration: InputDecoration(
              labelText: l10n.cardNumber,
              hintText: '1234 5678 9012 3456',
              prefixIcon: const Icon(Icons.credit_card_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) return l10n.cardNumberIsRequired;
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  decoration: InputDecoration(
                    labelText: l10n.expiryDate,
                    hintText: 'MM/YY',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return l10n.expiryDateIsRequired;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  decoration: InputDecoration(
                    labelText: l10n.cvv,
                    hintText: '123',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return l10n.cvvIsRequired;
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetupButton(AppLocalizations l10n, DynamicAppColors colors) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2E7D32), // Dunkleres Grün
            Color(0xFF66BB6A), // Helleres Grün
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _setupAutoPayment(l10n, colors),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    l10n.setUpAutoPayment,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSecurityNote(AppLocalizations l10n, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security_outlined,
            color: colors.info,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.secureAndEncrypted,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.autoPaymentSecurityDescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSetupConfirmation(BuildContext context, DynamicAppColors colors) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: colors.success),
            const SizedBox(width: 8),
            Text(l10n.setupCompleteTitle),
          ],
        ),
        content: Text(
          l10n.setupCompleteMessage,
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop(); // Go back to previous page
            },
            child: Text(
              l10n.done,
              style: TextStyle(color: colors.primaryAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setupAutoPayment(
      AppLocalizations l10n, DynamicAppColors colors) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Check if we have landlord information
    if (_landlordId == null) {
      _showErrorDialog(
        context,
        colors,
        l10n.unableToSetupPaymentNoPropertyInfo,
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      // Create setup intent for recurring payments with landlord connection
      final connectService = ConnectService();
      final setupResponse = await connectService.createSetupIntent(
        paymentMethodType: _selectedPaymentMethod,
        landlordId: _landlordId!,
        tenantId: _tenantId,
        propertyId: _propertyId,
      );

      if (setupResponse['client_secret'] == null) {
        throw Exception('Failed to create setup intent');
      }

      if (_selectedPaymentMethod == 'bank') {
        // For bank transfers, we need to collect bank account details
        await _setupBankAccount(setupResponse['client_secret'], connectService);
      } else {
        // For cards, use Stripe's payment method collection
        await _setupCardPayment(setupResponse['client_secret']);
      }

      _showSetupConfirmation(context, colors);
    } catch (e) {
      _showErrorDialog(context, colors, l10n.setupFailedWithError(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _setupBankAccount(
      String clientSecret, ConnectService connectService) async {
    // For bank transfers, we need to collect the account details
    // and create a setup intent with bank account payment method
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        setupIntentClientSecret: clientSecret,
        merchantDisplayName: 'ImmoSync',
        allowsDelayedPaymentMethods: true,
      ),
    );

    await Stripe.instance.presentPaymentSheet();
    // Payment sheet handles the setup - if we get here, it was successful
  }

  Future<void> _setupCardPayment(String clientSecret) async {
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        setupIntentClientSecret: clientSecret,
        merchantDisplayName: 'ImmoSync',
      ),
    );

    await Stripe.instance.presentPaymentSheet();
    // Payment sheet handles the setup - if we get here, it was successful
  }

  void _showErrorDialog(
      BuildContext context, DynamicAppColors colors, String message) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: colors.error),
            const SizedBox(width: 8),
            Text(l10n.setupFailedTitle),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.ok,
              style: TextStyle(color: colors.primaryAccent),
            ),
          ),
        ],
      ),
    );
  }
}
