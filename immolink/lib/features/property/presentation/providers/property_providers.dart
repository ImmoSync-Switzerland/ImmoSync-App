import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immolink/features/auth/domain/models/user.dart';
import 'package:immolink/features/property/domain/services/property_service.dart';
import '../../domain/models/property.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/user_service_provider.dart';

// Service provider
final propertyServiceProvider = Provider<PropertyService>((ref) {
  return PropertyService();
});

// Properties stream provider
final propertiesProvider = StreamProvider<List<Property>>((ref) {
  final propertyService = ref.watch(propertyServiceProvider);
  return propertyService.getAllProperties();
});

// Real-time refresh timer provider
final propertyRefreshTimerProvider = StreamProvider<int>((ref) async* {
  // Create a timer that emits every 30 seconds
  var counter = 0;
  final timer = Timer.periodic(const Duration(seconds: 30), (timer) {});
  
  // Keep the provider alive
  ref.onDispose(() {
    timer.cancel();
  });
  
  yield counter++;
  
  await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
    yield counter++;
  }
});

// Landlord-specific properties provider with real-time refresh
final landlordPropertiesProvider = StreamProvider<List<Property>>((ref) async* {
  print('LandlordPropertiesProvider initialized');
  final currentUser = ref.watch(currentUserProvider);
  
  // Watch the refresh timer to trigger updates
  ref.watch(propertyRefreshTimerProvider);
  
  print('Current user in provider: ${currentUser?.id}');

  // Early return empty list if no user
  if (currentUser == null) {
    yield [];
    return;
  }

  final propertyService = ref.watch(propertyServiceProvider);
  print('Calling PropertyService.getLandlordProperties with ID: ${currentUser.id}');
  
  // Get initial data
  await for (final properties in propertyService.getLandlordProperties(currentUser.id)) {
    print('LandlordPropertiesProvider: Yielding ${properties.length} properties');
    yield properties;
  }
});

// Tenant-specific properties provider with real-time refresh
final tenantPropertiesProvider = StreamProvider<List<Property>>((ref) async* {
  print('TenantPropertiesProvider initialized');
  final currentUser = ref.watch(currentUserProvider);
  
  // Watch the refresh timer to trigger updates
  ref.watch(propertyRefreshTimerProvider);
  
  // Early return empty list if no user
  if (currentUser == null) {
    yield [];
    return;
  }

  final propertyService = ref.watch(propertyServiceProvider);
  print('Calling PropertyService.getTenantProperties with ID: ${currentUser.id}');
  
  // Get initial data
  await for (final properties in propertyService.getTenantProperties(currentUser.id)) {
    print('TenantPropertiesProvider: Yielding ${properties.length} properties');
    yield properties;
  }
});

final tenantInvitationProvider =
    StateNotifierProvider<TenantInvitationNotifier, AsyncValue<void>>((ref) {
  return TenantInvitationNotifier(ref.watch(propertyServiceProvider));
});

final tenantRemovalProvider =
    StateNotifierProvider<TenantRemovalNotifier, AsyncValue<void>>((ref) {
  return TenantRemovalNotifier(ref.watch(propertyServiceProvider));
});

class TenantInvitationNotifier extends StateNotifier<AsyncValue<void>> {
  final PropertyService _propertyService;

  TenantInvitationNotifier(this._propertyService)
      : super(const AsyncValue.data(null));

  Future<void> inviteTenant(String propertyId, String tenantId) async {
    state = const AsyncValue.loading();

    try {
      await _propertyService.inviteTenant(propertyId, tenantId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class TenantRemovalNotifier extends StateNotifier<AsyncValue<void>> {
  final PropertyService _propertyService;

  TenantRemovalNotifier(this._propertyService)
      : super(const AsyncValue.data(null));

  Future<void> removeTenant(String propertyId, String tenantId) async {
    state = const AsyncValue.loading();

    try {
      await _propertyService.removeTenant(propertyId, tenantId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final availableTenantsProvider = StreamProvider.family<List<User>, String?>((ref, propertyId) {
  final userService = ref.watch(userServiceProvider);
  return userService.getAvailableTenants(propertyId: propertyId);
});

final propertyProvider =
    StreamProvider.family<Property, String>((ref, propertyId) {
  final propertyService = ref.watch(propertyServiceProvider);
  return propertyService.getPropertyById(propertyId);
});

