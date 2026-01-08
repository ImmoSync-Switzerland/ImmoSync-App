import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:immosync/core/widgets/glass_nav_bar.dart';
import 'package:immosync/core/theme/app_typography.dart';

/// Lightweight quick action descriptor used by dashboard UIs.
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

/// Shared dashboard configuration consumed by Bento + legacy glass layouts.
class DashboardConfig {
  const DashboardConfig({
    required this.headerTitle,
    required this.searchHint,
    required this.revenueLabel,
    required this.revenueSubtitle,
    this.revenueTrend,
    this.revenueAction,
    required this.outstandingLabel,
    required this.outstandingSubtitle,
    this.outstandingTrend,
    this.outstandingAction,
    required this.primaryActionLabel,
    required this.primaryActionIcon,
    this.primaryActionRoute,
    this.primaryActionUsePush = false,
    this.primaryActionQueryParameters,
    this.quickActions = const [],
  });

  final String headerTitle;
  final String searchHint;
  final String revenueLabel;
  final String revenueSubtitle;
  final String? revenueTrend;
  final QuickActionItem? revenueAction;
  final String outstandingLabel;
  final String outstandingSubtitle;
  final String? outstandingTrend;
  final QuickActionItem? outstandingAction;
  final String primaryActionLabel;
  final IconData primaryActionIcon;
  final String? primaryActionRoute;
  final bool primaryActionUsePush;
  final Map<String, String>? primaryActionQueryParameters;
  final List<QuickActionItem> quickActions;
}

/// Simple glassy container with blur + subtle border.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.border,
    this.blur = 16,
    this.blurSigma,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final BoxBorder? border;
  final double blur;
  final double? blurSigma;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = borderRadius ?? BorderRadius.circular(18);
    final sigma = blurSigma ?? blur;
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color:
                  (color ?? theme.colorScheme.surface).withValues(alpha: 0.16),
              borderRadius: radius,
              border: border ??
                  Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Page scaffold with a blurred background and optional glass bottom nav.
class GlassPageScaffold extends StatelessWidget {
  const GlassPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onBack,
    this.actions,
    this.floatingActionButton,
    this.showBottomNav = true,
    this.padding,
  });

  final String title;
  final Widget body;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBottomNav;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      bottomNavigationBar: showBottomNav ? const AppGlassNavBar() : null,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          const GlassBackground(),
          SafeArea(
            child: Padding(
              padding: padding ?? const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GlassHeader(title: title, onBack: onBack, actions: actions),
                  const SizedBox(height: 16),
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

class _GlassHeader extends StatelessWidget {
  const _GlassHeader({required this.title, this.onBack, this.actions});

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null)
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
            onPressed: onBack,
          ),
        Text(
          title,
          style: AppTypography.pageTitle.copyWith(color: Colors.white),
        ),
        const Spacer(),
        if (actions != null) ...actions!,
      ],
    );
  }
}

/// Blurred gradient backdrop for glass-styled pages.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A1128),
                Color(0xFF0D0F1A),
                Colors.black,
              ],
            ),
          ),
        ),
        Positioned(
          left: -120,
          top: -80,
          child: _GlowOrb(
            color: const Color(0xFF7C9CFF).withValues(alpha: 0.28),
            size: 320,
          ),
        ),
        Positioned(
          right: -90,
          bottom: 40,
          child: _GlowOrb(
            color: const Color(0xFF8AE0FF).withValues(alpha: 0.22),
            size: 280,
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: const SizedBox(),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.05), Colors.transparent],
          stops: const [0, 0.45, 1],
        ),
      ),
    );
  }
}
