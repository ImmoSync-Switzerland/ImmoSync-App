import 'package:flutter/material.dart';
import 'package:immosync/features/home/presentation/pages/bento_dashboard.dart';
import 'package:immosync/features/home/presentation/pages/glass_dashboard_shared.dart'
    show DashboardConfig, QuickActionItem;

const String _tenantHeaderTitle = 'Tenant Dashboard';
const String _tenantSearchHint = 'Search homes, payments...';
const String _tenantRevenueLabel = "CHF 3'250.00";
const String _tenantRevenueSubtitle = 'Upcoming Payments';
const String _tenantOutstandingLabel = '1 Ticket';
const String _tenantOutstandingSubtitle = 'Maintenance';
const String _tenantPrimaryActionLabel = 'Pay Rent';
const IconData _tenantPrimaryActionIcon = Icons.payments_outlined;
const String _tenantPrimaryActionRoute = '/payments/make';
const bool _tenantPrimaryActionUsePush = true;

const List<QuickActionItem> _tenantQuickActions = [
  QuickActionItem(
    icon: Icons.folder_open_rounded,
    label: 'Documents',
    route: '/documents',
  ),
  QuickActionItem(
    icon: Icons.credit_card_rounded,
    label: 'Payments',
    route: '/payments/history',
  ),
  QuickActionItem(
    icon: Icons.build_circle_outlined,
    label: 'Maintenance',
    route: '/tenant/maintenance',
  ),
  QuickActionItem(
    icon: Icons.support_agent,
    label: 'Support',
    route: '/contact-support',
  ),
];

const DashboardConfig _tenantGlassConfig = DashboardConfig(
  headerTitle: _tenantHeaderTitle,
  searchHint: _tenantSearchHint,
  revenueLabel: _tenantRevenueLabel,
  revenueSubtitle: _tenantRevenueSubtitle,
  revenueAction: QuickActionItem(
    icon: Icons.credit_card_rounded,
    label: 'Payments',
    route: '/payments/history',
  ),
  outstandingLabel: _tenantOutstandingLabel,
  outstandingSubtitle: _tenantOutstandingSubtitle,
  outstandingAction: QuickActionItem(
    icon: Icons.build_circle_outlined,
    label: 'Maintenance',
    route: '/tenant/maintenance',
  ),
  primaryActionLabel: _tenantPrimaryActionLabel,
  primaryActionIcon: _tenantPrimaryActionIcon,
  primaryActionRoute: _tenantPrimaryActionRoute,
  primaryActionUsePush: _tenantPrimaryActionUsePush,
  quickActions: _tenantQuickActions,
);

class TenantDashboard extends StatelessWidget {
  const TenantDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const BentoDashboardScaffold(config: _tenantGlassConfig);
  }
}
