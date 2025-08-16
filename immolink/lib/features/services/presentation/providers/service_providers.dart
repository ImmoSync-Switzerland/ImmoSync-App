import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/service.dart';
import '../../domain/services/service_service.dart';

// Service provider
final serviceServiceProvider = Provider<ServiceService>((ref) {
  return ServiceService();
});

// Provider for all services (for landlord management)
final landlordServicesProvider = FutureProvider.autoDispose<List<Service>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User not authenticated');
  }
  
  final serviceService = ref.watch(serviceServiceProvider);
  return serviceService.getServicesForLandlord(user.id);
});

// Provider for all available services (admin-managed, not landlord-specific)
final allAvailableServicesProvider = FutureProvider.autoDispose<List<Service>>((ref) async {
  final serviceService = ref.watch(serviceServiceProvider);
  return serviceService.getServices(availability: 'available');
});

// Provider for services available to tenants
final tenantAvailableServicesProvider = FutureProvider.autoDispose.family<List<Service>, String>((ref, landlordId) async {
  final serviceService = ref.watch(serviceServiceProvider);
  return serviceService.getServicesForTenant(landlordId);
});

// Provider for services by category
final servicesByCategoryProvider = FutureProvider.autoDispose.family<List<Service>, String>((ref, category) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User not authenticated');
  }
  
  final serviceService = ref.watch(serviceServiceProvider);
  return serviceService.getServices(
    landlordId: user.id,
    category: category,
  );
});

// State notifier for creating/updating services
class ServiceNotifier extends StateNotifier<AsyncValue<Service?>> {
  final ServiceService _serviceService;
  final Ref _ref;
  
  ServiceNotifier(this._serviceService, this._ref) : super(const AsyncValue.data(null));
  
  Future<void> createService(Service service) async {
    state = const AsyncValue.loading();
    try {
      final createdService = await _serviceService.createService(service);
      state = AsyncValue.data(createdService);
      
      // Refresh the landlord services list
      _ref.invalidate(landlordServicesProvider);
      // Also refresh tenant services for all landlords
      _ref.invalidate(tenantAvailableServicesProvider);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  Future<void> updateService(Service service) async {
    state = const AsyncValue.loading();
    try {
      final updatedService = await _serviceService.updateService(service);
      state = AsyncValue.data(updatedService);
      
      // Refresh the landlord services list
      _ref.invalidate(landlordServicesProvider);
      // Also refresh tenant services for all landlords
      _ref.invalidate(tenantAvailableServicesProvider);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  Future<void> deleteService(String serviceId) async {
    state = const AsyncValue.loading();
    try {
      await _serviceService.deleteService(serviceId);
      state = const AsyncValue.data(null);
      
      // Refresh the landlord services list
      _ref.invalidate(landlordServicesProvider);
      // Also refresh tenant services for all landlords
      _ref.invalidate(tenantAvailableServicesProvider);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final serviceNotifierProvider = StateNotifierProvider.autoDispose<ServiceNotifier, AsyncValue<Service?>>((ref) {
  final serviceService = ref.watch(serviceServiceProvider);
  return ServiceNotifier(serviceService, ref);
});
