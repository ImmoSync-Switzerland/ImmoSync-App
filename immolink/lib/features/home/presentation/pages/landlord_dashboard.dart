import 'package:flutter/material.dart';
import 'package:immosync/features/home/presentation/pages/bento_dashboard.dart';
import 'package:immosync/features/home/presentation/pages/glass_dashboard_shared.dart'
    show DashboardConfig, QuickActionItem;
import 'package:immosync/l10n/app_localizations.dart';

const String _landlordRevenueLabel = "CHF 135'125.00";
const String _landlordOutstandingLabel = 'CHF 0.00';
const IconData _landlordPrimaryActionIcon = Icons.add_home_work_rounded;
const String _landlordPrimaryActionRoute = '/add-property';
const bool _landlordPrimaryActionUsePush = true;

class LandlordDashboard extends StatelessWidget {
  const LandlordDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
      headerTitle: l10n.landlordDashboard,
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
      outstandingTrend: '-0.8% WoW',
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
