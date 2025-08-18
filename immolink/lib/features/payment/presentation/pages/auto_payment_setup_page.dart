import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';

class AutoPaymentSetupPage extends ConsumerStatefulWidget {
  const AutoPaymentSetupPage({super.key});

  @override
  ConsumerState<AutoPaymentSetupPage> createState() => _AutoPaymentSetupPageState();
}

class _AutoPaymentSetupPageState extends ConsumerState<AutoPaymentSetupPage> {
  String _selectedPaymentMethod = 'bank';
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _bankAccountController = TextEditingController();
  final _routingNumberController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

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
      backgroundColor: colors.primaryBackground,
      appBar: _buildAppBar(l10n, colors),
      bottomNavigationBar: const CommonBottomNav(),
      body: SafeArea(
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n, DynamicAppColors colors) {
    return AppBar(
      backgroundColor: colors.primaryBackground,
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
        'Auto Payment Setup',
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceCards,
            colors.luxuryGradientStart,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.success.withValues(alpha: 0.2),
                      colors.success.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.payment_outlined,
                  color: colors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Automatic Payments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Set up automatic rent payments to never miss a due date. Your payment information is encrypted and secure.',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector(AppLocalizations l10n, DynamicAppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
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
                'Bank Account',
                Icons.account_balance_outlined,
                'bank',
                'ACH Transfer',
                colors,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPaymentMethodCard(
                'Credit/Debit Card',
                Icons.credit_card_outlined,
                'card',
                'Instant Payment',
                colors,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(String title, IconData icon, String value, String subtitle, DynamicAppColors colors) {
    final isSelected = _selectedPaymentMethod == value;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedPaymentMethod = value);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected 
                ? [colors.primaryAccent.withValues(alpha: 0.1), colors.primaryAccent.withValues(alpha: 0.05)]
                : [colors.surfaceCards, colors.surfaceCards],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.primaryAccent : colors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? colors.primaryAccent.withValues(alpha: 0.1)
                    : colors.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? colors.primaryAccent : colors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
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
            'Bank Account Information',
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
              labelText: 'Account Number',
              hintText: 'Enter your bank account number',
              prefixIcon: Icon(Icons.account_balance_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Account number is required';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _routingNumberController,
            decoration: InputDecoration(
              labelText: 'Routing Number',
              hintText: 'Enter your bank routing number',
              prefixIcon: Icon(Icons.numbers_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Routing number is required';
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
            'Card Information',
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
              labelText: 'Cardholder Name',
              hintText: 'Enter name on card',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Cardholder name is required';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cardNumberController,
            decoration: InputDecoration(
              labelText: 'Card Number',
              hintText: '1234 5678 9012 3456',
              prefixIcon: Icon(Icons.credit_card_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Card number is required';
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
                    labelText: 'Expiry Date',
                    hintText: 'MM/YY',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Expiry date is required';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'CVV is required';
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          if (_formKey.currentState?.validate() ?? false) {
            _showSetupConfirmation(context, colors);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primaryAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          'Set Up Auto Payment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
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
                  'Secure & Encrypted',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your payment information is encrypted with bank-level security. You can modify or cancel auto payments anytime.',
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: colors.success),
            const SizedBox(width: 8),
            Text('Setup Complete'),
          ],
        ),
        content: Text(
          'Your automatic payment has been set up successfully. You will receive a confirmation email shortly.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop(); // Go back to previous page
            },
            child: Text(
              'Done',
              style: TextStyle(color: colors.primaryAccent),
            ),
          ),
        ],
      ),
    );
  }
}
