import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:immosync/core/providers/dynamic_colors_provider.dart';
import 'package:immosync/features/subscription/domain/models/subscription.dart';
import 'package:immosync/features/subscription/presentation/providers/subscription_providers.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../home/presentation/models/dashboard_design.dart';
import '../../../home/presentation/pages/glass_dashboard_shared.dart';
import '../../../settings/providers/settings_provider.dart';

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
    final design = dashboardDesignFromId(
      ref.watch(settingsProvider).dashboardDesign,
    );
    final bool glassMode = design == DashboardDesign.glass;

    final String pageTitle = userSubscription.when(
      data: (subscription) =>
          subscription != null && subscription.status.toLowerCase() == 'active'
              ? l10n.manageSubscriptionTitle
              : l10n.chooseYourPlanTitle,
      loading: () => l10n.chooseYourPlanTitle,
      error: (_, __) => l10n.chooseYourPlanTitle,
    );

    final Widget body = userSubscription.when(
      loading: () => _buildLoading(colors, glassMode: glassMode),
      error: (error, _) =>
          _buildErrorView(colors, error, l10n, glassMode: glassMode),
      data: (subscription) => plansAsync.when(
        loading: () => _buildLoading(colors, glassMode: glassMode),
        error: (error, _) =>
            _buildErrorView(colors, error, l10n, glassMode: glassMode),
        data: (plans) => _buildSubscriptionView(
          subscription,
          plans,
          colors,
          l10n,
          glassMode: glassMode,
        ),
      ),
    );

    if (glassMode) {
      return GlassPageScaffold(
        title: pageTitle,
        showBottomNav: false,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        body: body,
      );
    }

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        title: Text(
          pageTitle,
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
      body: body,
    );
  }

  Widget _buildLoading(
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    const indicator = SizedBox(
      width: 40,
      height: 40,
      child: CircularProgressIndicator(),
    );

    if (glassMode) {
      return const Center(
        child: GlassContainer(
          padding: EdgeInsets.all(28),
          child: indicator,
        ),
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorView(
    DynamicAppColors colors,
    Object error,
    AppLocalizations l10n, {
    required bool glassMode,
  }) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: glassMode ? Colors.white : colors.error,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.subscriptionLoadError,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: glassMode ? Colors.white : colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          error.toString(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: glassMode
                ? Colors.white.withValues(alpha: 0.85)
                : colors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            ref.invalidate(subscriptionPlansProvider);
            ref.invalidate(userSubscriptionProvider);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: glassMode ? Colors.white : colors.primaryAccent,
            foregroundColor: glassMode ? Colors.black87 : Colors.white,
          ),
          child: Text(l10n.retry),
        ),
      ],
    );

    if (glassMode) {
      return Center(
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: content,
        ),
      );
    }

    return Center(child: content);
  }

  Widget _buildSubscriptionView(
    UserSubscription? subscription,
    List<SubscriptionPlan> plans,
    DynamicAppColors colors,
    AppLocalizations l10n, {
    required bool glassMode,
  }) {
    final bool hasActiveSubscription =
        subscription != null && subscription.status.toLowerCase() == 'active';
    final List<SubscriptionPlan> availablePlans =
        hasActiveSubscription ? _getUpgradeOptions(subscription, plans) : plans;

    final header = <Widget>[
      if (hasActiveSubscription)
        _buildCurrentSubscriptionHeader(
          subscription,
          colors,
          l10n,
          glassMode: glassMode,
        ),
      if (availablePlans.isNotEmpty)
        _buildBillingToggle(colors, l10n, glassMode: glassMode),
    ];

    final plansList = availablePlans.isNotEmpty
        ? availablePlans
            .map(
              (plan) => _buildPlanCard(
                plan,
                colors,
                l10n,
                isUpgrade: hasActiveSubscription,
                glassMode: glassMode,
              ),
            )
            .toList()
        : <Widget>[
            _buildNoUpgradesAvailable(colors, l10n, glassMode: glassMode),
          ];

    final continueButton = _selectedPlan != null
        ? _buildContinueButton(
            colors,
            l10n,
            isUpgrade: hasActiveSubscription,
            glassMode: glassMode,
          )
        : const SizedBox.shrink();

    if (glassMode) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...header,
            if (availablePlans.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                hasActiveSubscription
                    ? l10n.upgradeUnlockFeaturesMessage
                    : l10n.selectPlanIntro,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
            ],
            ...plansList,
            const SizedBox(height: 24),
            continueButton,
          ],
        ),
      );
    }

    return Column(
      children: [
        ...header,
        Expanded(
          child: availablePlans.isNotEmpty
              ? ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      hasActiveSubscription
                          ? l10n.upgradeUnlockFeaturesMessage
                          : l10n.selectPlanIntro,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...plansList,
                  ],
                )
              : Center(child: plansList.first),
        ),
        continueButton,
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
        .where(
            (plan) => hierarchy.indexOf(plan.id.toLowerCase()) > currentIndex)
        .toList();
  }

  Widget _buildCurrentSubscriptionHeader(
    UserSubscription subscription,
    DynamicAppColors colors,
    AppLocalizations l10n, {
    required bool glassMode,
  }) {
    final headerContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: glassMode ? Colors.white : colors.success,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle,
                size: 20,
                color: glassMode ? Colors.black87 : Colors.white,
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
                      color: glassMode ? Colors.white : colors.textPrimary,
                    ),
                  ),
                  Text(
                    '${l10n.statusLabel}: ${subscription.status.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: glassMode ? Colors.white70 : colors.success,
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
                color: glassMode ? Colors.white : colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: glassMode
                ? Colors.white.withValues(alpha: 0.12)
                : colors.surfaceCards,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: glassMode
                    ? Colors.white.withValues(alpha: 0.85)
                    : colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '${l10n.nextBillingLabel}: ${subscription.nextBillingDate.toLocal().toString().split(' ')[0]}',
                style: TextStyle(
                  fontSize: 14,
                  color: glassMode
                      ? Colors.white.withValues(alpha: 0.85)
                      : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (glassMode) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: headerContent,
        ),
      );
    }

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
      child: headerContent,
    );
  }

  Widget _buildNoUpgradesAvailable(
    DynamicAppColors colors,
    AppLocalizations l10n, {
    required bool glassMode,
  }) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: glassMode
                ? Colors.white.withValues(alpha: 0.15)
                : colors.primaryAccent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.workspace_premium,
            size: 64,
            color: glassMode ? Colors.white : colors.primaryAccent,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.highestPlanTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: glassMode ? Colors.white : colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.highestPlanDescription,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            height: 1.4,
            color: glassMode
                ? Colors.white.withValues(alpha: 0.85)
                : colors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: glassMode
                ? Colors.white.withValues(alpha: 0.12)
                : colors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: glassMode
                ? Border.all(color: Colors.white.withValues(alpha: 0.25))
                : Border.all(color: colors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                size: 20,
                color: glassMode ? Colors.white : colors.success,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.premiumThanksMessage,
                style: TextStyle(
                  color: glassMode ? Colors.white : colors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (glassMode) {
      return GlassContainer(
        padding: const EdgeInsets.all(24),
        child: content,
      );
    }

    return Center(child: content);
  }

  Widget _buildBillingToggle(
    DynamicAppColors colors,
    AppLocalizations l10n, {
    required bool glassMode,
  }) {
    final toggle = Row(
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
                    ? (glassMode ? Colors.white : colors.primaryAccent)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.billingMonthly,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: !_isYearlyBilling
                      ? (glassMode ? Colors.black87 : Colors.white)
                      : (glassMode
                          ? Colors.white.withValues(alpha: 0.75)
                          : colors.textSecondary),
                ),
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
                    ? (glassMode ? Colors.white : colors.primaryAccent)
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
                          ? (glassMode ? Colors.black87 : Colors.white)
                          : (glassMode
                              ? Colors.white.withValues(alpha: 0.75)
                              : colors.textSecondary),
                    ),
                  ),
                  if (_isYearlyBilling)
                    Text(
                      l10n.savePercent('17'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: glassMode
                            ? Colors.black87.withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    if (glassMode) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: GlassContainer(
          padding: const EdgeInsets.all(6),
          child: toggle,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderLight),
      ),
      child: toggle,
    );
  }

  Widget _buildPlanCard(
    SubscriptionPlan plan,
    DynamicAppColors colors,
    AppLocalizations l10n, {
    required bool glassMode,
    bool isUpgrade = false,
  }) {
    final bool isSelected = _selectedPlan?.id == plan.id;
    final double price =
        _isYearlyBilling ? plan.yearlyPrice : plan.monthlyPrice;
    final double monthlyPrice =
        _isYearlyBilling ? plan.yearlyPrice / 12 : plan.monthlyPrice;

    final decoration = BoxDecoration(
      color: glassMode
          ? Colors.white.withValues(alpha: 0.12)
          : colors.surfaceCards,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isSelected
            ? (glassMode ? Colors.white : colors.primaryAccent)
            : colors.borderLight,
        width: isSelected ? 2 : 1,
      ),
      boxShadow: isSelected
          ? [
              BoxShadow(
                color: (glassMode ? Colors.black : colors.primaryAccent)
                    .withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedPlan = plan);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: decoration,
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
                              color:
                                  glassMode ? Colors.white : colors.textPrimary,
                            ),
                          ),
                          if (plan.isPopular) ...[
                            const SizedBox(width: 8),
                            _buildBadge(
                              l10n.popularBadge,
                              glassMode ? Colors.white : colors.primaryAccent,
                              glassMode ? Colors.black : Colors.white,
                            ),
                          ],
                          if (isUpgrade) ...[
                            const SizedBox(width: 8),
                            _buildBadge(
                              l10n.upgradeBadge,
                              glassMode ? Colors.white : colors.luxuryGold,
                              glassMode ? Colors.black : Colors.white,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: glassMode
                              ? Colors.white.withValues(alpha: 0.8)
                              : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: glassMode ? Colors.white : colors.primaryAccent,
                      ),
                    ),
                    Text(
                      _isYearlyBilling
                          ? l10n.perYearSuffix
                          : l10n.perMonthSuffix,
                      style: TextStyle(
                        fontSize: 12,
                        color: glassMode
                            ? Colors.white.withValues(alpha: 0.7)
                            : colors.textSecondary,
                      ),
                    ),
                    if (_isYearlyBilling)
                      Text(
                        '${monthlyPrice.toStringAsFixed(2)} ${l10n.perMonthSuffix}',
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              glassMode ? Colors.white54 : colors.textTertiary,
                        ),
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
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: glassMode ? Colors.white : colors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 14,
                          color: glassMode ? Colors.white : colors.textPrimary,
                        ),
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

  Widget _buildBadge(String text, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }

  Widget _buildContinueButton(
    DynamicAppColors colors,
    AppLocalizations l10n, {
    required bool glassMode,
    bool isUpgrade = false,
  }) {
    final backgroundColor = glassMode
        ? Colors.white
        : (isUpgrade ? colors.luxuryGold : colors.primaryAccent);
    final foregroundColor = glassMode ? Colors.black87 : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _handleSubscription,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: glassMode ? 0 : 0,
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
}
