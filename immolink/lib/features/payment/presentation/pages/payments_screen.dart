import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/payment/domain/services/stripe_connect_payment_service.dart';
import 'package:immosync/features/payment/presentation/providers/payment_providers.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  Future<void> _startOnboarding() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final notifier = ref.read(stripeConnectNotifierProvider.notifier);
    if (!mounted) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final account = await notifier.createConnectAccount(
        landlordId: user.id,
        email: user.email,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      if (account == null) {
        _showErrorSnackBar(
          'Failed to create Stripe account. Please try again.',
        );
        return;
      }

      final onboardingUrl = await notifier.createOnboardingLink(
        accountId: account.accountId,
        refreshUrl: 'https://immosync.ch/connect/refresh',
        returnUrl: 'https://immosync.ch/connect/return',
      );

      if (!mounted) return;

      if (onboardingUrl == null) {
        _showErrorSnackBar('Failed to create onboarding link.');
        return;
      }

      final uri = Uri.parse(onboardingUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Could not open browser');
      }
    } catch (_) {
      if (!mounted) return;
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}
      _showErrorSnackBar('Setup failed. Please try again.');
    }
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

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const _DeepNavyBackground(),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _handleBack,
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Payments',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08)),
                        ),
                      ),
                      child: const TabBar(
                        indicatorColor: Color(0xFF38BDF8),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        indicatorWeight: 3,
                        tabs: [
                          Tab(text: 'Overview'),
                          Tab(text: 'Transactions'),
                          Tab(text: 'Payouts'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: user == null
                        ? const Center(
                            child: Text(
                              'Please log in',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : TabBarView(
                            children: [
                              _OverviewTab(onStartSetup: _startOnboarding),
                              const _TransactionsTab(),
                              const _PayoutsTab(),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.onStartSetup});

  final Future<void> Function() onStartSetup;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final accountAsync = ref.watch(stripeConnectAccountProvider);
        final balanceAsync = ref.watch(landlordBalanceProvider);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          child: Column(
            children: [
              const SizedBox(height: 10),
              accountAsync.when(
                data: (account) {
                  if (!account.chargesEnabled || !account.payoutsEnabled) {
                    return _SetupHeroCard(
                      title: account.detailsSubmitted
                          ? 'Complete Your Setup'
                          : 'Setup Payment Account',
                      subtitle: account.detailsSubmitted
                          ? 'Complete the onboarding process to activate your payment account.'
                          : 'Connect your bank account to start receiving payments from tenants.',
                      onStartSetup: onStartSetup,
                    );
                  }

                  return Column(
                    children: [
                      _BentoCard(
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E)
                                    .withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.verified_rounded,
                                color: Color(0xFF22C55E),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stripe account active',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'You can accept payments and receive payouts.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      balanceAsync.when(
                        data: (balance) => _BalanceCard(balance: balance),
                        loading: () => const _BentoCard(
                          child: SizedBox(
                            height: 70,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                        error: (e, _) => const _BentoCard(
                          child: Text(
                            'Could not load balance.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const _BentoCard(
                  child: SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (e, _) => _SetupHeroCard(
                  title: 'Setup Payment Account',
                  subtitle:
                      'Connect your bank account to start receiving payments from tenants.',
                  onStartSetup: onStartSetup,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final paymentsAsync = ref.watch(landlordConnectPaymentsProvider);

        return paymentsAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: _BentoCard(
                  child: Text(
                    'No transactions yet.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final payment = items[index];
                const amountColor = Color(0xFF22C55E);
                final subtitle = _formatShortTimestamp(payment.createdAt);
                final title = _paymentTitle(payment);
                final amountLabel =
                    '+${_formatMoney(payment.amount, payment.currency)}';

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == items.length - 1 ? 0 : 10,
                  ),
                  child: _BentoCard(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.payments_outlined,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          amountLabel,
                          style: const TextStyle(
                            color: amountColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
            child: _BentoCard(
              child: Text(
                'Could not load transactions.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PayoutsTab extends StatelessWidget {
  const _PayoutsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final payoutsAsync = ref.watch(landlordPayoutsProvider);

        return payoutsAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: _BentoCard(
                  child: Text(
                    'No payouts yet.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final payout = items[index];
                final subtitle = _formatShortTimestamp(payout.createdAt);
                final title = payout.status.isEmpty
                    ? 'Payout'
                    : 'Payout · ${payout.status}';
                final amountLabel =
                    '-${_formatMoney(payout.amount, payout.currency)}';

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == items.length - 1 ? 0 : 10,
                  ),
                  child: _BentoCard(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          amountLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
            child: _BentoCard(
              child: Text(
                'Could not load payouts.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SetupHeroCard extends StatelessWidget {
  const _SetupHeroCard({
    required this.title,
    required this.subtitle,
    required this.onStartSetup,
  });

  final String title;
  final String subtitle;
  final Future<void> Function() onStartSetup;

  @override
  Widget build(BuildContext context) {
    return _BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF38BDF8).withValues(alpha: 0.16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.22),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance,
              size: 40,
              color: Color(0xFF38BDF8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          _GradientButton(
            label: 'Start Setup',
            onTap: () async {
              await onStartSetup();
            },
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final AccountBalance balance;

  @override
  Widget build(BuildContext context) {
    return _BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Balance',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BalanceMetric(
                  label: 'Available',
                  value: _formatMoney(balance.available, balance.currency),
                  valueColor: const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BalanceMetric(
                  label: 'Pending',
                  value: _formatMoney(balance.pending, balance.currency),
                  valueColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  const _BalanceMetric({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF38BDF8), Color(0xFF06B6D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const radius = 16.0;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(radius - 1),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 18,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DeepNavyBackground extends StatelessWidget {
  const _DeepNavyBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A1128), Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: -90,
          left: -50,
          child: _GlowCircle(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.28)),
        ),
        Positioned(
          bottom: -70,
          right: -30,
          child: _GlowCircle(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.22)),
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
          stops: const [0.0, 1.0],
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
        child: const SizedBox.expand(),
      ),
    );
  }
}

String _formatShortTimestamp(DateTime dateTime) {
  return DateFormat('MMM d · HH:mm').format(dateTime);
}

String _formatMoney(double amount, String currency) {
  final code = currency.toUpperCase();
  final formatted = NumberFormat.currency(
    name: code,
    symbol: code == 'CHF' ? 'CHF ' : '$code ',
    decimalDigits: 2,
  ).format(amount);
  return formatted;
}

String _paymentTitle(ConnectPayment payment) {
  final type = payment.paymentType.trim();
  if (type.isEmpty) return 'Payment';
  final normalized = type[0].toUpperCase() + type.substring(1);
  if (payment.status.isEmpty) return normalized;
  return '$normalized · ${payment.status}';
}
