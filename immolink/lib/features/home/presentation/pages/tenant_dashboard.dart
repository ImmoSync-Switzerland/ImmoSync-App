import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/home/presentation/pages/bento_dashboard.dart';
import 'package:immosync/features/home/presentation/pages/glass_dashboard_shared.dart'
    show DashboardConfig, QuickActionItem;
import 'package:immosync/features/maintenance/presentation/providers/maintenance_providers.dart';
import 'package:immosync/l10n/app_localizations.dart';

const String _tenantRevenueLabel = "CHF 3'250.00";
const IconData _tenantPrimaryActionIcon = Icons.payments_outlined;
const String _tenantPrimaryActionRoute = '/payments/make';
const bool _tenantPrimaryActionUsePush = true;

class TenantDashboard extends ConsumerWidget {
  const TenantDashboard({super.key});

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

    final maintenanceAsync = ref.watch(tenantMaintenanceRequestsProvider);
    final outstandingLabel = maintenanceAsync.maybeWhen(
      data: (requests) {
        final openCount = requests.where((r) {
          final status = r.status.toLowerCase();
          return status == 'pending' || status == 'in_progress';
        }).length;
        return openCount.toString();
      },
      orElse: () => '0',
    );

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
      headerTitle: _greetingWithName(l10n, currentUser?.fullName),
      searchHint: l10n.searchPropertiesTenantsMessages,
      revenueLabel: _tenantRevenueLabel,
      revenueSubtitle: l10n.upcomingPayments,
      revenueTrend: null,
      revenueAction: QuickActionItem(
        icon: Icons.credit_card_rounded,
        label: l10n.payments,
        route: '/payments/history',
      ),
      outstandingLabel: outstandingLabel,
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
