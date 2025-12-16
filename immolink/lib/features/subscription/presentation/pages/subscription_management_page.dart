import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/core/providers/dynamic_colors_provider.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/home/presentation/models/dashboard_design.dart';
import 'package:immosync/features/home/presentation/pages/glass_dashboard_shared.dart';
import 'package:immosync/features/settings/providers/settings_provider.dart';
import 'package:immosync/features/subscription/presentation/providers/subscription_providers.dart';
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
    final design = dashboardDesignFromId(
      ref.watch(settingsProvider).dashboardDesign,
    );
    final bool glassMode = design == DashboardDesign.glass;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.subscriptionPageTitle),
          backgroundColor: colors.primaryBackground,
        ),
        body: Center(child: Text(l10n.subscriptionLoginPrompt)),
      );
    }

    final Widget content = RefreshIndicator(
      onRefresh: () async => ref.invalidate(userSubscriptionProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(glassMode ? 16 : 20),
        child: subscriptionAsync.when(
          data: (subscription) {
            if (subscription == null) {
              return _buildNoSubscription(
                context,
                colors,
                l10n,
                glassMode: glassMode,
              );
            }
            return _buildSubscriptionDetails(
              context,
              colors,
              l10n,
              subscription,
              ref,
              glassMode: glassMode,
            );
          },
          loading: () => Center(
            child: glassMode
                ? const GlassContainer(
                    padding: EdgeInsets.all(28),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
          ),
          error: (error, _) => _buildErrorState(
            context,
            colors,
            l10n,
            error.toString(),
            glassMode: glassMode,
          ),
        ),
      ),
    );

    if (glassMode) {
      return GlassPageScaffold(
        title: l10n.subscriptionPageTitle,
        showBottomNav: false,
        onBack: () => context.go('/settings'),
        body: content,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.subscriptionPageTitle),
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
        child: content,
      ),
    );
  }

  Widget _buildNoSubscription(
    BuildContext context,
    DynamicAppColors colors,
    AppLocalizations l10n, {
    required bool glassMode,
  }) {
    final titleStyle = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: glassMode ? Colors.white : colors.textPrimary,
      letterSpacing: -0.6,
    );
    final subtitleStyle = TextStyle(
      fontSize: 16,
      color: glassMode
          ? Colors.white.withValues(alpha: 0.85)
          : colors.textSecondary,
      fontWeight: FontWeight.w500,
    );

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: glassMode ? Colors.white : colors.primaryAccent,
      foregroundColor: glassMode ? Colors.black87 : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final child = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: glassMode
                ? Colors.white.withValues(alpha: 0.15)
                : colors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.credit_card_off,
            size: 80,
            color: glassMode ? Colors.white : colors.warning,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          l10n.subscriptionNoActiveTitle,
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.subscriptionNoActiveDescription,
          style: subtitleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/subscription-plans'),
          style: buttonStyle,
          child: Text(
            l10n.subscriptionViewPlansButton,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );

    if (glassMode) {
      return Center(
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      );
    }

    return Center(child: child);
  }

  Widget _buildSubscriptionDetails(
    BuildContext context,
    DynamicAppColors colors,
    AppLocalizations l10n,
    dynamic subscription,
    WidgetRef ref, {
    required bool glassMode,
  }) {
    final Color primaryText = glassMode ? Colors.white : colors.textPrimary;
    final Color secondaryText =
        glassMode ? Colors.white.withValues(alpha: 0.8) : colors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: subscription.isActive
                  ? [
                      colors.success.withValues(alpha: 0.9),
                      colors.success.withValues(alpha: 0.7),
                    ]
                  : [
                      colors.error.withValues(alpha: 0.9),
                      colors.error.withValues(alpha: 0.7),
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
            border: glassMode
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  )
                : null,
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
                          ? l10n.subscriptionStatusActive
                          : l10n.subscriptionStatusValue(subscription.status),
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
                l10n.subscriptionPlanLabel,
                subscription.planId.toUpperCase(),
                Colors.white,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.payment,
                l10n.subscriptionAmountLabel,
                'CHF ${subscription.amount.toStringAsFixed(2)}',
                Colors.white,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.calendar_today,
                l10n.subscriptionBillingLabel,
                subscription.billingInterval == 'month'
                    ? l10n.subscriptionBillingMonthly
                    : l10n.subscriptionBillingYearly,
                Colors.white,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.event,
                l10n.subscriptionNextBillingLabel,
                _formatDate(subscription.nextBillingDate),
                Colors.white,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionCard(
          colors: colors,
          glassMode: glassMode,
          child: _buildDetailsContent(
            colors,
            l10n,
            subscription,
            primaryText,
            secondaryText,
            glassMode: glassMode,
          ),
        ),
        const SizedBox(height: 24),
        if (subscription.isActive) ...[
          _buildActionButton(
            context,
            colors,
            l10n.subscriptionManageButton,
            Icons.settings,
            () async {
              await _openCustomerPortal(context, ref, subscription, l10n);
            },
            glassMode: glassMode,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            colors,
            l10n.subscriptionCancelButton,
            Icons.cancel,
            () {
              _showCancelDialog(context, colors, ref, subscription.id, l10n);
            },
            isDestructive: true,
            glassMode: glassMode,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailsContent(
    DynamicAppColors colors,
    AppLocalizations l10n,
    dynamic subscription,
    Color primaryText,
    Color secondaryText, {
    required bool glassMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.subscriptionDetailsTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: primaryText,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 20),
        _buildDetailRow(
          l10n.subscriptionIdLabel,
          subscription.stripeSubscriptionId,
          colors,
          glassMode: glassMode,
        ),
        _buildDivider(glassMode, colors),
        _buildDetailRow(
          l10n.subscriptionCustomerIdLabel,
          subscription.stripeCustomerId ??
              l10n.subscriptionCustomerIdUnavailable,
          colors,
          glassMode: glassMode,
        ),
        _buildDivider(glassMode, colors),
        _buildDetailRow(
          l10n.subscriptionStartedLabel,
          _formatDate(subscription.startDate),
          colors,
          glassMode: glassMode,
        ),
        if (subscription.endDate != null) ...[
          _buildDivider(glassMode, colors),
          _buildDetailRow(
            l10n.subscriptionEndsLabel,
            _formatDate(subscription.endDate!),
            colors,
            glassMode: glassMode,
          ),
        ],
      ],
    );
  }

  Widget _sectionCard({
    required DynamicAppColors colors,
    required bool glassMode,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(24),
  }) {
    if (glassMode) {
      return GlassContainer(
        padding: padding,
        child: child,
      );
    }

    return Container(
      padding: padding,
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
      child: child,
    );
  }

  Widget _buildDivider(bool glassMode, DynamicAppColors colors) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        height: 1,
        color: glassMode
            ? Colors.white.withValues(alpha: 0.2)
            : colors.dividerSeparator,
      ),
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

  Widget _buildDetailRow(
    String label,
    String value,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    final Color labelColor =
        glassMode ? Colors.white.withValues(alpha: 0.7) : colors.textSecondary;
    final Color valueColor = glassMode ? Colors.white : colors.textPrimary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: valueColor,
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
    DynamicAppColors colors,
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool isDestructive = false,
    required bool glassMode,
  }) {
    final Color background = glassMode
        ? (isDestructive ? Colors.white.withValues(alpha: 0.12) : Colors.white)
        : (isDestructive ? colors.error : colors.primaryAccent);
    final Color foreground = glassMode
        ? (isDestructive ? Colors.redAccent : Colors.black87)
        : Colors.white;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: foreground),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: glassMode ? 0 : 0,
          side: glassMode
              ? BorderSide(
                  color: foreground.withValues(alpha: 0.4),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    DynamicAppColors colors,
    AppLocalizations l10n,
    String error, {
    required bool glassMode,
  }) {
    final child = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: glassMode ? Colors.white : colors.error,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.subscriptionErrorLoading,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: glassMode ? Colors.white : colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          error,
          style: TextStyle(
            fontSize: 14,
            color: glassMode
                ? Colors.white.withValues(alpha: 0.85)
                : colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    if (glassMode) {
      return Center(
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      );
    }

    return Center(child: child);
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  Future<void> _openCustomerPortal(
    BuildContext context,
    WidgetRef ref,
    dynamic subscription,
    AppLocalizations l10n,
  ) async {
    try {
      final customerId = subscription.stripeCustomerId;
      if (customerId == null || customerId.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.subscriptionNoCustomerIdMessage)),
          );
        }
        return;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    l10n.subscriptionOpeningPortal,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      final service = ref.read(subscriptionServiceProvider);
      final portalUrl = await service.createCustomerPortalSession(
        customerId: customerId,
        returnUrl: 'immosync://subscription/management',
      );

      final uri = Uri.parse(portalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch portal URL');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.subscriptionFailedToOpenPortal(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCancelDialog(
    BuildContext context,
    DynamicAppColors colors,
    WidgetRef ref,
    String subscriptionId,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.subscriptionCancelDialogTitle),
        content: Text(l10n.subscriptionCancelDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.subscriptionKeepButton),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final service = ref.read(subscriptionServiceProvider);
                await service.cancelSubscription(subscriptionId);
                ref.invalidate(userSubscriptionProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.subscriptionCancelledMessage),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.subscriptionCancelErrorMessage(e.toString()),
                      ),
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: Text(l10n.subscriptionCancelButton),
          ),
        ],
      ),
    );
  }
}
