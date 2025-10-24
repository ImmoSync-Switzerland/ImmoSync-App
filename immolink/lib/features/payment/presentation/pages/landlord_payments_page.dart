import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/payment/presentation/providers/payment_providers.dart';
import 'package:immosync/features/payment/domain/services/stripe_connect_payment_service.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/core/providers/dynamic_colors_provider.dart';
import 'package:immosync/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class LandlordPaymentsPage extends ConsumerStatefulWidget {
  const LandlordPaymentsPage({super.key});

  @override
  ConsumerState<LandlordPaymentsPage> createState() => _LandlordPaymentsPageState();
}

class _LandlordPaymentsPageState extends ConsumerState<LandlordPaymentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRequestingPayout = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final accountAsync = ref.watch(stripeConnectAccountProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.payments),
          backgroundColor: colors.primaryBackground,
        ),
        body: Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.payments),
        backgroundColor: colors.primaryBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.invalidate(stripeConnectAccountProvider);
              ref.invalidate(landlordBalanceProvider);
              ref.invalidate(landlordConnectPaymentsProvider);
            },
            tooltip: l10n.refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primaryAccent,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primaryAccent,
          tabs: [
            Tab(text: l10n.overview),
            Tab(text: l10n.payments),
            Tab(text: l10n.payouts),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: colors.createGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: accountAsync.when(
          data: (account) {
            if (!account.chargesEnabled || !account.payoutsEnabled) {
              return _buildOnboardingPrompt(context, account);
            }
            return TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(account),
                _buildPaymentsTab(),
                _buildPayoutsTab(),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildOnboardingPrompt(context, null),
        ),
      ),
    );
  }

  Widget _buildOnboardingPrompt(BuildContext context, StripeConnectAccount? account) {
    final colors = ref.watch(dynamicColorsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(stripeConnectAccountProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primaryAccent.withOpacity(0.1),
                    colors.primaryAccent.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.account_balance,
                size: 80,
                color: colors.primaryAccent,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              account == null ? 'Setup Payment Account' : 'Complete Your Setup',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              account == null
                  ? 'Connect your bank account to start receiving payments from tenants'
                  : 'Complete the onboarding process to activate your payment account',
              style: TextStyle(
                fontSize: 16,
                color: colors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (account != null) ...[
              _buildSetupStatusCard(account),
              const SizedBox(height: 24),
            ],
            ElevatedButton(
              onPressed: () => _startOnboarding(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.rocket_launch, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    account == null ? 'Start Setup' : 'Continue Setup',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildFeaturesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupStatusCard(StripeConnectAccount account) {
    final colors = ref.watch(dynamicColorsProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        children: [
          _buildStatusRow(
            'Account Created',
            true,
            colors,
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            'Bank Account Connected',
            account.detailsSubmitted,
            colors,
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            'Accept Payments',
            account.chargesEnabled,
            colors,
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            'Receive Payouts',
            account.payoutsEnabled,
            colors,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool completed, DynamicAppColors colors) {
    return Row(
      children: [
        Icon(
          completed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: completed ? colors.success : colors.textTertiary,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: completed ? colors.textPrimary : colors.textSecondary,
              fontWeight: completed ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    final colors = ref.watch(dynamicColorsProvider);

    final features = [
      {'icon': Icons.credit_card, 'title': 'Accept Card Payments', 'desc': 'Visa, Mastercard, and more'},
      {'icon': Icons.account_balance, 'title': 'Bank Transfers', 'desc': 'Direct to your account'},
      {'icon': Icons.shield, 'title': 'Secure & Encrypted', 'desc': 'PCI-compliant processing'},
      {'icon': Icons.speed, 'title': 'Fast Payouts', 'desc': 'Daily automatic transfers'},
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  feature['icon'] as IconData,
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
                      feature['title'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      feature['desc'] as String,
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
        );
      }).toList(),
    );
  }

  Widget _buildOverviewTab(StripeConnectAccount account) {
    final colors = ref.watch(dynamicColorsProvider);
    final balanceAsync = ref.watch(landlordBalanceProvider);
    final paymentsAsync = ref.watch(landlordConnectPaymentsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(landlordBalanceProvider);
        ref.invalidate(landlordConnectPaymentsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAccountStatusCard(account),
            const SizedBox(height: 20),
            balanceAsync.when(
              data: (balance) => _buildBalanceCard(balance),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildErrorCard('Failed to load balance'),
            ),
            const SizedBox(height: 20),
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
              data: (payments) {
                if (payments.isEmpty) {
                  return _buildEmptyState('No payments yet');
                }
                return Column(
                  children: payments.take(5).map((payment) {
                    return _buildPaymentCard(payment);
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildErrorCard('Failed to load payments'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountStatusCard(StripeConnectAccount account) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            account.chargesEnabled && account.payoutsEnabled
                ? Colors.green.shade400
                : Colors.orange.shade400,
            account.chargesEnabled && account.payoutsEnabled
                ? Colors.green.shade600
                : Colors.orange.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (account.chargesEnabled && account.payoutsEnabled
                    ? Colors.green
                    : Colors.orange)
                .withOpacity(0.3),
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
                account.chargesEnabled && account.payoutsEnabled
                    ? Icons.check_circle
                    : Icons.pending,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  account.chargesEnabled && account.payoutsEnabled
                      ? 'Account Active'
                      : 'Setup In Progress',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCapabilityRow('Accept Payments', account.chargesEnabled),
          const SizedBox(height: 12),
          _buildCapabilityRow('Receive Payouts', account.payoutsEnabled),
          const SizedBox(height: 12),
          _buildCapabilityRow('Details Submitted', account.detailsSubmitted),
        ],
      ),
    );
  }

  Widget _buildCapabilityRow(String label, bool enabled) {
    return Row(
      children: [
        Icon(
          enabled ? Icons.check_circle_outline : Icons.access_time,
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

  Widget _buildBalanceCard(AccountBalance balance) {
    final colors = ref.watch(dynamicColorsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Account Balance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              IconButton(
                icon: Icon(Icons.info_outline, color: colors.textSecondary),
                onPressed: () {
                  _showBalanceInfoDialog();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${balance.currency.toUpperCase()} ${balance.available.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colors.success,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: colors.borderLight,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${balance.currency.toUpperCase()} ${balance.pending.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (balance.available > 0) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRequestingPayout ? null : () => _requestPayout(balance),
                icon: _isRequestingPayout
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isRequestingPayout ? 'Processing...' : 'Request Payout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    final paymentsAsync = ref.watch(landlordConnectPaymentsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(landlordConnectPaymentsProvider);
      },
      child: paymentsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return _buildEmptyState('No payments yet');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              return _buildPaymentCard(payments[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: _buildErrorCard('Failed to load payments')),
      ),
    );
  }

  Widget _buildPayoutsTab() {
    final payoutsAsync = ref.watch(landlordPayoutsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(landlordPayoutsProvider);
      },
      child: payoutsAsync.when(
        data: (payouts) {
          if (payouts.isEmpty) {
            return _buildEmptyState('No payouts yet');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: payouts.length,
            itemBuilder: (context, index) {
              return _buildPayoutCard(payouts[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: _buildErrorCard('Failed to load payouts')),
      ),
    );
  }

  Widget _buildPaymentCard(ConnectPayment payment) {
    final colors = ref.watch(dynamicColorsProvider);
    final statusColor = _getStatusColor(payment.status, colors);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getPaymentIcon(payment.paymentType),
              color: statusColor,
              size: 28,
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
                    fontSize: 16,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(payment.createdAt),
                  style: TextStyle(
                    fontSize: 13,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  payment.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
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

  Widget _buildPayoutCard(Payout payout) {
    final colors = ref.watch(dynamicColorsProvider);
    final statusColor = _getPayoutStatusColor(payout.status, colors);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance,
              color: statusColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payout.description ?? 'Payout',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Arrives: ${payout.arrivalDate != null ? _formatDate(payout.arrivalDate!) : 'Pending'}',
                  style: TextStyle(
                    fontSize: 13,
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
                '${payout.currency.toUpperCase()} ${payout.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  payout.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
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

  Widget _buildEmptyState(String message) {
    final colors = ref.watch(dynamicColorsProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: colors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    final colors = ref.watch(dynamicColorsProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
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

  Color _getPayoutStatusColor(String status, DynamicAppColors colors) {
    switch (status.toLowerCase()) {
      case 'paid':
        return colors.success;
      case 'pending':
      case 'in_transit':
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
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _startOnboarding(BuildContext context) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final notifier = ref.read(stripeConnectNotifierProvider.notifier);

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // First, create or get the Connect account
      var account = await notifier.createConnectAccount(
        landlordId: user.id,
        email: user.email,
      );

      if (account == null) {
        if (mounted) Navigator.of(context).pop();
        _showErrorSnackBar('Failed to create account');
        return;
      }

      // Generate onboarding link
      final onboardingUrl = await notifier.createOnboardingLink(
        accountId: account.accountId,
        refreshUrl: 'immosync://stripe-refresh',
        returnUrl: 'immosync://stripe-return',
      );

      if (mounted) Navigator.of(context).pop();

      if (onboardingUrl != null) {
        // Try to launch URL
        final uri = Uri.parse(onboardingUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Opening Stripe Connect setup...'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          _showErrorSnackBar('Could not open browser');
        }
      } else {
        _showErrorSnackBar('Failed to create onboarding link');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorSnackBar('Error: $e');
      }
    }
  }

  Future<void> _requestPayout(AccountBalance balance) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildPayoutDialog(balance),
    );

    if (confirmed != true) return;

    setState(() {
      _isRequestingPayout = true;
    });

    try {
      final notifier = ref.read(stripeConnectNotifierProvider.notifier);
      final payout = await notifier.createPayout(
        landlordId: user.id,
        amount: balance.available,
        currency: balance.currency,
        description: 'Payout request',
      );

      if (payout != null) {
        ref.invalidate(landlordBalanceProvider);
        ref.invalidate(landlordPayoutsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payout requested: ${balance.currency.toUpperCase()} ${balance.available.toStringAsFixed(2)}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showErrorSnackBar('Failed to create payout');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingPayout = false;
        });
      }
    }
  }

  Widget _buildPayoutDialog(AccountBalance balance) {
    final colors = ref.watch(dynamicColorsProvider);

    return AlertDialog(
      title: const Text('Request Payout'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transfer your available balance to your bank account?'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount:'),
                    Text(
                      '${balance.currency.toUpperCase()} ${balance.available.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Arrival:',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                    Text(
                      '2-3 business days',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primaryAccent,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  void _showBalanceInfoDialog() {
    final colors = ref.watch(dynamicColorsProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Balance Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              'Available',
              'Funds ready to be transferred to your bank account',
              Icons.check_circle,
              colors.success,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Pending',
              'Funds waiting to clear (usually 2-3 days)',
              Icons.pending,
              colors.warning,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String desc, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
