import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/maintenance/domain/models/maintenance_request.dart';
import 'package:immosync/features/maintenance/domain/services/maintenance_service.dart';

// Provider for the maintenance service
final maintenanceServiceProvider = Provider<MaintenanceService>((ref) {
  return MaintenanceService();
});

// Provider for maintenance requests by tenant
final tenantMaintenanceRequestsProvider = FutureProvider.autoDispose<List<MaintenanceRequest>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User not authenticated');
  }
  
  final maintenanceService = ref.watch(maintenanceServiceProvider);
  return maintenanceService.getMaintenanceRequestsByTenant(user.id);
});

// Provider for maintenance requests by landlord
final landlordMaintenanceRequestsProvider = FutureProvider.autoDispose<List<MaintenanceRequest>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User not authenticated');
  }
  
  final maintenanceService = ref.watch(maintenanceServiceProvider);
  return maintenanceService.getMaintenanceRequestsByLandlord(user.id);
});

// Provider for maintenance requests by property
final propertyMaintenanceRequestsProvider = FutureProvider.family.autoDispose<List<MaintenanceRequest>, String>((ref, propertyId) async {
  final maintenanceService = ref.watch(maintenanceServiceProvider);
  return maintenanceService.getMaintenanceRequestsByProperty(propertyId);
});

// Provider for a single maintenance request by ID
final maintenanceRequestProvider = FutureProvider.family.autoDispose<MaintenanceRequest, String>((ref, requestId) async {
  final maintenanceService = ref.watch(maintenanceServiceProvider);
  return maintenanceService.getMaintenanceRequestById(requestId);
});

// State notifier for creating/updating maintenance requests
class MaintenanceRequestNotifier extends StateNotifier<AsyncValue<MaintenanceRequest?>> {
  final MaintenanceService _maintenanceService;
  
  MaintenanceRequestNotifier(this._maintenanceService) : super(const AsyncValue.data(null));
  
  Future<void> createMaintenanceRequest(MaintenanceRequest request) async {
    state = const AsyncValue.loading();
    try {
      final createdRequest = await _maintenanceService.createMaintenanceRequest(request);
      state = AsyncValue.data(createdRequest);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  Future<void> updateMaintenanceRequest(MaintenanceRequest request) async {
    state = const AsyncValue.loading();
    try {
      final updatedRequest = await _maintenanceService.updateMaintenanceRequest(request);
      state = AsyncValue.data(updatedRequest);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final maintenanceRequestNotifierProvider = StateNotifierProvider.autoDispose<MaintenanceRequestNotifier, AsyncValue<MaintenanceRequest?>>((ref) {
  final maintenanceService = ref.watch(maintenanceServiceProvider);
  return MaintenanceRequestNotifier(maintenanceService);
});

