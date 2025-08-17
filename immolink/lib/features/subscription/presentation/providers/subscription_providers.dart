import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immolink/features/auth/presentation/providers/auth_provider.dart';
import 'package:immolink/features/subscription/domain/models/subscription.dart';
import 'package:immolink/features/subscription/domain/services/subscription_service.dart';

// Provider for the subscription service
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

// Provider for available subscription plans
final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return subscriptionService.getAvailablePlans();
});

// Provider for user's current subscription
final userSubscriptionProvider = FutureProvider.autoDispose<UserSubscription?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return null;
  }
  
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return subscriptionService.getUserSubscription(user.id);
});

// State notifier for subscription management
class SubscriptionNotifier extends StateNotifier<AsyncValue<UserSubscription?>> {
  final SubscriptionService _subscriptionService;
  
  SubscriptionNotifier(this._subscriptionService) : super(const AsyncValue.data(null));

  Future<void> createSubscription({
    required String userId,
    required String planId,
    required String billingInterval,
    required String paymentMethodId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _subscriptionService.createSubscription(
        userId: userId,
        planId: planId,
        billingInterval: billingInterval,
        paymentMethodId: paymentMethodId,
      );
      
      if (result['subscription'] != null) {
        state = AsyncValue.data(UserSubscription.fromMap(result['subscription']));
      } else {
        throw Exception('Failed to create subscription');
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateSubscription({
    required String subscriptionId,
    required String planId,
    required String billingInterval,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _subscriptionService.updateSubscription(
        subscriptionId: subscriptionId,
        planId: planId,
        billingInterval: billingInterval,
      );
      
      if (result['subscription'] != null) {
        state = AsyncValue.data(UserSubscription.fromMap(result['subscription']));
      } else {
        throw Exception('Failed to update subscription');
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> cancelSubscription(String subscriptionId) async {
    state = const AsyncValue.loading();
    try {
      await _subscriptionService.cancelSubscription(subscriptionId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<String> createPaymentIntent({
    required double amount,
    required String currency,
    String? customerId,
  }) async {
    try {
      return await _subscriptionService.createPaymentIntent(
        amount: amount,
        currency: currency,
        customerId: customerId,
      );
    } catch (e) {
      rethrow;
    }
  }
}

// Provider for subscription notifier
final subscriptionNotifierProvider = StateNotifierProvider<SubscriptionNotifier, AsyncValue<UserSubscription?>>((ref) {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return SubscriptionNotifier(subscriptionService);
});
