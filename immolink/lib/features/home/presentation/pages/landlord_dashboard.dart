import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/core/widgets/common_bottom_nav.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/home/presentation/models/dashboard_design.dart';
import 'package:immosync/features/home/presentation/pages/classic_dashboard_shared.dart';
import 'package:immosync/features/home/presentation/pages/glass_dashboard_shared.dart';
import 'package:immosync/features/settings/providers/settings_provider.dart';

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
    icon: Icons.add_home_work_rounded,
    label: 'Add Property',
    route: '/add-property',
    usePush: true,
  ),
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
    route: '/subscription/landlord',
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
  revenueAction: QuickActionItem(
    icon: Icons.insert_chart_outlined_rounded,
    label: 'Reports',
    route: '/reports',
  ),
  outstandingLabel: _landlordOutstandingLabel,
  outstandingSubtitle: _landlordOutstandingSubtitle,
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

class LandlordDashboard extends ConsumerWidget {
  const LandlordDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = dashboardDesignFromId(
      ref.watch(settingsProvider).dashboardDesign,
    );

    switch (design) {
      case DashboardDesign.classic:
        return const _LandlordDashboardClassic();
      case DashboardDesign.glass:
        return const _LandlordDashboardGlass();
    }
  }
}

class _LandlordDashboardGlass extends StatelessWidget {
  const _LandlordDashboardGlass();

  @override
  Widget build(BuildContext context) {
    return const GlassDashboardScaffold(config: _landlordGlassConfig);
  }
}

class _LandlordDashboardClassic extends ConsumerWidget {
  const _LandlordDashboardClassic();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final rawName = (user?.fullName ?? '').trim();
    final greetingName = rawName.isEmpty ? 'Landlord' : rawName;

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
          route: _landlordPrimaryActionRoute,
          usePush: _landlordPrimaryActionUsePush,
        ),
        icon: const Icon(_landlordPrimaryActionIcon),
        label: const Text(_landlordPrimaryActionLabel),
      ),
      bottomNavigationBar: const CommonBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
          children: [
            ClassicGreetingCard(
              name: greetingName,
              headline: 'Good morning',
              buttonLabel: 'Manage your portfolio',
              onTap: () => context.go('/properties'),
            ),
            const SizedBox(height: 20),
            const ClassicSearchField(
              hint: 'Search properties, tenants, maintenance...',
            ),
            const SizedBox(height: 20),
            ClassicGradientCard(
              colors: const [
                Color(0xFF33C4FF),
                Color(0xFF55E3FF),
              ],
              icon: Icons.pie_chart_rounded,
              title: 'Financial Overview',
              subtitle: 'Snapshot of monthly performance',
              child: Column(
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: ClassicMetricChip(
                          icon: Icons.trending_up_rounded,
                          label: 'Monthly Revenue',
                          value: _landlordRevenueLabel,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ClassicMetricChip(
                          icon: Icons.warning_amber_rounded,
                          label: 'Outstanding',
                          value: _landlordOutstandingLabel,
                          valueColor: Color(0xFFFFF5D1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClassicActionTextButton(
                    label: 'View detailed reports',
                    onTap: () => context.go('/reports'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ClassicGradientCard(
              colors: const [
                Color(0xFFFF855B),
                Color(0xFFFFB36F),
              ],
              icon: Icons.flash_on_rounded,
              title: 'Quick Actions',
              subtitle: 'Access your most used tasks',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _landlordQuickActions
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
                Color(0xFF43C6AC),
                Color(0xFF2BB1A3),
              ],
              icon: Icons.message_rounded,
              title: 'Recent Messages',
              subtitle: 'Stay connected with your tenants',
              child: Column(
                children: [
                  ..._sampleMessages.map(
                    (message) => ClassicListTile(
                      leadingIcon: Icons.chat_bubble_outline_rounded,
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
                Color(0xFFFF6F61),
                Color(0xFFFF9069),
              ],
              icon: Icons.build_circle_outlined,
              title: 'Maintenance Requests',
              subtitle: 'Keep track of open issues',
              child: Column(
                children: [
                  ..._sampleMaintenance.map(
                    (item) => ClassicListTile(
                      leadingIcon: item.icon,
                      leadingColor: item.iconColor,
                      title: item.title,
                      subtitle: item.location,
                      trailingBadgeLabel: item.priority,
                      trailingBadgeColor: item.priorityColor,
                      onTap: () => context.go('/maintenance/manage'),
                    ),
                  ),
                  ClassicActionTextButton(
                    label: 'View all requests',
                    onTap: () => context.go('/maintenance/manage'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ClassicGradientCard(
              colors: const [
                Color(0xFF5B6CFF),
                Color(0xFF7F8BFF),
              ],
              icon: Icons.home_work_rounded,
              title: 'Properties',
              subtitle: 'Portfolio at a glance',
              child: Column(
                children: [
                  ..._sampleProperties.map(
                    (property) => ClassicListTile(
                      leadingIcon: property.icon,
                      leadingColor: property.iconColor,
                      title: property.title,
                      subtitle: property.location,
                      trailingBadgeLabel: property.status,
                      trailingBadgeColor: property.statusColor,
                      trailingSecondaryText: property.amount,
                      onTap: () => context.go('/properties'),
                    ),
                  ),
                  ClassicActionTextButton(
                    label: 'Manage properties',
                    onTap: () => context.go('/properties'),
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

class _ClassicPropertyItem {
  const _ClassicPropertyItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.location,
    required this.amount,
    required this.status,
    required this.statusColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String location;
  final String amount;
  final String status;
  final Color statusColor;
}

class _ClassicMaintenanceItem {
  const _ClassicMaintenanceItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.location,
    required this.priority,
    required this.priorityColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String location;
  final String priority;
  final Color priorityColor;
}

class _ClassicMessageItem {
  const _ClassicMessageItem({
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

const List<_ClassicPropertyItem> _sampleProperties = [
  _ClassicPropertyItem(
    icon: Icons.apartment_rounded,
    iconColor: Color(0xFFB2C6FF),
    title: 'Hinterkirchweg 12',
    location: 'Basel, CH',
    amount: "CHF 2'500.00 / mo",
    status: 'Rented',
    statusColor: Color(0xFF3DD598),
  ),
  _ClassicPropertyItem(
    icon: Icons.holiday_village_rounded,
    iconColor: Color(0xFFD7C4FF),
    title: 'Seeblickstrasse 4',
    location: 'Luzern, CH',
    amount: "CHF 3'120.00 / mo",
    status: 'Vacant',
    statusColor: Color(0xFFFFD166),
  ),
  _ClassicPropertyItem(
    icon: Icons.house_rounded,
    iconColor: Color(0xFFB6E6FF),
    title: 'Bahnhofstrasse 87',
    location: 'Zürich, CH',
    amount: "CHF 4'550.00 / mo",
    status: 'Rented',
    statusColor: Color(0xFF3DD598),
  ),
];

const List<_ClassicMaintenanceItem> _sampleMaintenance = [
  _ClassicMaintenanceItem(
    icon: Icons.thermostat_rounded,
    iconColor: Color(0xFFFFD5D8),
    title: 'Heating malfunction',
    location: 'Riehen, Basel',
    priority: 'Urgent',
    priorityColor: Color(0xFFF95F62),
  ),
  _ClassicMaintenanceItem(
    icon: Icons.lightbulb_outline,
    iconColor: Color(0xFFFFECD6),
    title: 'Entrance lighting issue',
    location: 'Liestal',
    priority: 'Medium',
    priorityColor: Color(0xFFFFA940),
  ),
];

const List<_ClassicMessageItem> _sampleMessages = [
  _ClassicMessageItem(
    sender: 'Thomas Berger',
    preview: 'Could we schedule a visit for next week?',
    time: '2h ago',
    color: Color(0xFFB4E4FF),
  ),
  _ClassicMessageItem(
    sender: 'Apartment 4B',
    preview: 'Thank you for the quick support!',
    time: 'Yesterday',
    color: Color(0xFFD7F5FF),
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
