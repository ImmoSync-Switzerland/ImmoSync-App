// CLEAN REWRITE OF CORRUPTED FILE
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:immosync/core/providers/dynamic_colors_provider.dart';
import 'package:immosync/features/subscription/domain/models/subscription.dart';
import 'package:immosync/features/subscription/presentation/providers/subscription_providers.dart';
import '../../../../../l10n/app_localizations.dart';

class LandlordSubscriptionPage extends ConsumerStatefulWidget {
  const LandlordSubscriptionPage({super.key});

  @override
  ConsumerState<LandlordSubscriptionPage> createState() =>
      _LandlordSubscriptionPageState();
}

class _LandlordSubscriptionPageState
    extends ConsumerState<LandlordSubscriptionPage> {
  bool _isYearlyBilling = false;
  SubscriptionPlan? _selectedPlan;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final userSubscription = ref.watch(userSubscriptionProvider);

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        title: userSubscription.when(
          data: (subscription) => Text(
            subscription != null && subscription.status == 'active'
                ? l10n.manageSubscriptionTitle
                : l10n.chooseYourPlanTitle,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          loading: () => Text(
            l10n.chooseYourPlanTitle,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          error: (_, __) => Text(
            l10n.chooseYourPlanTitle,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        backgroundColor: colors.surfaceCards,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: userSubscription.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorView(colors, error, l10n),
        data: (subscription) => plansAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildErrorView(colors, error, l10n),
          data: (plans) =>
              _buildSubscriptionView(subscription, plans, colors, l10n),
        ),
      ),
    );
  }

  Widget _buildErrorView(
      DynamicAppColors colors, Object error, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colors.error),
          const SizedBox(height: 16),
          Text(
            l10n.subscriptionLoadError,
            style: TextStyle(
                fontSize: 18,
                color: colors.textPrimary,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(subscriptionPlansProvider);
              ref.invalidate(userSubscriptionProvider);
            },
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionView(
    UserSubscription? subscription,
    List<SubscriptionPlan> plans,
    DynamicAppColors colors,
    AppLocalizations l10n,
  ) {
    final hasActiveSubscription =
        subscription != null && subscription.status == 'active';
    var availablePlans = plans;
    if (hasActiveSubscription) {
      availablePlans = _getUpgradeOptions(subscription, plans);
    }

    return Column(
      children: [
        if (hasActiveSubscription)
          _buildCurrentSubscriptionHeader(subscription, colors, l10n),
        if (availablePlans.isNotEmpty) _buildBillingToggle(colors, l10n),
        Expanded(
          child: availablePlans.isNotEmpty
              ? ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      hasActiveSubscription
                          ? l10n.upgradeUnlockFeaturesMessage
                          : l10n.selectPlanIntro,
                      style: TextStyle(
                          fontSize: 16,
                          color: colors.textSecondary,
                          height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ...availablePlans.map(
                      (plan) => _buildPlanCard(
                        plan,
                        colors,
                        l10n,
                        isUpgrade: hasActiveSubscription,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                )
              : _buildNoUpgradesAvailable(colors, l10n),
        ),
        if (_selectedPlan != null)
          _buildContinueButton(colors, l10n, isUpgrade: hasActiveSubscription),
      ],
    );
  }

  List<SubscriptionPlan> _getUpgradeOptions(
    UserSubscription current,
    List<SubscriptionPlan> allPlans,
  ) {
    const hierarchy = ['basic', 'pro', 'enterprise'];
    final currentIndex = hierarchy.indexOf(current.planId.toLowerCase());
    if (currentIndex == -1) return allPlans;
    return allPlans
        .where((p) => hierarchy.indexOf(p.id.toLowerCase()) > currentIndex)
        .toList();
  }

  Widget _buildCurrentSubscriptionHeader(
    UserSubscription subscription,
    DynamicAppColors colors,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primaryAccent.withValues(alpha: 0.1),
            colors.primaryAccent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primaryAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.success,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.currentPlanLabel}: ${subscription.planId.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      '${l10n.statusLabel}: ${subscription.status.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'CHF ${subscription.amount.toStringAsFixed(2)}/${subscription.billingInterval}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceCards,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: colors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${l10n.nextBillingLabel}: ${subscription.nextBillingDate.toLocal().toString().split(' ')[0]}',
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
  }

  Widget _buildNoUpgradesAvailable(
      DynamicAppColors colors, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colors.primaryAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium,
              size: 64,
              color: colors.primaryAccent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.highestPlanTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.highestPlanDescription,
            style: TextStyle(
              fontSize: 16,
              color: colors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: colors.success, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.premiumThanksMessage,
                  style: TextStyle(
                    color: colors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle(DynamicAppColors colors, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _isYearlyBilling = false);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isYearlyBilling
                      ? colors.primaryAccent
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.billingMonthly,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        !_isYearlyBilling ? Colors.white : colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _isYearlyBilling = true);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isYearlyBilling
                      ? colors.primaryAccent
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.billingYearly,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isYearlyBilling
                            ? Colors.white
                            : colors.textSecondary,
                      ),
                    ),
                    if (_isYearlyBilling)
                      Text(
                        l10n.savePercent('17'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    SubscriptionPlan plan,
    DynamicAppColors colors,
    AppLocalizations l10n, {
    bool isUpgrade = false,
  }) {
    final isSelected = _selectedPlan?.id == plan.id;
    final price = _isYearlyBilling ? plan.yearlyPrice : plan.monthlyPrice;
    final monthlyPrice =
        _isYearlyBilling ? plan.yearlyPrice / 12 : plan.monthlyPrice;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedPlan = plan);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surfaceCards,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.primaryAccent : colors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primaryAccent.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
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
                      Row(
                        children: [
                          Text(
                            plan.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          if (plan.isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.primaryAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l10n.popularBadge,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                          if (isUpgrade) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.luxuryGold,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l10n.upgradeBadge,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.description,
                        style: TextStyle(
                            fontSize: 14, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: colors.primaryAccent,
                      ),
                    ),
                    Text(
                      _isYearlyBilling
                          ? l10n.perYearSuffix
                          : l10n.perMonthSuffix,
                      style:
                          TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                    if (_isYearlyBilling)
                      Text(
                        '${monthlyPrice.toStringAsFixed(2)} ${l10n.perMonthSuffix}',
                        style:
                            TextStyle(fontSize: 10, color: colors.textTertiary),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...plan.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: colors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style:
                            TextStyle(fontSize: 14, color: colors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton(
    DynamicAppColors colors,
    AppLocalizations l10n, {
    bool isUpgrade = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _handleSubscription,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isUpgrade ? colors.luxuryGold : colors.primaryAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isUpgrade) const Icon(Icons.upgrade, size: 20),
                    if (isUpgrade) const SizedBox(width: 8),
                    Text(
                      isUpgrade
                          ? l10n.upgradePlanButton
                          : l10n.continueToPayment,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _handleSubscription() async {
    if (_selectedPlan == null) return;
    setState(() => _isProcessing = true);
    try {
      context.push('/subscription/payment', extra: {
        'plan': _selectedPlan!,
        'isYearly': _isYearlyBilling,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}
