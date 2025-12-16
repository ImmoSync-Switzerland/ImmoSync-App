import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:immosync/core/providers/navigation_provider.dart';
import 'package:immosync/features/auth/presentation/providers/user_role_provider.dart';
import 'package:immosync/l10n/app_localizations.dart';

class DashboardConfig {
  const DashboardConfig({
    required this.headerTitle,
    required this.searchHint,
    required this.revenueLabel,
    required this.revenueSubtitle,
    required this.outstandingLabel,
    required this.outstandingSubtitle,
    required this.primaryActionLabel,
    required this.primaryActionIcon,
    required this.quickActions,
    this.primaryActionRoute,
    this.primaryActionUsePush = false,
    this.primaryActionQueryParameters,
    this.revenueAction,
    this.outstandingAction,
  });

  final String headerTitle;
  final String searchHint;
  final String revenueLabel;
  final String revenueSubtitle;
  final String outstandingLabel;
  final String outstandingSubtitle;
  final String primaryActionLabel;
  final IconData primaryActionIcon;
  final List<QuickActionItem> quickActions;
  final String? primaryActionRoute;
  final bool primaryActionUsePush;
  final Map<String, String>? primaryActionQueryParameters;
  final QuickActionItem? revenueAction;
  final QuickActionItem? outstandingAction;
}

class QuickActionItem {
  const QuickActionItem({
    required this.icon,
    required this.label,
    required this.route,
    this.usePush = false,
    this.queryParameters,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool usePush;
  final Map<String, String>? queryParameters;
}

class GlassDashboardScaffold extends StatelessWidget {
  const GlassDashboardScaffold({
    super.key,
    required this.config,
  });

  final DashboardConfig config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        foregroundColor: Colors.black87,
        elevation: 0,
        onPressed: () => _handlePrimaryAction(context),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.only(bottom: 24, left: 24, right: 24),
        child: GlassBottomNavBar(),
      ),
      body: Stack(
        children: [
          const _MeshGradientBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.headerTitle,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SearchBar(hintText: config.searchHint),
                  const SizedBox(height: 32),
                  Text(
                    'Financial Overview',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          context: context,
                          icon: Icons.trending_up_rounded,
                          label: config.revenueLabel,
                          subtitle: config.revenueSubtitle,
                          action: config.revenueAction,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricTile(
                          context: context,
                          icon: Icons.notification_important_rounded,
                          label: config.outstandingLabel,
                          subtitle: config.outstandingSubtitle,
                          action: config.outstandingAction,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  GlassContainer(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _PrimaryActionButton(
                          label: config.primaryActionLabel,
                          icon: config.primaryActionIcon,
                          onTap: () => _handlePrimaryAction(context),
                        ),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const double spacing = 12;
                            final int columns = constraints.maxWidth > 900
                                ? 4
                                : constraints.maxWidth > 600
                                    ? 3
                                    : 2;
                            final double itemWidth = (constraints.maxWidth -
                                    spacing * (columns - 1)) /
                                columns;

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: config.quickActions
                                  .map(
                                    (item) => SizedBox(
                                      width: itemWidth,
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: _QuickActionTile(
                                          item: item,
                                          onTap: () => _handleQuickActionTap(
                                            context,
                                            item,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    QuickActionItem? action,
  }) {
    return GlassContainer(
      constraints: const BoxConstraints(minHeight: 150),
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: action != null
              ? () => _handleQuickActionTap(context, action)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _MetricCard(
              icon: icon,
              label: label,
              subtitle: subtitle,
            ),
          ),
        ),
      ),
    );
  }

  void _handlePrimaryAction(BuildContext context) {
    if (config.primaryActionRoute == null) {
      return;
    }

    _navigate(
      context,
      route: config.primaryActionRoute!,
      usePush: config.primaryActionUsePush,
      queryParameters: config.primaryActionQueryParameters,
    );
  }

  void _handleQuickActionTap(BuildContext context, QuickActionItem item) {
    _navigate(
      context,
      route: item.route,
      usePush: item.usePush,
      queryParameters: item.queryParameters,
    );
  }

  void _navigate(
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
        .map((entry) =>
            '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}')
        .join('&');

    return route.contains('?') ? '$route&$queryString' : '$route?$queryString';
  }
}

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.constraints,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: width,
          height: height,
          constraints: constraints,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

const EdgeInsets _glassNavBarPadding =
    EdgeInsets.symmetric(vertical: 14, horizontal: 24);

class GlassBottomNavBar extends ConsumerWidget {
  const GlassBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(routeAwareNavigationProvider);
    final userRole = ref.watch(userRoleProvider);
    final l10n = AppLocalizations.of(context)!;
    final items = _buildGlassNavItems(userRole, l10n);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentRoute = GoRouterState.of(context).uri.path;
      ref
          .read(routeAwareNavigationProvider.notifier)
          .updateFromRoute(currentRoute);
    });

    return GlassContainer(
      padding: _glassNavBarPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final isActive = index == selectedIndex;

          return _NavItem(
            icon: data.icon,
            label: data.label,
            isActive: isActive,
            onTap: () {
              if (selectedIndex == index) {
                return;
              }
              ref.read(routeAwareNavigationProvider.notifier).setIndex(index);
              context.go(data.route);
            },
          );
        }).toList(),
      ),
    );
  }
}

class _GlassNavEntry {
  const _GlassNavEntry({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;
}

List<_GlassNavEntry> _buildGlassNavItems(
  String userRole,
  AppLocalizations l10n,
) {
  final bool isTenant = userRole == 'tenant';

  return [
    _GlassNavEntry(
      icon: Icons.dashboard_rounded,
      label: l10n.dashboard,
      route: '/home',
    ),
    _GlassNavEntry(
      icon: isTenant ? Icons.folder_outlined : Icons.maps_home_work_rounded,
      label: isTenant ? l10n.documents : l10n.properties,
      route: isTenant ? '/documents' : '/properties',
    ),
    _GlassNavEntry(
      icon: Icons.message_outlined,
      label: l10n.messages,
      route: '/conversations',
    ),
    _GlassNavEntry(
      icon: Icons.insert_chart_outlined,
      label: l10n.reports,
      route: '/reports',
    ),
    _GlassNavEntry(
      icon: Icons.person_outline_rounded,
      label: l10n.profile,
      route: '/profile',
    ),
  ];
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Colors.white;
    final Color inactiveColor = Colors.white.withValues(alpha: 0.65);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.hintText});

  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        style: GoogleFonts.poppins(
          color: Colors.black87,
          fontSize: 14,
        ),
        cursorColor: Colors.black54,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
          prefixIcon:
              Icon(Icons.search_rounded, color: Colors.grey.shade600, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 18),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.15),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.item,
    required this.onTap,
  });

  final QuickActionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeshGradientBackground extends StatelessWidget {
  const _MeshGradientBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key});

  @override
  Widget build(BuildContext context) => const _MeshGradientBackground();
}

class GlassPageScaffold extends StatelessWidget {
  const GlassPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBottomNav = true,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 24),
    this.onBack,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBottomNav;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onBack;

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: showBottomNav
          ? const Padding(
              padding: EdgeInsets.only(bottom: 24, left: 24, right: 24),
              child: GlassBottomNavBar(),
            )
          : null,
      body: Stack(
        children: [
          const GlassBackground(),
          SafeArea(
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _handleBack(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (actions != null && actions!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          for (var i = 0; i < actions!.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            actions![i],
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(child: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
