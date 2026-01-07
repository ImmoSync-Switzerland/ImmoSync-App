import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/home/presentation/pages/bento_dashboard.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/home/presentation/pages/glass_dashboard_shared.dart'
    show DashboardConfig, QuickActionItem;
import 'package:immosync/l10n/app_localizations.dart';

const String _landlordRevenueLabel = "CHF 135'125.00";
const String _landlordOutstandingLabel = 'CHF 0.00';
const IconData _landlordPrimaryActionIcon = Icons.add_home_work_rounded;
const String _landlordPrimaryActionRoute = '/add-property';
const bool _landlordPrimaryActionUsePush = true;

class LandlordDashboard extends ConsumerWidget {
  const LandlordDashboard({super.key});

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;

    // Morning: 05:00–11:59
    if (hour >= 5 && hour < 12) return l10n.goodMorning;

    // Day: 12:00–17:59
    if (hour < 18) return l10n.goodAfternoon;

    // Evening: 18:00–04:59
    return l10n.goodEvening;
  }

  String _greetingWithName(AppLocalizations l10n, String? fullName) {
    final greeting = _greeting(l10n);
    final name = (fullName ?? '').trim();
    if (name.isEmpty) return greeting;
    final firstName = name.split(RegExp(r'\s+')).first;
    return '$greeting, $firstName';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(currentUserProvider);

    final quickActions = <QuickActionItem>[
      QuickActionItem(
        icon: Icons.message_rounded,
        label: l10n.messages,
        route: '/conversations',
      ),
      QuickActionItem(
        icon: Icons.insert_chart_outlined_rounded,
        label: l10n.reports,
        route: '/reports',
      ),
      QuickActionItem(
        icon: Icons.build_circle_outlined,
        label: l10n.maintenance,
        route: '/maintenance/manage',
      ),
      QuickActionItem(
        icon: Icons.people_alt_rounded,
        label: l10n.tenants,
        route: '/tenants',
      ),
      QuickActionItem(
        icon: Icons.account_balance_wallet_outlined,
        label: l10n.payments,
        route: '/landlord/payments',
      ),
      QuickActionItem(
        icon: Icons.folder_open_rounded,
        label: l10n.documents,
        route: '/landlord/documents',
      ),
      QuickActionItem(
        icon: Icons.subscriptions_outlined,
        label: l10n.subscription,
        route: '/subscription/management',
      ),
      QuickActionItem(
        icon: Icons.design_services_outlined,
        label: l10n.services,
        route: '/landlord/services',
      ),
    ];

    final config = DashboardConfig(
      headerTitle: _greetingWithName(l10n, currentUser?.fullName),
      searchHint: l10n.searchPropertiesLandlords,
      revenueLabel: _landlordRevenueLabel,
      revenueSubtitle: l10n.monthlyRevenue,
      revenueTrend: '+4.2% MoM',
      revenueAction: QuickActionItem(
        icon: Icons.insert_chart_outlined_rounded,
        label: l10n.reports,
        route: '/reports',
      ),
      outstandingLabel: _landlordOutstandingLabel,
      outstandingSubtitle: l10n.outstanding,
      outstandingAction: QuickActionItem(
        icon: Icons.account_balance_wallet_outlined,
        label: l10n.payments,
        route: '/landlord/payments',
      ),
      primaryActionLabel: l10n.addProperty,
      primaryActionIcon: _landlordPrimaryActionIcon,
      primaryActionRoute: _landlordPrimaryActionRoute,
      primaryActionUsePush: _landlordPrimaryActionUsePush,
      quickActions: quickActions,
    );

    return BentoDashboardScaffold(config: config);
  }
}
