import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:immolink/core/providers/dynamic_colors_provider.dart';
import 'package:immolink/features/auth/presentation/providers/auth_provider.dart';
import 'package:immolink/features/subscription/domain/models/subscription.dart';
import 'package:immolink/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class SubscriptionPaymentPage extends ConsumerStatefulWidget {
  final SubscriptionPlan plan;
  final bool isYearly;

  const SubscriptionPaymentPage({
    super.key,
    required this.plan,
    required this.isYearly,
  });

  @override
  ConsumerState<SubscriptionPaymentPage> createState() => _SubscriptionPaymentPageState();
}

class _SubscriptionPaymentPageState extends ConsumerState<SubscriptionPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  CardFieldInputDetails? _cardFieldInputDetails;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;
    
    final price = widget.isYearly ? widget.plan.yearlyPrice.toDouble() : widget.plan.monthlyPrice.toDouble();
    final savings = widget.isYearly ? (widget.plan.monthlyPrice * 12) - widget.plan.yearlyPrice : 0;

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Complete Payment',
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Plan summary
            _buildPlanSummary(price, savings.toDouble(), colors, l10n),
            const SizedBox(height: 32),
            
            // Payment method section
            _buildPaymentMethodSection(colors, l10n),
            const SizedBox(height: 32),
            
            // Terms and conditions
            _buildTermsSection(colors, l10n),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(price, colors, l10n),
    );
  }

  Widget _buildPlanSummary(double price, double savings, DynamicAppColors colors, AppLocalizations l10n) {
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.plan.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.plan.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: colors.primaryAccent,
                    ),
                  ),
                  Text(
                    widget.isYearly ? '/year' : '/month',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          if (widget.isYearly && savings > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.savings_outlined,
                    color: colors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'You save \$${savings.toStringAsFixed(2)} per year',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          Text(
            'Included features:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.plan.features.take(4).map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.check,
                  size: 14,
                  color: colors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feature,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(DynamicAppColors colors, AppLocalizations l10n) {
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
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surfaceCards,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderLight),
          ),
          child: Column(
            children: [
              CardField(
                onCardChanged: (card) {
                  setState(() {
                    _cardFieldInputDetails = card;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.security,
                    size: 16,
                    color: colors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your payment information is encrypted and secure',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTermsSection(DynamicAppColors colors, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCards.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderLight.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subscription Terms',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Your subscription will automatically renew ${widget.isYearly ? 'yearly' : 'monthly'}\n'
            '• You can cancel anytime from your account settings\n'
            '• Refunds are available within 30 days of purchase\n'
            '• By subscribing, you agree to our Terms of Service',
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(double price, DynamicAppColors colors, AppLocalizations l10n) {
    final canPay = _cardFieldInputDetails?.complete == true && !_isProcessing;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        border: Border(
          top: BorderSide(color: colors.borderLight),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                '\$${price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colors.primaryAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canPay ? _handlePayment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Subscribe Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePayment() async {
    if (_cardFieldInputDetails?.complete != true) return;

    setState(() => _isProcessing = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create payment intent
      final price = widget.isYearly ? widget.plan.yearlyPrice : widget.plan.monthlyPrice;
      final clientSecret = await ref.read(subscriptionNotifierProvider.notifier).createPaymentIntent(
        amount: price,
        currency: 'usd',
      );

      // Confirm payment
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(),
          ),
        ),
      );

      // Create subscription
      await ref.read(subscriptionNotifierProvider.notifier).createSubscription(
        userId: user.id,
        planId: widget.plan.id,
        billingInterval: widget.isYearly ? 'yearly' : 'monthly',
        paymentMethodId: _cardFieldInputDetails!.last4!,
      );

      // Success
      _showSuccessDialog();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text('Welcome!'),
          ],
        ),
        content: Text(
          'Your subscription to ${widget.plan.name} has been activated successfully. You can now access all premium features.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}
