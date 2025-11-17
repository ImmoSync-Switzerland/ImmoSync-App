import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/core/providers/dynamic_colors_provider.dart';
import 'package:immosync/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionManagementPage extends ConsumerWidget {
  const SubscriptionManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final subscriptionAsync = ref.watch(userSubscriptionProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Subscription'),
          backgroundColor: colors.primaryBackground,
        ),
        body: const Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        backgroundColor: colors.primaryBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.invalidate(userSubscriptionProvider);
            },
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: colors.createGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userSubscriptionProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: subscriptionAsync.when(
              data: (subscription) {
                if (subscription == null) {
                  return _buildNoSubscription(context, colors, l10n);
                }
                return _buildSubscriptionDetails(
                    context, colors, l10n, subscription, ref);
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) =>
                  _buildErrorState(context, colors, error.toString()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoSubscription(
      BuildContext context, dynamic colors, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.credit_card_off,
              size: 80,
              color: colors.warning,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'No Active Subscription',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              letterSpacing: -0.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'You currently don\'t have an active subscription.',
            style: TextStyle(
              fontSize: 16,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              // Navigate to subscription plans page
              Navigator.pushNamed(context, '/subscription-plans');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryAccent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'View Plans',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionDetails(
    BuildContext context,
    dynamic colors,
    AppLocalizations l10n,
    dynamic subscription,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: subscription.isActive
                  ? [
                      colors.success.withValues(alpha: 0.9),
                      colors.success.withValues(alpha: 0.7)
                    ]
                  : [
                      colors.error.withValues(alpha: 0.9),
                      colors.error.withValues(alpha: 0.7)
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: subscription.isActive
                    ? colors.success.withValues(alpha: 0.3)
                    : colors.error.withValues(alpha: 0.3),
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
                  Icon(
                    subscription.isActive ? Icons.check_circle : Icons.warning,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      subscription.isActive
                          ? 'Subscription Active'
                          : 'Subscription ${subscription.status}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildInfoRow(
                Icons.credit_card,
                'Plan',
                subscription.planId.toUpperCase(),
                Colors.white,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.payment,
                'Amount',
                'CHF ${subscription.amount.toStringAsFixed(2)}',
                Colors.white,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.calendar_today,
                'Billing',
                subscription.billingInterval == 'month' ? 'Monthly' : 'Yearly',
                Colors.white,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.event,
                'Next Billing',
                _formatDate(subscription.nextBillingDate),
                Colors.white,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Details Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surfaceCards,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subscription Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailRow(
                'Subscription ID',
                subscription.stripeSubscriptionId,
                colors,
              ),
              const Divider(height: 32),
              _buildDetailRow(
                'Customer ID',
                subscription.stripeCustomerId ?? 'N/A',
                colors,
              ),
              const Divider(height: 32),
              _buildDetailRow(
                'Started',
                _formatDate(subscription.startDate),
                colors,
              ),
              if (subscription.endDate != null) ...[
                const Divider(height: 32),
                _buildDetailRow(
                  'Ends',
                  _formatDate(subscription.endDate!),
                  colors,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Actions
        if (subscription.isActive) ...[
          _buildActionButton(
            context,
            colors,
            'Manage Subscription',
            Icons.settings,
            () async {
              await _openCustomerPortal(context, ref, subscription);
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            colors,
            'Cancel Subscription',
            Icons.cancel,
            () {
              _showCancelDialog(context, colors, ref, subscription.id);
            },
            isDestructive: true,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color.withValues(alpha: 0.8), size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.8),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, dynamic colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    dynamic colors,
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool isDestructive = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive ? colors.error : colors.primaryAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, dynamic colors, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colors.error),
          const SizedBox(height: 16),
          Text(
            'Error Loading Subscription',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
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

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  Future<void> _openCustomerPortal(
    BuildContext context,
    WidgetRef ref,
    dynamic subscription,
  ) async {
    try {
      final customerId = subscription.stripeCustomerId;
      if (customerId == null || customerId.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No customer ID found')),
          );
        }
        return;
      }

      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Opening Stripe Portal...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final service = ref.read(subscriptionServiceProvider);
      final portalUrl = await service.createCustomerPortalSession(
        customerId: customerId,
        returnUrl: 'immosync://subscription/management',
      );

      print('[SubscriptionManagement] Opening portal URL: $portalUrl');

      // Launch URL in browser
      final uri = Uri.parse(portalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch portal URL');
      }
    } catch (e) {
      print('[SubscriptionManagement][ERROR] Failed to open portal: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open portal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCancelDialog(BuildContext context, dynamic colors, WidgetRef ref,
      String subscriptionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription?'),
        content: const Text(
          'Are you sure you want to cancel your subscription? You will lose access to premium features at the end of the current billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Implement subscription cancellation
              try {
                final service = ref.read(subscriptionServiceProvider);
                await service.cancelSubscription(subscriptionId);
                ref.invalidate(userSubscriptionProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Subscription cancelled')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
  }
}
