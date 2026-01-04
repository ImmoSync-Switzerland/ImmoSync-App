import 'package:flutter/material.dart';
import 'package:immosync/features/home/presentation/pages/bento_dashboard.dart';
import 'package:immosync/features/home/presentation/pages/glass_dashboard_shared.dart'
    show DashboardConfig, QuickActionItem;

const String _landlordHeaderTitle = 'Landlord Dashboard';
const String _landlordSearchHint = 'Search properties, tenants...';
const String _landlordRevenueLabel = "CHF 135'125.00";
const String _landlordRevenueSubtitle = 'Monthly Revenue';
const String _landlordOutstandingLabel = 'CHF 0.00';
const String _landlordOutstandingSubtitle = 'Outstanding';
const String _landlordPrimaryActionLabel = 'Add Property';
const IconData _landlordPrimaryActionIcon = Icons.add_home_work_rounded;
const String _landlordPrimaryActionRoute = '/add-property';
const bool _landlordPrimaryActionUsePush = true;

const List<QuickActionItem> _landlordQuickActions = [
  QuickActionItem(
    icon: Icons.message_rounded,
    label: 'Messages',
    route: '/conversations',
  ),
  QuickActionItem(
    icon: Icons.insert_chart_outlined_rounded,
    label: 'Reports',
    route: '/reports',
  ),
  QuickActionItem(
    icon: Icons.build_circle_outlined,
    label: 'Maintenance',
    route: '/maintenance/manage',
  ),
  QuickActionItem(
    icon: Icons.people_alt_rounded,
    label: 'Tenants',
    route: '/tenants',
  ),
  QuickActionItem(
    icon: Icons.account_balance_wallet_outlined,
    label: 'Payments',
    route: '/landlord/payments',
  ),
  QuickActionItem(
    icon: Icons.folder_open_rounded,
    label: 'Documents',
    route: '/landlord/documents',
  ),
  QuickActionItem(
    icon: Icons.subscriptions_outlined,
    label: 'Subscription',
    route: '/subscription/management',
  ),
  QuickActionItem(
    icon: Icons.design_services_outlined,
    label: 'Services',
    route: '/landlord/services',
  ),
];

const DashboardConfig _landlordGlassConfig = DashboardConfig(
  headerTitle: _landlordHeaderTitle,
  searchHint: _landlordSearchHint,
  revenueLabel: _landlordRevenueLabel,
  revenueSubtitle: _landlordRevenueSubtitle,
  revenueTrend: '+4.2% MoM',
  revenueAction: QuickActionItem(
    icon: Icons.insert_chart_outlined_rounded,
    label: 'Reports',
    route: '/reports',
  ),
  outstandingLabel: _landlordOutstandingLabel,
  outstandingSubtitle: _landlordOutstandingSubtitle,
  outstandingTrend: '-0.8% WoW',
  outstandingAction: QuickActionItem(
    icon: Icons.account_balance_wallet_outlined,
    label: 'Payments',
    route: '/landlord/payments',
  ),
  primaryActionLabel: _landlordPrimaryActionLabel,
  primaryActionIcon: _landlordPrimaryActionIcon,
  primaryActionRoute: _landlordPrimaryActionRoute,
  primaryActionUsePush: _landlordPrimaryActionUsePush,
  quickActions: _landlordQuickActions,
);

class LandlordDashboard extends StatelessWidget {
  const LandlordDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const BentoDashboardScaffold(config: _landlordGlassConfig);
  }
}
