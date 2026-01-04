import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:immosync/features/auth/presentation/providers/user_role_provider.dart';
// import 'package:immosync/core/providers/navigation_provider.dart'; // Nicht mehr zwingend nötig für die UI-Berechnung

/// Die wiederverwendbare Glass-Komponente (UI pur)
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<BottomNavigationBarItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Height kann weggelassen werden, damit es sich dem Inhalt anpasst,
      // oder fixiert werden, falls gewünscht.
      decoration: BoxDecoration(
        // Ein feinerer Border für den "Premium"-Look
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1), // Etwas subtiler
            width: 0.5, // Dünner ist oft edler
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          // Starker Blur für den Milchglas-Effekt
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Container(
            // Der "Tint" (die Tönung)
            color: Colors.black.withValues(alpha: 0.6),
            child: BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: onDestinationSelected,

              // Transparenz-Einstellungen
              backgroundColor: Colors.transparent,
              elevation: 0,

              // Verhalten & Typ
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: false,
              showUnselectedLabels: false,

              // Farben (High Contrast Bento Style)
              selectedItemColor: Colors.white, // Aktiv = Reinweiß
              unselectedItemColor:
                  Colors.white.withValues(alpha: 0.4), // Inaktiv = Gedimmt

              items: items,
            ),
          ),
        ),
      ),
    );
  }
}

/// Die Logik-Komponente (Verbindet Router & User Role)
class AppGlassNavBar extends ConsumerWidget {
  const AppGlassNavBar({super.key});

  // Hilfsmethode: Berechnet Index basierend auf der URL
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/properties') ||
        location.startsWith('/documents')) {
      return 1;
    }
    if (location.startsWith('/conversations')) return 2;
    if (location.startsWith('/reports')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0; // Fallback
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(userRoleProvider);

    // Berechne Index direkt aus dem Router-State (Reaktiv & Sicher)
    final int selectedIndex = _calculateSelectedIndex(context);

    return GlassNavBar(
      selectedIndex: selectedIndex,
      items: _navItems(userRole),
      onDestinationSelected: (index) => _onItemTapped(context, index, userRole),
    );
  }

  void _onItemTapped(BuildContext context, int index, String? userRole) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        if (userRole == 'tenant') {
          context.go('/documents');
        } else {
          context.go('/properties');
        }
        break;
      case 2:
        context.go('/conversations');
        break;
      case 3:
        context.go('/reports');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  List<BottomNavigationBarItem> _navItems(String? userRole) {
    final bool isTenant = userRole == 'tenant';
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: Icon(isTenant ? Icons.folder_outlined : Icons.home_work_outlined),
        label: isTenant ? 'Documents' : 'Properties',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline),
        label: 'Messages',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.bar_chart_outlined),
        label: 'Reports',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        label: 'Profile',
      ),
    ];
  }
}
