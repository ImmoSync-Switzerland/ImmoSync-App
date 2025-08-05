import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../providers/navigation_provider.dart';

class CommonBottomNav extends ConsumerWidget {
  const CommonBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(routeAwareNavigationProvider);
    
    // Update navigation index based on current route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentRoute = GoRouterState.of(context).uri.path;
      ref.read(routeAwareNavigationProvider.notifier).updateFromRoute(currentRoute);
    });
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryBackground,
            AppColors.luxuryGradientStart,
          ],
        ),
        border: Border(
          top: BorderSide(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColorMedium,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          HapticFeedback.lightImpact();
          ref.read(routeAwareNavigationProvider.notifier).setIndex(index);
          
          // Navigate to the appropriate pages
          switch (index) {
            case 0: // Dashboard
              context.go('/home');
              break;
            case 1: // Properties
              context.go('/properties');
              break;
            case 2: // Messages
              context.go('/conversations');
              break;
            case 3: // Reports
              context.go('/reports');
              break;
            case 4: // Profile
              context.go('/settings');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primaryAccent,
        unselectedItemColor: AppColors.textTertiary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          _buildBottomNavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 0, selectedIndex),
          _buildBottomNavItem(Icons.home_work_outlined, Icons.home_work, 'Properties', 1, selectedIndex),
          _buildBottomNavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'Messages', 2, selectedIndex),
          _buildBottomNavItem(Icons.analytics_outlined, Icons.analytics, 'Reports', 3, selectedIndex),
          _buildBottomNavItem(Icons.person_outline, Icons.person, 'Profile', 4, selectedIndex),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem(
    IconData icon, 
    IconData activeIcon, 
    String label, 
    int index, 
    int selectedIndex
  ) {
    final isSelected = selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryAccent.withValues(alpha: 0.1),
              AppColors.primaryAccent.withValues(alpha: 0.05),
            ],
          ) : null,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(
            color: AppColors.primaryAccent.withValues(alpha: 0.2),
            width: 1,
          ) : null,
        ),
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? AppColors.primaryAccent : AppColors.textTertiary,
        ),
      ),
      label: label,
    );
  }
}
