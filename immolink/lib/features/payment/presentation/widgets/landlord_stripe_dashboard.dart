import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/payment/presentation/providers/payment_providers.dart';
import 'package:immosync/features/payment/domain/services/stripe_connect_payment_service.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/core/providers/dynamic_colors_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget for landlords to manage their Stripe Connect payments
class LandlordStripeConnectDashboard extends ConsumerWidget {
  const LandlordStripeConnectDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(dynamicColorsProvider);
    final user = ref.watch(currentUserProvider);
    final accountAsync = ref.watch(stripeConnectAccountProvider);
    final balanceAsync = ref.watch(landlordBalanceProvider);
    final paymentsAsync = ref.watch(landlordConnectPaymentsProvider);

    if (user == null) {
      return const Center(child: Text('Please log in'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Dashboard'),
        backgroundColor: colors.primaryBackground,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(stripeConnectAccountProvider);
          ref.invalidate(landlordBalanceProvider);
          ref.invalidate(landlordConnectPaymentsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stripe Connect Account Status
              accountAsync.when(
                data: (account) => _buildAccountStatusCard(
                  context,
                  colors,
                  account.chargesEnabled,
                  account.payoutsEnabled,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _buildOnboardingPrompt(context, ref, colors),
              ),
              const SizedBox(height: 20),

              // Account Balance
              balanceAsync.when(
                data: (balance) => _buildBalanceCard(context, colors, balance),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Error loading balance: $error'),
              ),
              const SizedBox(height: 20),

              // Recent Payments
              Text(
                'Recent Payments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              paymentsAsync.when(
                data: (payments) => payments.isEmpty
                    ? const Center(child: Text('No payments yet'))
                    : Column(
                        children: payments
                            .map((payment) =>
                                _buildPaymentCard(context, colors, payment))
                            .toList(),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Error loading payments: $error'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountStatusCard(
    BuildContext context,
    DynamicAppColors colors,
    bool chargesEnabled,
    bool payoutsEnabled,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            chargesEnabled && payoutsEnabled
                ? Colors.green.shade400
                : Colors.orange.shade400,
            chargesEnabled && payoutsEnabled
                ? Colors.green.shade600
                : Colors.orange.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                chargesEnabled && payoutsEnabled
                    ? Icons.check_circle
                    : Icons.warning,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  chargesEnabled && payoutsEnabled
                      ? 'Account Active'
                      : 'Setup Required',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusRow('Accept Payments', chargesEnabled),
          const SizedBox(height: 8),
          _buildStatusRow('Receive Payouts', payoutsEnabled),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool enabled) {
    return Row(
      children: [
        Icon(
          enabled ? Icons.check : Icons.close,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildOnboardingPrompt(
    BuildContext context,
    WidgetRef ref,
    DynamicAppColors colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance,
            size: 48,
            color: colors.primaryAccent,
          ),
          const SizedBox(height: 16),
          Text(
            'Set up your payment account',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect your bank account to start receiving payments from tenants',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _startOnboarding(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryAccent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Start Setup'),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    DynamicAppColors colors,
    AccountBalance balance,
  ) {
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
            'Account Balance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${balance.currency.toUpperCase()} ${balance.available.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.success,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Pending',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${balance.currency.toUpperCase()} ${balance.pending.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(
    BuildContext context,
    DynamicAppColors colors,
    ConnectPayment payment,
  ) {
    final statusColor = _getStatusColor(payment.status, colors);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getPaymentIcon(payment.paymentType),
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.description ?? payment.paymentType.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(payment.createdAt),
                  style: TextStyle(
                    fontSize: 12,
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
                '${payment.currency.toUpperCase()} ${payment.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  payment.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, DynamicAppColors colors) {
    switch (status.toLowerCase()) {
      case 'succeeded':
      case 'completed':
        return colors.success;
      case 'pending':
      case 'processing':
        return colors.warning;
      case 'failed':
      case 'canceled':
        return colors.error;
      default:
        return colors.textSecondary;
    }
  }

  IconData _getPaymentIcon(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'rent':
        return Icons.home;
      case 'deposit':
        return Icons.account_balance_wallet;
      case 'maintenance':
        return Icons.build;
      default:
        return Icons.payment;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _startOnboarding(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final notifier = ref.read(stripeConnectNotifierProvider.notifier);

    try {
      // First, create or get the Connect account
      final account = await notifier.createConnectAccount(
        landlordId: user.id,
        email: user.email,
      );

      if (!context.mounted) return;

      if (account != null) {
        // Generate onboarding link
        // Note: Stripe requires HTTP/HTTPS URLs, not deep links
        final onboardingUrl = await notifier.createOnboardingLink(
          accountId: account.accountId,
          refreshUrl: 'https://immosync.ch/connect/refresh',
          returnUrl: 'https://immosync.ch/connect/return',
        );

        if (!context.mounted) return;

        if (onboardingUrl != null) {
          // Open onboarding URL in browser
          final uri = Uri.parse(onboardingUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening Stripe Connect setup...'),
                ),
              );
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not open browser'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
