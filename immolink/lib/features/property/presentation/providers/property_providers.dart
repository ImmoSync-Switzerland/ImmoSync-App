import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/auth/domain/models/user.dart';
import 'package:immosync/features/property/domain/services/property_service.dart';
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

// Manual refresh trigger: call ref.read(propertyRefreshTriggerProvider.notifier).state++ to force reload
final propertyRefreshTriggerProvider = StateProvider<int>((_) => 0);

// Landlord-specific properties provider with real-time refresh
final landlordPropertiesProvider = StreamProvider<List<Property>>((ref) async* {
  print('[LandlordPropertiesProvider] init');
  final currentUser = ref.watch(currentUserProvider);

  // React to manual refresh trigger
  final refreshTick = ref.watch(propertyRefreshTriggerProvider);
  if (refreshTick > 0) {
    print('[LandlordPropertiesProvider] Manual refresh tick = $refreshTick');
  }

  print('[LandlordPropertiesProvider] Current user: ${currentUser?.id}');

  if (currentUser == null) {
    print('[LandlordPropertiesProvider] No current user -> empty list');
    yield [];
    return;
  }

  final propertyService = ref.watch(propertyServiceProvider);
  print(
      '[LandlordPropertiesProvider] Fetching for landlordId=${currentUser.id}');

  try {
    await for (final properties
        in propertyService.getLandlordProperties(currentUser.id)) {
      print(
          '[LandlordPropertiesProvider] Emitting ${properties.length} properties');
      yield properties;
    }
  } catch (e, st) {
    // Log and rethrow so Riverpod captures error state
    print('[LandlordPropertiesProvider][ERROR] $e');
    print(st);
    rethrow;
  }
});

// Tenant-specific properties provider with real-time refresh
final tenantPropertiesProvider = StreamProvider<List<Property>>((ref) async* {
  print('TenantPropertiesProvider initialized');
  final currentUser = ref.watch(currentUserProvider);

  // Watch the manual refresh trigger (increments cause rebuild)
  ref.watch(propertyRefreshTriggerProvider);

  // Early return empty list if no user
  if (currentUser == null) {
    yield [];
    return;
  }

  final propertyService = ref.watch(propertyServiceProvider);
  print(
      'Calling PropertyService.getTenantProperties with ID: ${currentUser.id}');

  // Get initial data
  await for (final properties
      in propertyService.getTenantProperties(currentUser.id)) {
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

final availableTenantsProvider =
    StreamProvider.family<List<User>, String?>((ref, propertyId) {
  final userService = ref.watch(userServiceProvider);
  return userService.getAvailableTenants(propertyId: propertyId);
});

final propertyProvider =
    StreamProvider.family<Property, String>((ref, propertyId) {
  final propertyService = ref.watch(propertyServiceProvider);
  return propertyService.getPropertyById(propertyId);
});
