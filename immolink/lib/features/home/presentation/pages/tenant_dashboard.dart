import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/core/widgets/common_bottom_nav.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/home/presentation/models/dashboard_design.dart';
import 'package:immosync/features/home/presentation/pages/classic_dashboard_shared.dart';
import 'package:immosync/features/home/presentation/pages/glass_dashboard_shared.dart';
import 'package:immosync/features/settings/providers/settings_provider.dart';

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

class TenantDashboard extends ConsumerWidget {
  const TenantDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = dashboardDesignFromId(
      ref.watch(settingsProvider).dashboardDesign,
    );

    switch (design) {
      case DashboardDesign.classic:
        return const _TenantDashboardClassic();
      case DashboardDesign.glass:
        return const _TenantDashboardGlass();
    }
  }
}

class _TenantDashboardGlass extends StatelessWidget {
  const _TenantDashboardGlass();

  @override
  Widget build(BuildContext context) {
    return const GlassDashboardScaffold(config: _tenantGlassConfig);
  }
}

class _TenantDashboardClassic extends ConsumerWidget {
  const _TenantDashboardClassic();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final rawName = (user?.fullName ?? '').trim();
    final greetingName = rawName.isEmpty ? 'Tenant' : rawName;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Dashboard',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.go('/notifications'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToRoute(
          context,
          route: _tenantPrimaryActionRoute,
          usePush: _tenantPrimaryActionUsePush,
        ),
        icon: const Icon(_tenantPrimaryActionIcon),
        label: const Text(_tenantPrimaryActionLabel),
      ),
      bottomNavigationBar: const CommonBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
          children: [
            ClassicGreetingCard(
              name: greetingName,
              headline: 'Welcome back',
              buttonLabel: 'Review upcoming rent',
              onTap: () => context.go('/payments/history'),
            ),
            const SizedBox(height: 20),
            const ClassicSearchField(
              hint: 'Search homes, payments, maintenance...',
            ),
            const SizedBox(height: 20),
            ClassicGradientCard(
              colors: const [
                Color(0xFF6A88FF),
                Color(0xFF9EA7FF),
              ],
              icon: Icons.payments_rounded,
              title: 'Payments Overview',
              subtitle: 'Stay on top of rent and utilities',
              child: Column(
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: ClassicMetricChip(
                          icon: Icons.calendar_month_rounded,
                          label: 'Due This Month',
                          value: _tenantRevenueLabel,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ClassicMetricChip(
                          icon: Icons.alarm_rounded,
                          label: 'Next Payment',
                          value: 'Due in 5 days',
                          valueColor: Color(0xFFFFF5D1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClassicActionTextButton(
                    label: 'Pay rent now',
                    onTap: () => _navigateToRoute(
                      context,
                      route: _tenantPrimaryActionRoute,
                      usePush: _tenantPrimaryActionUsePush,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ClassicGradientCard(
              colors: const [
                Color(0xFFFF9F7C),
                Color(0xFFFFC28D),
              ],
              icon: Icons.flash_on_rounded,
              title: 'Quick Actions',
              subtitle: 'Jump back into frequent tasks',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _tenantQuickActions
                    .map(
                      (item) => ClassicQuickActionButton(
                        icon: item.icon,
                        label: item.label,
                        onTap: () => _navigateToRoute(
                          context,
                          route: item.route,
                          usePush: item.usePush,
                          queryParameters: item.queryParameters,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            ClassicGradientCard(
              colors: const [
                Color(0xFF5AC8FA),
                Color(0xFF4FC0E8),
              ],
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Latest Messages',
              subtitle: 'Never miss an update from your landlord',
              child: Column(
                children: [
                  ..._tenantMessages.map(
                    (message) => ClassicListTile(
                      leadingIcon: Icons.mark_chat_unread_rounded,
                      leadingColor: message.color,
                      title: message.sender,
                      subtitle: message.preview,
                      trailingSecondaryText: message.time,
                      onTap: () => context.go('/conversations'),
                    ),
                  ),
                  ClassicActionTextButton(
                    label: 'Open inbox',
                    onTap: () => context.go('/conversations'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ClassicGradientCard(
              colors: const [
                Color(0xFF34D399),
                Color(0xFF3AA58C),
              ],
              icon: Icons.handyman_rounded,
              title: 'Maintenance Tracker',
              subtitle: 'Track progress on your requests',
              child: Column(
                children: [
                  ..._tenantMaintenance.map(
                    (item) => ClassicListTile(
                      leadingIcon: item.icon,
                      leadingColor: item.iconColor,
                      title: item.title,
                      subtitle: item.location,
                      trailingBadgeLabel: item.status,
                      trailingBadgeColor: item.statusColor,
                      trailingSecondaryText: item.updated,
                      onTap: () => context.go('/tenant/maintenance'),
                    ),
                  ),
                  ClassicActionTextButton(
                    label: 'View all requests',
                    onTap: () => context.go('/tenant/maintenance'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ClassicGradientCard(
              colors: const [
                Color(0xFF8B5CF6),
                Color(0xFFA78BFA),
              ],
              icon: Icons.folder_open_rounded,
              title: 'Documents & Leases',
              subtitle: 'Access your files anytime',
              child: Column(
                children: [
                  ..._tenantDocuments.map(
                    (doc) => ClassicListTile(
                      leadingIcon: doc.icon,
                      leadingColor: doc.iconColor,
                      title: doc.title,
                      subtitle: doc.description,
                      trailingBadgeLabel: doc.tag,
                      trailingBadgeColor: doc.tagColor,
                      onTap: () => context.go('/documents'),
                    ),
                  ),
                  ClassicActionTextButton(
                    label: 'View all documents',
                    onTap: () => context.go('/documents'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TenantMessageItem {
  const _TenantMessageItem({
    required this.sender,
    required this.preview,
    required this.time,
    required this.color,
  });

  final String sender;
  final String preview;
  final String time;
  final Color color;
}

class _TenantMaintenanceItem {
  const _TenantMaintenanceItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.location,
    required this.status,
    required this.statusColor,
    required this.updated,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String location;
  final String status;
  final Color statusColor;
  final String updated;
}

class _TenantDocumentItem {
  const _TenantDocumentItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.tag,
    required this.tagColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String tag;
  final Color tagColor;
}

const List<_TenantMessageItem> _tenantMessages = [
  _TenantMessageItem(
    sender: 'Property Services',
    preview: 'Your rent receipt for December is now available.',
    time: '1h ago',
    color: Color(0xFFB4E4FF),
  ),
  _TenantMessageItem(
    sender: 'Landlord',
    preview: 'Maintenance visit confirmed for Friday, 10:00.',
    time: 'Yesterday',
    color: Color(0xFFD7F5FF),
  ),
];

const List<_TenantMaintenanceItem> _tenantMaintenance = [
  _TenantMaintenanceItem(
    icon: Icons.water_damage_outlined,
    iconColor: Color(0xFFB3E5FC),
    title: 'Bathroom sink leak',
    location: 'Unit 3A • Bathroom',
    status: 'In progress',
    statusColor: Color(0xFFFFD166),
    updated: 'Updated 2h ago',
  ),
  _TenantMaintenanceItem(
    icon: Icons.bolt_rounded,
    iconColor: Color(0xFFFFDAD6),
    title: 'Kitchen power outlet',
    location: 'Unit 3A • Kitchen',
    status: 'Scheduled',
    statusColor: Color(0xFF60A5FA),
    updated: 'Technician arrives Thu',
  ),
];

const List<_TenantDocumentItem> _tenantDocuments = [
  _TenantDocumentItem(
    icon: Icons.description_rounded,
    iconColor: Color(0xFFD7C4FF),
    title: 'Lease Agreement',
    description: 'Signed • Expires Dec 2025',
    tag: 'Signed',
    tagColor: Color(0xFF34D399),
  ),
  _TenantDocumentItem(
    icon: Icons.shield_outlined,
    iconColor: Color(0xFFCCE7FF),
    title: 'Insurance Certificate',
    description: 'Updated • Valid through 2024',
    tag: 'New',
    tagColor: Color(0xFFFF8A65),
  ),
  _TenantDocumentItem(
    icon: Icons.sticky_note_2_outlined,
    iconColor: Color(0xFFFFF4CC),
    title: 'Move-in Checklist',
    description: 'Completed • September 2023',
    tag: 'Archive',
    tagColor: Color(0xFFCBD5F5),
  ),
];

void _navigateToRoute(
  BuildContext context, {
  required String route,
  bool usePush = false,
  Map<String, String>? queryParameters,
}) {
  final targetRoute = _buildRouteWithQuery(route, queryParameters);
  if (usePush) {
    context.push(targetRoute);
  } else {
    context.go(targetRoute);
  }
}

String _buildRouteWithQuery(
  String route,
  Map<String, String>? queryParameters,
) {
  if (queryParameters == null || queryParameters.isEmpty) {
    return route;
  }

  final queryString = queryParameters.entries
      .map(
        (entry) =>
            '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
      )
      .join('&');

  return route.contains('?') ? '$route&$queryString' : '$route?$queryString';
}
