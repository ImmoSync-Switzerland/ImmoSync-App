import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immolink/core/providers/dynamic_colors_provider.dart';
import 'package:immolink/features/subscription/domain/models/subscription.dart';
import 'package:immolink/features/subscription/presentation/providers/subscription_providers.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class LandlordSubscriptionPage extends ConsumerStatefulWidget {
  const LandlordSubscriptionPage({super.key});

  @override
  ConsumerState<LandlordSubscriptionPage> createState() => _LandlordSubscriptionPageState();
}

class _LandlordSubscriptionPageState extends ConsumerState<LandlordSubscriptionPage> {
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
                ? 'Manage Subscription'
                : 'Choose Your Plan',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          loading: () => Text(
            'Choose Your Plan',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          error: (_, __) => Text(
            'Choose Your Plan',
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
        error: (error, stackTrace) => _buildErrorView(colors, error),
        data: (subscription) => plansAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _buildErrorView(colors, error),
          data: (plans) => _buildSubscriptionView(subscription, plans, colors, l10n),
        ),
      ),
    );
  }

  Widget _buildErrorView(DynamicAppColors colors, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load subscription data',
            style: TextStyle(
              fontSize: 18,
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(subscriptionPlansProvider);
              ref.invalidate(userSubscriptionProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionView(UserSubscription? subscription, List<SubscriptionPlan> plans, DynamicAppColors colors, AppLocalizations l10n) {
    final bool hasActiveSubscription = subscription != null && subscription.status == 'active';
    
    // If user has active subscription, filter plans to show only upgrade options
    List<SubscriptionPlan> availablePlans = plans;
    if (hasActiveSubscription) {
      availablePlans = _getUpgradeOptions(subscription, plans);
    }

    return Column(
      children: [
        // Show current subscription card at the top if active
        if (hasActiveSubscription) 
          _buildCurrentSubscriptionHeader(subscription, colors, l10n),
        
        // Billing toggle (only if there are plans to show)
        if (availablePlans.isNotEmpty)
          _buildBillingToggle(colors),
        
        // Plans list or upgrade message
        Expanded(
          child: availablePlans.isNotEmpty 
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 16),
                  Text(
                    hasActiveSubscription 
                      ? 'Upgrade to unlock more features and property limits'
                      : 'Select the perfect plan for your property management needs',
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ...availablePlans.map((plan) => _buildPlanCard(plan, colors, l10n, hasActiveSubscription)),
                  const SizedBox(height: 32),
                ],
              )
            : _buildNoUpgradesAvailable(colors, l10n),
        ),
        
        // Continue button
        if (_selectedPlan != null)
          _buildContinueButton(colors, l10n, hasActiveSubscription),
      ],
    );
  }

  List<SubscriptionPlan> _getUpgradeOptions(UserSubscription currentSubscription, List<SubscriptionPlan> allPlans) {
    // Define plan hierarchy
    const planHierarchy = ['basic', 'pro', 'enterprise'];
    
    final currentPlanIndex = planHierarchy.indexOf(currentSubscription.planId.toLowerCase());
    if (currentPlanIndex == -1) return allPlans; // Unknown plan, show all
    
    // Return only plans that are higher in the hierarchy
    return allPlans.where((plan) {
      final planIndex = planHierarchy.indexOf(plan.id.toLowerCase());
      return planIndex > currentPlanIndex;
    }).toList();
  }

  Widget _buildCurrentSubscriptionHeader(UserSubscription subscription, DynamicAppColors colors, AppLocalizations l10n) {
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
                child: Icon(
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
                      'Current Plan: ${subscription.planId.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Status: ${subscription.status.toUpperCase()}',
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
                  'Next billing: ${subscription.nextBillingDate.toLocal().toString().split(' ')[0]}',
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

  Widget _buildNoUpgradesAvailable(DynamicAppColors colors, AppLocalizations l10n) {
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
            'You\'re on the highest plan!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'You have access to all premium features and unlimited property management capabilities.',
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
                  'Thank you for being a premium subscriber!',
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

  Widget _buildBillingToggle(DynamicAppColors colors) {
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
                  color: !_isYearlyBilling ? colors.primaryAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Monthly',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: !_isYearlyBilling ? Colors.white : colors.textSecondary,
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
                  color: _isYearlyBilling ? colors.primaryAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Yearly',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isYearlyBilling ? Colors.white : colors.textSecondary,
                      ),
                    ),
                    if (_isYearlyBilling)
                      Text(
                        'Save 17%',
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

  Widget _buildPlanCard(SubscriptionPlan plan, DynamicAppColors colors, AppLocalizations l10n, [bool isUpgrade = false]) {
    final isSelected = _selectedPlan?.id == plan.id;
    final price = _isYearlyBilling ? plan.yearlyPrice : plan.monthlyPrice;
    final monthlyPrice = _isYearlyBilling ? plan.yearlyPrice / 12 : plan.monthlyPrice;

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
          boxShadow: isSelected ? [
            BoxShadow(
              color: colors.primaryAccent.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.primaryAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Popular',
                                style: TextStyle(
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.luxuryGold,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Upgrade',
                                style: TextStyle(
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
                      _isYearlyBilling ? '/year' : '/month',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                    if (_isYearlyBilling)
                      Text(
                        '\$${monthlyPrice.toStringAsFixed(2)}/month',
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...plan.features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: colors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton(DynamicAppColors colors, AppLocalizations l10n, [bool isUpgrade = false]) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _handleSubscription,
          style: ElevatedButton.styleFrom(
            backgroundColor: isUpgrade ? colors.luxuryGold : colors.primaryAccent,
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
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isUpgrade) Icon(Icons.upgrade, size: 20),
                    if (isUpgrade) const SizedBox(width: 8),
                    Text(
                      isUpgrade ? 'Upgrade Plan' : 'Continue to Payment',
                      style: TextStyle(
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
      // Navigate to payment page with selected plan
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
