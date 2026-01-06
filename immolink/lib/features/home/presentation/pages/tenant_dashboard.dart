import 'package:flutter/material.dart';
import 'package:immosync/features/home/presentation/pages/bento_dashboard.dart';
import 'package:immosync/features/home/presentation/pages/glass_dashboard_shared.dart'
    show DashboardConfig, QuickActionItem;
import 'package:immosync/l10n/app_localizations.dart';

const String _tenantRevenueLabel = "CHF 3'250.00";
const String _tenantOutstandingLabel = '1 Ticket';
const IconData _tenantPrimaryActionIcon = Icons.payments_outlined;
const String _tenantPrimaryActionRoute = '/payments/make';
const bool _tenantPrimaryActionUsePush = true;

class TenantDashboard extends StatelessWidget {
  const TenantDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final quickActions = <QuickActionItem>[
      QuickActionItem(
        icon: Icons.folder_open_rounded,
        label: l10n.documents,
        route: '/documents',
      ),
      QuickActionItem(
        icon: Icons.credit_card_rounded,
        label: l10n.payments,
        route: '/payments/history',
      ),
      QuickActionItem(
        icon: Icons.build_circle_outlined,
        label: l10n.maintenance,
        route: '/tenant/maintenance',
      ),
      QuickActionItem(
        icon: Icons.support_agent,
        label: l10n.contactSupport,
        route: '/contact-support',
      ),
    ];

    final config = DashboardConfig(
      headerTitle: l10n.tenantDashboard,
      searchHint: l10n.searchPropertiesTenantsMessages,
      revenueLabel: _tenantRevenueLabel,
      revenueSubtitle: l10n.upcomingPayments,
      revenueAction: QuickActionItem(
        icon: Icons.credit_card_rounded,
        label: l10n.payments,
        route: '/payments/history',
      ),
      outstandingLabel: _tenantOutstandingLabel,
      outstandingSubtitle: l10n.maintenance,
      outstandingAction: QuickActionItem(
        icon: Icons.build_circle_outlined,
        label: l10n.maintenance,
        route: '/tenant/maintenance',
      ),
      primaryActionLabel: l10n.payRent,
      primaryActionIcon: _tenantPrimaryActionIcon,
      primaryActionRoute: _tenantPrimaryActionRoute,
      primaryActionUsePush: _tenantPrimaryActionUsePush,
      quickActions: quickActions,
    );

    return BentoDashboardScaffold(config: config);
  }
}
