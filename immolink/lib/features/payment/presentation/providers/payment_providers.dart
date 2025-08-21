import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/payment/domain/models/payment.dart';
import 'package:immosync/features/payment/domain/services/payment_service.dart';

// Provider for the payment service
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

// Provider for payments by tenant
final tenantPaymentsProvider = FutureProvider.autoDispose<List<Payment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User not authenticated');
  }
  
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getPaymentsByTenant(user.id);
});

// Provider for payments by landlord
final landlordPaymentsProvider = FutureProvider.autoDispose<List<Payment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User not authenticated');
  }
  
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getPaymentsByLandlord(user.id);
});

// Provider for payments by property
final propertyPaymentsProvider = FutureProvider.family.autoDispose<List<Payment>, String>((ref, propertyId) async {
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getPaymentsByProperty(propertyId);
});

// Provider for a single payment by ID
final paymentProvider = FutureProvider.family.autoDispose<Payment, String>((ref, paymentId) async {
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getPaymentById(paymentId);
});

// State notifier for creating/updating payments
class PaymentNotifier extends StateNotifier<AsyncValue<Payment?>> {
  final PaymentService _paymentService;
  
  PaymentNotifier(this._paymentService) : super(const AsyncValue.data(null));
  
  Future<void> createPayment(Payment payment) async {
    state = const AsyncValue.loading();
    try {
      final createdPayment = await _paymentService.createPayment(payment);
      state = AsyncValue.data(createdPayment);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  Future<void> updatePayment(Payment payment) async {
    state = const AsyncValue.loading();
    try {
      final updatedPayment = await _paymentService.updatePayment(payment);
      state = AsyncValue.data(updatedPayment);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final paymentNotifierProvider = StateNotifierProvider.autoDispose<PaymentNotifier, AsyncValue<Payment?>>((ref) {
  final paymentService = ref.watch(paymentServiceProvider);
  return PaymentNotifier(paymentService);
});

