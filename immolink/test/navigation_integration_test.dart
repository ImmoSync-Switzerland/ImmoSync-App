import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/core/widgets/common_bottom_nav.dart';

void main() {
  group('CommonBottomNav Integration Tests', () {
    testWidgets('Navigation highlights correct tab when tapping',
        (WidgetTester tester) async {
      // Create a simple router for testing
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/conversations',
            builder: (context, state) => const Scaffold(body: Text('Chat')),
          ),
          GoRoute(
            path: '/properties',
            builder: (context, state) =>
                const Scaffold(body: Text('Properties')),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const Scaffold(body: Text('Reports')),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const Scaffold(body: Text('Settings')),
          ),
        ],
      );

      // Create the test app
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
            builder: (context, child) => Scaffold(
              body: child,
              bottomNavigationBar: const CommonBottomNav(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should be on dashboard (index 0)
      final bottomNavBar =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomNavBar.currentIndex, 0);

      // Tap on Messages (index 2)
      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      // Should navigate to conversations and highlight Messages tab
      expect(find.text('Chat'), findsOneWidget);
      final updatedBottomNavBar =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(updatedBottomNavBar.currentIndex, 2);

      // Tap on Dashboard (index 0)
      await tester.tap(find.byIcon(Icons.dashboard_outlined));
      await tester.pumpAndSettle();

      // Should navigate to home and highlight Dashboard tab
      expect(find.text('Home'), findsOneWidget);
      final finalBottomNavBar =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(finalBottomNavBar.currentIndex, 0);
    });
  });
}
