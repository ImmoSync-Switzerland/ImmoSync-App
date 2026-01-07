import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/home/presentation/pages/bento_dashboard.dart';
import 'package:immosync/features/home/presentation/pages/glass_dashboard_shared.dart'
    show DashboardConfig, QuickActionItem;
import 'package:immosync/l10n/app_localizations.dart';

const String _tenantRevenueLabel = "CHF 3'250.00";
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
class TenantDashboard extends ConsumerWidget {
  const TenantDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(currentUserProvider);

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l10n.goodMorning
        : hour < 18
            ? l10n.hello
            : l10n.goodEvening;

    final fullName = (currentUser?.fullName ?? '').trim();
    final firstName =
        fullName.isEmpty ? '' : fullName.split(RegExp(r'\s+')).first;
    final greetingWithName =
        firstName.isEmpty ? greeting : '$greeting, $firstName';

    final config = DashboardConfig(
      headerTitle: greetingWithName,
      searchHint: l10n.searchTenantDashboardHint,
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
      quickActions: [
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
          label: l10n.support,
          route: '/contact-support',
        ),
      ],
    );

    return BentoDashboardScaffold(config: config);
  }
}
