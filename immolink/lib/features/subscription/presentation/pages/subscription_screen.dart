import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/features/subscription/domain/models/subscription.dart';
import 'package:immosync/features/subscription/presentation/providers/subscription_providers.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  static const _bgTop = Color(0xFF0A1128);
  static const _bgBottom = Colors.black;
  static const _card = Color(0xFF1C1C1E);

  bool _yearly = false;

  String _formatMoney(double amount) {
    return 'CHF ${amount.toStringAsFixed(2)}';
  }

  String _formatDate(BuildContext context, DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  SubscriptionPlan? _planForSubscription(
    UserSubscription subscription,
    List<SubscriptionPlan> plans,
  ) {
    final direct = plans.where((p) => p.id == subscription.planId);
    if (direct.isNotEmpty) return direct.first;

    final byStripePrice = plans.where(
      (p) =>
          p.stripePriceIdMonthly == subscription.planId ||
          p.stripePriceIdYearly == subscription.planId,
    );
    if (byStripePrice.isNotEmpty) return byStripePrice.first;

    return null;
  }

  SubscriptionPlan? _professionalPlan(List<SubscriptionPlan> plans) {
    final byId = plans.where((p) => p.id.toLowerCase() == 'pro');
    if (byId.isNotEmpty) return byId.first;

    final byPopular = plans.where((p) => p.isPopular);
    if (byPopular.isNotEmpty) return byPopular.first;

    final byName = plans.where(
      (p) =>
          p.name.toLowerCase().contains('professional') ||
          p.name.toLowerCase() == 'pro',
    );
    if (byName.isNotEmpty) return byName.first;

    return null;
  }

  ({String label, Color color}) _statusBadge(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'active') {
      return (label: 'Active', color: const Color(0xFF22C55E));
    }
    if (normalized == 'past_due') {
      return (label: 'Past due', color: const Color(0xFFF59E0B));
    }
    if (normalized == 'canceled') {
      return (label: 'Canceled', color: const Color(0xFFEF4444));
    }
    if (normalized == 'incomplete') {
      return (label: 'Incomplete', color: const Color(0xFFF59E0B));
    }
    return (label: status.isEmpty ? 'Unknown' : status, color: Colors.white54);
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final subscriptionAsync = ref.watch(userSubscriptionProvider);

    final proCycle = _yearly ? '/ year' : '/ month';

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          icon: const Icon(
            Icons.chevron_left,
            color: Colors.white,
            size: 20,
          ),
          tooltip: 'Back',
        ),
        title: const Text(
          'Manage Subscription',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BentoCard(
                    child: _CurrentPlanCard(
                        subscriptionAsync: subscriptionAsync,
                        plansAsync: plansAsync,
                        formatter: _formatMoney,
                        dateFormatter: (date) => _formatDate(context, date),
                        statusBadge: _statusBadge,
                        planForSubscription: _planForSubscription)),
                const SizedBox(height: 16),
                _CycleToggle(
                  yearly: _yearly,
                  onChanged: (value) => setState(() => _yearly = value),
                ),
                const SizedBox(height: 16),
                _BentoCard(
                  child: plansAsync.when(
                    data: (plans) {
                      final proPlan = _professionalPlan(plans);
                      if (proPlan == null) {
                        return const Text(
                          'No plans available.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }

                      final price =
                          _yearly ? proPlan.yearlyPrice : proPlan.monthlyPrice;
                      final priceText = _formatMoney(price);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  proPlan.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              if (proPlan.isPopular) _PopularBadge(),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                priceText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 30,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  proCycle,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            proPlan.description.isEmpty
                                ? 'Best for growing portfolios with automation and advanced tools.'
                                : proPlan.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            height: 1,
                            width: double.infinity,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          const SizedBox(height: 14),
                          if (proPlan.features.isEmpty)
                            const _FeatureItem(
                                text: 'Includes premium features')
                          else
                            ...proPlan.features
                                .take(6)
                                .expand((f) => [
                                      _FeatureItem(text: f),
                                      const SizedBox(height: 10),
                                    ])
                                .toList()
                              ..removeLast(),
                          const SizedBox(height: 16),
                          _GradientButton(
                            label: 'Upgrade Now',
                            onTap: () {
                              context.go(
                                '/subscription/payment',
                                extra: {
                                  'plan': proPlan,
                                  'isYearly': _yearly,
                                },
                              );
                            },
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox(
                      height: 88,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                    error: (error, _) => Text(
                      'Failed to load plans: $error',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({
    required this.subscriptionAsync,
    required this.plansAsync,
    required this.formatter,
    required this.dateFormatter,
    required this.statusBadge,
    required this.planForSubscription,
  });

  final AsyncValue<UserSubscription?> subscriptionAsync;
  final AsyncValue<List<SubscriptionPlan>> plansAsync;
  final String Function(double amount) formatter;
  final String Function(DateTime date) dateFormatter;
  final ({String label, Color color}) Function(String status) statusBadge;
  final SubscriptionPlan? Function(
    UserSubscription subscription,
    List<SubscriptionPlan> plans,
  ) planForSubscription;

  @override
  Widget build(BuildContext context) {
    return subscriptionAsync.when(
      data: (subscription) {
        if (subscription == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Plan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'No active subscription',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: const Text(
                  'Choose a plan below to continue.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );
        }

        return plansAsync.when(
          data: (plans) {
            final plan = planForSubscription(subscription, plans);
            final status = statusBadge(subscription.status);
            final yearly =
                subscription.billingInterval.toLowerCase().contains('year');
            final planName = plan?.name.isNotEmpty == true
                ? plan!.name
                : subscription.planId;
            final amount = plan != null
                ? (yearly ? plan.yearlyPrice : plan.monthlyPrice)
                : subscription.amount;
            final cycleSuffix = yearly ? '/ yr' : '/ mo';
            final priceLabel = '${formatter(amount)} $cycleSuffix';

            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: status.color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: status.color.withValues(alpha: 0.25),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        status.label == 'Active'
                            ? Icons.check_circle_rounded
                            : Icons.info_rounded,
                        color: status.color,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            planName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            status.label,
                            style: TextStyle(
                              color: status.color,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      priceLabel,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Text(
                    'Next billing: ${dateFormatter(subscription.nextBillingDate)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 88,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          error: (error, _) {
            final status = statusBadge(subscription.status);
            final yearly =
                subscription.billingInterval.toLowerCase().contains('year');
            final cycleSuffix = yearly ? '/ yr' : '/ mo';
            final priceLabel = '${formatter(subscription.amount)} $cycleSuffix';

            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: status.color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        status.label == 'Active'
                            ? Icons.check_circle_rounded
                            : Icons.info_rounded,
                        color: status.color,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subscription.planId,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            status.label,
                            style: TextStyle(
                              color: status.color,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      priceLabel,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Text(
                    'Plans unavailable: $error',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      loading: () => const SizedBox(
        height: 88,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      error: (error, _) => Text(
        'Failed to load subscription: $error',
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
          fontSize: 12,
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
    return Container(
      decoration: BoxDecoration(
        color: _SubscriptionScreenState._card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }
}

class _CycleToggle extends StatelessWidget {
  const _CycleToggle({required this.yearly, required this.onChanged});

  final bool yearly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _SubscriptionScreenState._card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TogglePill(
              label: 'Monthly',
              selected: !yearly,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _TogglePill(
              label: 'Yearly',
              selected: yearly,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white70,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _PopularBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Popular',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF38BDF8), Color(0xFF3B82F6)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}
