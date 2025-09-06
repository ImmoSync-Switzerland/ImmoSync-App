import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:immosync/core/providers/dynamic_colors_provider.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/subscription/domain/models/subscription.dart';
import 'package:immosync/features/subscription/presentation/providers/subscription_providers.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immosync/core/config/db_config.dart';

class SubscriptionPaymentPage extends ConsumerStatefulWidget {
  final SubscriptionPlan plan;
  final bool isYearly;

  const SubscriptionPaymentPage({
    super.key,
    required this.plan,
    required this.isYearly,
  });

  @override
  ConsumerState<SubscriptionPaymentPage> createState() =>
      _SubscriptionPaymentPageState();
}

class _SubscriptionPaymentPageState
    extends ConsumerState<SubscriptionPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  CardFieldInputDetails? _cardFieldInputDetails;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;

    final price = widget.isYearly
        ? widget.plan.yearlyPrice.toDouble()
        : widget.plan.monthlyPrice.toDouble();
    final savings = widget.isYearly
        ? (widget.plan.monthlyPrice * 12) - widget.plan.yearlyPrice
        : 0;

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        title: Text(
          l10n.completePayment,
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

  Widget _buildPlanSummary(double price, double savings,
      DynamicAppColors colors, AppLocalizations l10n) {
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
                    widget.isYearly ? l10n.perYearSuffix : l10n.perMonthSuffix,
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
                    l10n.youSavePerYear(savings.toStringAsFixed(2)),
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
            l10n.includedFeatures,
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

  Widget _buildPaymentMethodSection(
      DynamicAppColors colors, AppLocalizations l10n) {
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
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surfaceCards,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderLight),
          ),
          child: Column(
            children: [
              // Platform-aware payment field
              _buildPlatformAwarePaymentField(colors, l10n),
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
                      l10n.paymentInfoSecure,
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

  Widget _buildPlatformAwarePaymentField(
      DynamicAppColors colors, AppLocalizations l10n) {
    // Check if we're on a supported platform for CardField
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        kIsWeb) {
      try {
        return CardField(
          onCardChanged: (card) {
            setState(() {
              _cardFieldInputDetails = card;
            });
          },
        );
      } catch (e) {
        // If CardField fails, fall back to the desktop UI
        return _buildDesktopPaymentUI(colors);
      }
    } else {
      // For desktop platforms, show alternative payment UI
      return _buildDesktopPaymentUI(colors);
    }
  }

  Widget _buildDesktopPaymentUI(DynamicAppColors colors) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primaryAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primaryAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.desktop_windows_outlined,
            size: 48,
            color: colors.primaryAccent,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.desktopPaymentNotSupported,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.desktopPaymentUseWebOrMobile,
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openWebVersion(),
                  icon: const Icon(Icons.web, size: 18),
                  label: Text(l10n.openWebVersion),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: Text(l10n.back),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    side: BorderSide(color: colors.borderLight),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openWebVersion() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isProcessing = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create checkout session on backend
      final response = await http.post(
        Uri.parse('${DbConfig.apiUrl}/payments/create-subscription-checkout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'planId': widget.plan.id,
          'isYearly': widget.isYearly,
          'userId': user.id,
          'successUrl': 'immolink://subscription-success',
          'cancelUrl': 'immolink://subscription-cancel',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final checkoutUrl = data['checkoutUrl'] as String;

        // Open Stripe checkout in browser
        if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
          await launchUrl(Uri.parse(checkoutUrl),
              mode: LaunchMode.externalApplication);

          // Show message to user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.redirectingToSecurePaymentPage),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          throw Exception('Unable to open checkout URL');
        }
      } else {
        throw Exception('Failed to create checkout session: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening payment page: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
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
            l10n.subscriptionTerms,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.subscriptionBulletAutoRenews(widget.isYearly ? l10n.yearlyInterval : l10n.monthlyInterval)}\n'
            '${l10n.subscriptionBulletCancelAnytime}\n'
            '${l10n.subscriptionBulletRefundPolicy}\n'
            '${l10n.subscriptionBulletAgreeTerms}',
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

  Widget _buildBottomBar(
      double price, DynamicAppColors colors, AppLocalizations l10n) {
    final bool isSupported = _isPlatformSupported();
    final bool canPay = isSupported
        ? (_cardFieldInputDetails?.complete == true && !_isProcessing)
        : !_isProcessing;

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
                l10n.total,
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
                      _isPlatformSupported()
                          ? l10n.subscribeNow
                          : l10n.continueOnWeb,
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

  bool _isPlatformSupported() {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        kIsWeb;
  }

  void _handlePayment() async {
    final l10n = AppLocalizations.of(context)!;
    // For unsupported platforms, redirect to web
    if (!_isPlatformSupported()) {
      _openWebVersion();
      return;
    }

    if (_cardFieldInputDetails?.complete != true) return;

    setState(() => _isProcessing = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create payment intent
      final price =
          widget.isYearly ? widget.plan.yearlyPrice : widget.plan.monthlyPrice;
      final clientSecret = await ref
          .read(subscriptionNotifierProvider.notifier)
          .createPaymentIntent(
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
          content: Text(l10n.paymentFailed(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(l10n.welcome),
          ],
        ),
        content: Text(
          l10n.subscriptionActivated(widget.plan.name),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
            child: Text(l10n.getStarted),
          ),
        ],
      ),
    );
  }
}
