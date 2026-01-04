import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/l10n/app_localizations.dart';
import '../providers/navigation_provider.dart';
import '../providers/dynamic_colors_provider.dart';
import '../../features/auth/presentation/providers/user_role_provider.dart';

class CommonBottomNav extends ConsumerWidget {
  const CommonBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(routeAwareNavigationProvider);
    final colors = ref.watch(dynamicColorsProvider);
    final userRole = ref.watch(userRoleProvider);

    // Update navigation index based on current route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentRoute = GoRouterState.of(context).uri.path;
      ref
          .read(routeAwareNavigationProvider.notifier)
          .updateFromRoute(currentRoute);
    });

    final theme = Theme.of(context).bottomNavigationBarTheme;

    return Container(
      padding: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: theme.backgroundColor ?? Colors.transparent,
        border: Border(
          top: BorderSide(
            color: colors.borderLight.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColorMedium.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex.clamp(0, 3),
        onTap: (index) {
          HapticFeedback.lightImpact();
          ref.read(routeAwareNavigationProvider.notifier).setIndex(index);

          // Navigate to the appropriate pages based on user role
          switch (index) {
            case 0: // Dashboard
              context.go('/home');
              break;
            case 1: // Properties/Documents (role-based)
              if (userRole == 'tenant') {
                context.go('/documents');
              } else {
                context.go('/properties');
              }
              break;
            case 2: // Messages
              context.go('/conversations');
              break;
            case 3: // Reports
              context.go('/reports');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: theme.selectedItemColor ?? colors.primaryAccent,
        unselectedItemColor: theme.unselectedItemColor ?? colors.textTertiary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: _buildNavigationItems(context, userRole, selectedIndex, colors),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildNavigationItems(BuildContext context,
      String userRole, int selectedIndex, dynamic colors) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _buildBottomNavItem(Icons.dashboard_outlined, Icons.dashboard,
          l10n.dashboard, 0, selectedIndex, colors),
      if (userRole == 'tenant')
        _buildBottomNavItem(Icons.folder_outlined, Icons.folder, l10n.documents,
            1, selectedIndex, colors)
      else
        _buildBottomNavItem(Icons.home_work_outlined, Icons.home_work,
            l10n.properties, 1, selectedIndex, colors),
      _buildBottomNavItem(Icons.chat_bubble_outline, Icons.chat_bubble,
          l10n.messages, 2, selectedIndex, colors),
      _buildBottomNavItem(Icons.analytics_outlined, Icons.analytics,
          l10n.reports, 3, selectedIndex, colors),
    ];
  }

  BottomNavigationBarItem _buildBottomNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
    int selectedIndex,
    dynamic colors,
  ) {
    final isSelected = selectedIndex == index;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding:
            EdgeInsets.symmetric(horizontal: isSelected ? 14 : 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryAccent.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? colors.primaryAccent.withValues(alpha: 0.25)
                : colors.borderLight.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? colors.primaryAccent : colors.textTertiary,
        ),
      ),
      label: label,
    );
  }
}
