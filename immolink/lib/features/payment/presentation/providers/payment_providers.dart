import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/payment/domain/models/payment.dart';
import 'package:immosync/features/payment/domain/services/payment_service.dart';
import 'package:immosync/features/payment/domain/services/stripe_connect_payment_service.dart';

// Provider for the payment service
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

// Provider for payments by tenant
final tenantPaymentsProvider =
    FutureProvider.autoDispose<List<Payment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getPaymentsByTenant(user.id);
});

// Provider for payments by landlord
final landlordPaymentsProvider =
    FutureProvider.autoDispose<List<Payment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getPaymentsByLandlord(user.id);
});

// Provider for payments by property
final propertyPaymentsProvider = FutureProvider.family
    .autoDispose<List<Payment>, String>((ref, propertyId) async {
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getPaymentsByProperty(propertyId);
});

// Provider for a single payment by ID
final paymentProvider =
    FutureProvider.family.autoDispose<Payment, String>((ref, paymentId) async {
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

final paymentNotifierProvider =
    StateNotifierProvider.autoDispose<PaymentNotifier, AsyncValue<Payment?>>(
        (ref) {
  final paymentService = ref.watch(paymentServiceProvider);
  return PaymentNotifier(paymentService);
});

// ============================================================================
// STRIPE CONNECT PROVIDERS
// ============================================================================

/// Provider for the Stripe Connect payment service
final stripeConnectPaymentServiceProvider =
    Provider<StripeConnectPaymentService>((ref) {
  return StripeConnectPaymentService(ref: ref);
});

/// Provider for landlord's Stripe Connect account
final stripeConnectAccountProvider =
    FutureProvider.autoDispose<StripeConnectAccount>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final service = ref.watch(stripeConnectPaymentServiceProvider);
  return service.getConnectAccount(user.id);
});

/// Provider to check if landlord has completed Stripe onboarding
final isStripeOnboardingCompleteProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final service = ref.watch(stripeConnectPaymentServiceProvider);
  return service.isOnboardingComplete(user.id);
});

/// Provider for landlord's payment history from Stripe Connect
final landlordConnectPaymentsProvider =
    FutureProvider.autoDispose<List<ConnectPayment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final service = ref.watch(stripeConnectPaymentServiceProvider);
  return service.getLandlordPayments(landlordId: user.id, limit: 50);
});

/// Provider for tenant's payment history from Stripe Connect
final tenantConnectPaymentsProvider =
    FutureProvider.autoDispose<List<ConnectPayment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final service = ref.watch(stripeConnectPaymentServiceProvider);
  return service.getTenantPayments(tenantId: user.id, limit: 50);
});

/// Provider for landlord's account balance
final landlordBalanceProvider =
    FutureProvider.autoDispose<AccountBalance>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final service = ref.watch(stripeConnectPaymentServiceProvider);
  return service.getAccountBalance(user.id);
});

/// Provider for landlord's payout history
final landlordPayoutsProvider =
    FutureProvider.autoDispose<List<Payout>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final service = ref.watch(stripeConnectPaymentServiceProvider);
  return service.getPayouts(landlordId: user.id, limit: 20);
});

/// State notifier for Stripe Connect operations
class StripeConnectNotifier extends StateNotifier<AsyncValue<String?>> {
  final StripeConnectPaymentService _service;

  StripeConnectNotifier(this._service) : super(const AsyncValue.data(null));

  /// Create Stripe Connect account for landlord
  Future<StripeConnectAccount?> createConnectAccount({
    required String landlordId,
    required String email,
    String? businessType,
  }) async {
    state = const AsyncValue.loading();
    try {
      final account = await _service.createConnectAccount(
        landlordId: landlordId,
        email: email,
        businessType: businessType,
      );
      state = AsyncValue.data(account.accountId);
      return account;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  /// Generate onboarding link for landlord
  Future<String?> createOnboardingLink({
    required String accountId,
    String? refreshUrl,
    String? returnUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final url = await _service.createOnboardingLink(
        accountId: accountId,
        refreshUrl: refreshUrl,
        returnUrl: returnUrl,
      );
      state = const AsyncValue.data('success');
      return url;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  /// Create payment from tenant to landlord
  Future<TenantPaymentIntent?> createTenantPayment({
    required String tenantId,
    required String landlordId,
    required String propertyId,
    required double amount,
    String currency = 'chf',
    String paymentType = 'rent',
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      final paymentIntent = await _service.createTenantPayment(
        tenantId: tenantId,
        landlordId: landlordId,
        propertyId: propertyId,
        amount: amount,
        currency: currency,
        paymentType: paymentType,
        description: description,
      );
      state = AsyncValue.data(paymentIntent.paymentIntentId);
      return paymentIntent;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  /// Confirm payment after Stripe checkout
  Future<PaymentResult?> confirmPayment({
    required String paymentIntentId,
    String? paymentMethodId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.confirmPayment(
        paymentIntentId: paymentIntentId,
        paymentMethodId: paymentMethodId,
      );
      state = const AsyncValue.data('payment_confirmed');
      return result;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  /// Create a payout to landlord's bank
  Future<Payout?> createPayout({
    required String landlordId,
    required double amount,
    String currency = 'chf',
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      final payout = await _service.createPayout(
        landlordId: landlordId,
        amount: amount,
        currency: currency,
        description: description,
      );
      state = const AsyncValue.data('payout_created');
      return payout;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  /// Create a refund for a payment
  Future<Refund?> createRefund({
    required String paymentIntentId,
    double? amount,
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      final refund = await _service.createRefund(
        paymentIntentId: paymentIntentId,
        amount: amount,
        reason: reason,
      );
      state = const AsyncValue.data('refund_created');
      return refund;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final stripeConnectNotifierProvider =
    StateNotifierProvider<StripeConnectNotifier, AsyncValue<String?>>((ref) {
  final service = ref.watch(stripeConnectPaymentServiceProvider);
  return StripeConnectNotifier(service);
});
