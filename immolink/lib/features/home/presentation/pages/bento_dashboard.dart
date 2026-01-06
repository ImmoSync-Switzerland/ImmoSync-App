import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:immosync/core/localization/app_translations.dart';
import 'package:immosync/core/widgets/glass_nav_bar.dart';
import 'package:immosync/features/home/presentation/pages/glass_dashboard_shared.dart'
    show DashboardConfig, QuickActionItem;

/// Bento-styled dashboard scaffold for the landlord experience.
/// Replaces the previous glassmorphism look with crisp, high-contrast tiles.
class BentoDashboardScaffold extends StatelessWidget {
  const BentoDashboardScaffold({
    super.key,
    required this.config,
  });

  final DashboardConfig config;

  static const _borderGradient = [
    Color(0x26FFFFFF), // white @ 0.15 opacity
    Colors.transparent,
  ];
  static const _spacing = 16.0;

  @override
  Widget build(BuildContext context) {
    final quickActions = _dedupQuickActions(config.quickActions);

    final QuickActionItem? messagesAction = _findAction(
          quickActions,
          (action) => action.label.toLowerCase().contains('message'),
        ) ??
        (quickActions.isNotEmpty ? quickActions.first : null);
    final QuickActionItem? statsAction = _findAction(
          quickActions,
          (action) =>
              action.label.toLowerCase().contains('report') ||
              action.label.toLowerCase().contains('stat'),
        ) ??
        (quickActions.length > 1 ? quickActions[1] : null);
    final restActions = quickActions
        .where((a) => a != messagesAction && a != statsAction)
        .toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 0,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: const AppGlassNavBar(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _BentoBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    greeting:
                        '${AppTranslations.of(context, 'dashboard.goodMorning')}, Fabian',
                    subtitle: AppTranslations.of(context, 'nav.dashboard'),
                  ),
                  const SizedBox(height: 16),
                  _DashboardSearchBar(hint: config.searchHint),
                  const SizedBox(height: 16),
                  if (_isLandlordQuickActions(config)) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _GlowQuickActionTile(
                            color: const Color(0xFF22D3EE),
                            icon: Icons.add_home_work_rounded,
                            title: 'Add Property',
                            subtitle: 'New Portfolio',
                            onTap: () => _navigate(
                              context,
                              route:
                                  config.primaryActionRoute ?? '/add-property',
                              usePush: config.primaryActionUsePush,
                              queryParameters:
                                  config.primaryActionQueryParameters,
                            ),
                          ),
                          const SizedBox(width: 14),
                          _GlowQuickActionTile(
                            color: const Color(0xFF34D399),
                            icon: Icons.person_add_alt_1_rounded,
                            title: 'Add Tenant',
                            subtitle: 'Assign Unit',
                            onTap: () => _navigate(
                              context,
                              route: '/tenants',
                              usePush: false,
                            ),
                          ),
                          const SizedBox(width: 14),
                          _GlowQuickActionTile(
                            color: const Color(0xFFFBBF24),
                            icon: Icons.handyman_rounded,
                            title: 'Maintenance',
                            subtitle: '3 Tickets',
                            onTap: () => _navigate(
                              context,
                              route: '/maintenance/manage',
                              usePush: false,
                            ),
                          ),
                          const SizedBox(width: 14),
                          _GlowQuickActionTile(
                            color: const Color(0xFFA855F7),
                            icon: Icons.chat_bubble_rounded,
                            title: 'Messages',
                            subtitle: '2 Unread',
                            onTap: () => _navigate(
                              context,
                              route: '/conversations',
                              usePush: false,
                            ),
                          ),
                          const SizedBox(width: 14),
                          _GlowQuickActionTile(
                            color: const Color(0xFF60A5FA),
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Payments',
                            subtitle: 'Overview',
                            onTap: () => _navigate(
                              context,
                              route: '/landlord/payments',
                              usePush: false,
                            ),
                          ),
                          const SizedBox(width: 14),
                          _GlowQuickActionTile(
                            color: const Color(0xFFFB7185),
                            icon: Icons.subscriptions_outlined,
                            title: 'Subscription',
                            subtitle: 'Plan',
                            onTap: () => _navigate(
                              context,
                              route: '/subscription/management',
                              usePush: false,
                            ),
                          ),
                          const SizedBox(width: 14),
                          _GlowQuickActionTile(
                            color: const Color(0xFF38BDF8),
                            icon: Icons.folder_open_rounded,
                            title: 'Documents',
                            subtitle: 'Files',
                            onTap: () => _navigate(
                              context,
                              route: '/landlord/documents',
                              usePush: false,
                            ),
                          ),
                          const SizedBox(width: 14),
                          _GlowQuickActionTile(
                            color: const Color(0xFFA3E635),
                            icon: Icons.design_services_outlined,
                            title: 'Services',
                            subtitle: 'Bookings',
                            onTap: () => _navigate(
                              context,
                              route: '/landlord/services',
                              usePush: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    _SectionTitle(
                      text: AppTranslations.of(
                        context,
                        'dashboard.quickActions',
                      ),
                    ),
                    const SizedBox(height: _spacing),
                    _PrimaryActionTile(
                      label: config.primaryActionLabel,
                      icon: config.primaryActionIcon,
                      onTap: () => _handlePrimaryAction(context),
                    ),
                    const SizedBox(height: _spacing),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionTile(
                            label: messagesAction?.label ?? 'Messages',
                            icon: messagesAction?.icon ?? Icons.message_rounded,
                            accent: const Color(0xFF8AB4FF),
                            onTap: messagesAction == null
                                ? null
                                : () => _handleQuickActionTap(
                                      context,
                                      messagesAction,
                                    ),
                          ),
                        ),
                        const SizedBox(width: _spacing),
                        Expanded(
                          child: _QuickActionTile(
                            label: statsAction?.label ?? 'Statistics',
                            icon: statsAction?.icon ?? Icons.bar_chart_rounded,
                            accent: const Color(0xFF7AE3C3),
                            onTap: statsAction == null
                                ? null
                                : () => _handleQuickActionTap(
                                      context,
                                      statsAction,
                                    ),
                          ),
                        ),
                      ],
                    ),
                    if (restActions.isNotEmpty) ...[
                      const SizedBox(height: _spacing),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const double spacing = 12;
                          final int columns = constraints.maxWidth > 900
                              ? 4
                              : constraints.maxWidth > 640
                                  ? 3
                                  : 2;
                          final double itemWidth =
                              (constraints.maxWidth - spacing * (columns - 1)) /
                                  columns;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: restActions
                                .map(
                                  (item) => SizedBox(
                                    width: itemWidth,
                                    child: _QuickActionTile(
                                      label: item.label,
                                      icon: item.icon,
                                      accent: const Color(0xFF99A8FF),
                                      onTap: () => _handleQuickActionTap(
                                        context,
                                        item,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ],
                  const SizedBox(height: 28),
                  _SectionTitle(
                    text: AppTranslations.of(
                      context,
                      'dashboard.revenueChart',
                    ),
                  ),
                  const SizedBox(height: _spacing),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          title: config.revenueSubtitle,
                          value: config.revenueLabel,
                          trend: config.revenueTrend ?? '+4.2% MoM',
                          trendColor: const Color(0xFF10B981),
                          icon: Icons.trending_up_rounded,
                          iconColor: const Color(0xFF10B981),
                          shadow: const BoxShadow(
                            color: Color(0x3310B981),
                            blurRadius: 25,
                            spreadRadius: -5,
                            offset: Offset(0, 10),
                          ),
                          onTap: config.revenueAction == null
                              ? null
                              : () => _handleQuickActionTap(
                                    context,
                                    config.revenueAction!,
                                  ),
                        ),
                      ),
                      const SizedBox(width: _spacing),
                      Expanded(
                        child: _MetricTile(
                          title: config.outstandingSubtitle,
                          value: config.outstandingLabel,
                          trend: config.outstandingTrend ?? '-0.8% WoW',
                          trendColor: const Color(0xFF3B82F6),
                          icon: Icons.notifications_active_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          shadow: const BoxShadow(
                            color: Color(0x333B82F6),
                            blurRadius: 25,
                            spreadRadius: -5,
                            offset: Offset(0, 10),
                          ),
                          onTap: config.outstandingAction == null
                              ? null
                              : () => _handleQuickActionTap(
                                    context,
                                    config.outstandingAction!,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _SectionTitle(
                    text: AppTranslations.of(
                      context,
                      'dashboard.recentActivity',
                    ),
                  ),
                  const SizedBox(height: _spacing),
                  _BentoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppTranslations.of(
                            context,
                            'empty.noRecentActivity',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppTranslations.of(
                            context,
                            'empty.activityDescription',
                          ),
                          style: const TextStyle(
                            color: Color(0xB3FFFFFF),
                            fontSize: 13,
                            height: 1.35,
                          ),
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

  void _handlePrimaryAction(BuildContext context) {
    if (config.primaryActionRoute == null) return;
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

  bool _isLandlordQuickActions(DashboardConfig config) {
    return config.headerTitle.toLowerCase().contains('landlord');
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

  List<QuickActionItem> _dedupQuickActions(List<QuickActionItem> items) {
    final String normalizedPrimary =
        config.primaryActionLabel.toLowerCase().trim();
    final Set<String> seen = {};

    return items.where((item) {
      final normalizedLabel = item.label.toLowerCase().trim();
      final key = '$normalizedLabel|${item.route}|${item.usePush}';

      if (normalizedLabel == normalizedPrimary) {
        return false;
      }

      if (seen.contains(key)) {
        return false;
      }

      seen.add(key);
      return true;
    }).toList();
  }

  QuickActionItem? _findAction(
    List<QuickActionItem> actions,
    bool Function(QuickActionItem) predicate,
  ) {
    for (final action in actions) {
      if (predicate(action)) return action;
    }
    return null;
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
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.subtitle,
  });

  final String greeting;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        _ProfileButton(onTap: () => context.go('/profile')),
      ],
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2A2A2A),
              Color(0xFF161616),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.person_outline,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 12,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.6),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    required this.trend,
    required this.trendColor,
    required this.icon,
    required this.iconColor,
    required this.shadow,
    this.onTap,
  });

  final String title;
  final String value;
  final String trend;
  final Color trendColor;
  final IconData icon;
  final Color iconColor;
  final BoxShadow shadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _BentoCard(
      shadow: shadow,
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _IconBadge(icon: icon, color: iconColor),
              const SizedBox(width: 12),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _TrendPill(
                    label: trend,
                    color: trendColor.withValues(alpha: 0.16),
                    textColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              letterSpacing: 1.1,
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionTile extends StatelessWidget {
  const _PrimaryActionTile({
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _BentoCard(
      shadow: const BoxShadow(
        color: Color(0x4D3B82F6),
        blurRadius: 28,
        spreadRadius: -4,
        offset: Offset(0, 12),
      ),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          _IconBadge(
            icon: icon,
            color: const Color(0xFF7AE3C3),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add a new listing or unit to your portfolio',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.label,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: _BentoCard(
        shadow: BoxShadow(
          color: accent.withValues(alpha: 0.28),
          blurRadius: 22,
          spreadRadius: -6,
          offset: const Offset(0, 10),
        ),
        onTap: onTap,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconBadge(icon: icon, color: accent),
            const Spacer(),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Open',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowQuickActionTile extends StatelessWidget {
  const _GlowQuickActionTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const double radius = 22;
    const dark = Color(0xFF1C1C1E);

    return SizedBox(
      width: 150,
      height: 150,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.22),
              blurRadius: 26,
              spreadRadius: -10,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.15),
                    dark,
                  ],
                ),
                border: Border.all(
                  color: color.withValues(alpha: 0.30),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GlowIconBubble(color: color, icon: icon),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowIconBubble extends StatelessWidget {
  const _GlowIconBubble({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.20),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 18,
            spreadRadius: -8,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}

class _DashboardSearchBar extends StatefulWidget {
  const _DashboardSearchBar({required this.hint});

  final String hint;

  @override
  State<_DashboardSearchBar> createState() => _DashboardSearchBarState();
}

class _DashboardSearchBarState extends State<_DashboardSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openSearch(String rawQuery) {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      context.push('/search');
      return;
    }

    context.push('/search?q=${Uri.encodeComponent(query)}');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      onSubmitted: _openSearch,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1C1C1E),
        hintText: widget.hint,
        hintStyle: GoogleFonts.inter(
          color: Colors.white54,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Colors.white54,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.shadow,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final BoxShadow? shadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const double radius = 22;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: BentoDashboardScaffold._borderGradient,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          if (shadow != null) shadow!,
        ],
      ),
      padding: const EdgeInsets.all(1),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1C1C1E),
              Color(0xFF141414),
            ],
          ),
          borderRadius: BorderRadius.circular(radius - 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(radius - 1),
            onTap: onTap,
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24, maxHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.9),
            color.withValues(alpha: 0.65),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: RichText(
        text: TextSpan(
          children: _buildTextSpans(label, textColor),
        ),
      ),
    );
  }

  List<InlineSpan> _buildTextSpans(String text, Color color) {
    final parts = text.split(' ');
    if (parts.length < 2) {
      return [
        TextSpan(
          text: text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ];
    }

    final suffix = parts.removeLast();
    final prefix = parts.join(' ');

    return [
      TextSpan(
        text: '$prefix ',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      TextSpan(
        text: suffix,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color.withValues(alpha: 0.85),
        ),
      ),
    ];
  }
}

class _BentoBackground extends StatelessWidget {
  const _BentoBackground();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A1128),
              Color(0xFF050505),
            ],
          ),
        ),
        child: Stack(
          children: [
            _GlowOrb(
              color: Color(0x3310B981),
              size: 420,
              offset: Offset(-80, -60),
              blur: 120,
            ),
            _GlowOrb(
              color: Color(0x333B82F6),
              size: 480,
              offset: Offset(-50, 420),
              blur: 140,
            ),
            _GlowOrb(
              color: Color(0x332E1065),
              size: 360,
              offset: Offset(200, 520),
              blur: 120,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.color,
    required this.size,
    required this.offset,
    required this.blur,
  });

  final Color color;
  final double size;
  final Offset offset;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
