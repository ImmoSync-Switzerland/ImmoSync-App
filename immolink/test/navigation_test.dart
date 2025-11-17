import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/core/providers/navigation_provider.dart';

void main() {
  group('Navigation Provider Tests', () {
    test('getNavigationIndexFromRoute returns correct indices', () {
      expect(getNavigationIndexFromRoute('/home'), 0);
      expect(getNavigationIndexFromRoute('/tenant-dashboard'), 0);
      expect(getNavigationIndexFromRoute('/landlord-dashboard'), 0);

      expect(getNavigationIndexFromRoute('/properties'), 1);
      expect(getNavigationIndexFromRoute('/property/123'), 1);

      expect(getNavigationIndexFromRoute('/conversations'), 2);
      expect(getNavigationIndexFromRoute('/chat/456'), 2);

      expect(getNavigationIndexFromRoute('/reports'), 3);
      expect(getNavigationIndexFromRoute('/maintenance'), 3);

      expect(getNavigationIndexFromRoute('/settings'), 4);
      expect(getNavigationIndexFromRoute('/profile'), 4);

      // Default case
      expect(getNavigationIndexFromRoute('/unknown'), 0);
    });

    test('RouteAwareNavigationNotifier handles manual navigation correctly',
        () {
      final container = ProviderContainer();
      final notifier = container.read(routeAwareNavigationProvider.notifier);

      // Initial state should be 0
      expect(container.read(routeAwareNavigationProvider), 0);

      // Test manual navigation
      notifier.setIndex(2); // Navigate to chat
      expect(container.read(routeAwareNavigationProvider), 2);

      // Simulate route update that should be ignored after manual navigation
      notifier.updateFromRoute('/chat/123');
      expect(container.read(routeAwareNavigationProvider), 2);

      // After the first route update post manual navigation,
      // subsequent route updates should work normally
      notifier.updateFromRoute('/home');
      expect(container.read(routeAwareNavigationProvider), 0);

      container.dispose();
    });

    test('RouteAwareNavigationNotifier updates from route normally', () {
      final container = ProviderContainer();
      final notifier = container.read(routeAwareNavigationProvider.notifier);

      // Test normal route updates
      notifier.updateFromRoute('/conversations');
      expect(container.read(routeAwareNavigationProvider), 2);

      notifier.updateFromRoute('/properties');
      expect(container.read(routeAwareNavigationProvider), 1);

      notifier.updateFromRoute('/settings');
      expect(container.read(routeAwareNavigationProvider), 4);

      container.dispose();
    });
  });
}
