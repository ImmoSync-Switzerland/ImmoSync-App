import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the current navigation index
final navigationIndexProvider = StateProvider<int>((ref) => 0);

// Provider for the current route
final currentRouteProvider = StateProvider<String>((ref) => '/home');

// Function to get navigation index from route
int getNavigationIndexFromRoute(String route) {
  if (route.startsWith('/home') || route.startsWith('/tenant-dashboard') || route.startsWith('/landlord-dashboard')) {
    return 0; // Dashboard
  } else if (route.startsWith('/properties') || route.startsWith('/property')) {
    return 1; // Properties/Immobilien
  } else if (route.startsWith('/conversations') || route.startsWith('/chat')) {
    return 2; // Messages/Nachrichten
  } else if (route.startsWith('/reports') || route.startsWith('/maintenance')) {
    return 3; // Reports/Berichte
  } else if (route.startsWith('/settings') || route.startsWith('/profile')) {
    return 4; // Profile/Profil
  }
  return 0; // Default to Dashboard
}

// Provider that automatically updates navigation index based on current route
final routeAwareNavigationProvider = StateNotifierProvider<RouteAwareNavigationNotifier, int>((ref) {
  return RouteAwareNavigationNotifier(ref);
});

class RouteAwareNavigationNotifier extends StateNotifier<int> {
  final Ref ref;
  bool _isManualNavigation = false;

  RouteAwareNavigationNotifier(this.ref) : super(0);

  void updateFromRoute(String route) {
    // Don't update from route if we just performed a manual navigation
    if (_isManualNavigation) {
      _isManualNavigation = false;
      return;
    }
    
    final newIndex = getNavigationIndexFromRoute(route);
    if (state != newIndex) {
      state = newIndex;
    }
  }

  void setIndex(int index) {
    _isManualNavigation = true;
    state = index;
  }
}
