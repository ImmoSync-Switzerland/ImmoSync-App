import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immosync/core/config/db_config.dart';
import 'package:immosync/features/subscription/domain/models/subscription.dart';

class SubscriptionService {
  final String _apiUrl = DbConfig.apiUrl;

  Future<List<SubscriptionPlan>> getAvailablePlans() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/payments/subscription-plans'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => SubscriptionPlan.fromMap(json)).toList();
      } else {
        print('Failed to load plans from Stripe: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load subscription plans from Stripe');
      }
    } catch (e) {
      print('Error getting subscription plans from Stripe: $e');
      // Return default plans as fallback
      print('Falling back to default plans...');
      return _getDefaultPlans();
    }
  }

  Future<UserSubscription?> getUserSubscription(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/subscriptions/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null) {
          try {
            return UserSubscription.fromMap(data);
          } catch (e) {
            print('Error parsing subscription data: $e');
            print('Raw subscription data: $data');
            return null;
          }
        }
        return null;
      } else if (response.statusCode == 404) {
        return null; // No subscription found
      } else {
        print('Failed to get user subscription: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load user subscription');
      }
    } catch (e) {
      print('Error getting user subscription: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> createSubscription({
    required String userId,
    required String planId,
    required String billingInterval,
    required String paymentMethodId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/subscriptions/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'planId': planId,
          'billingInterval': billingInterval,
          'paymentMethodId': paymentMethodId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create subscription: ${response.body}');
      }
    } catch (e) {
      print('Error creating subscription: $e');
      throw Exception('Failed to create subscription: $e');
    }
  }

  Future<Map<String, dynamic>> updateSubscription({
    required String subscriptionId,
    required String planId,
    required String billingInterval,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/subscriptions/$subscriptionId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'planId': planId,
          'billingInterval': billingInterval,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update subscription: ${response.body}');
      }
    } catch (e) {
      print('Error updating subscription: $e');
      throw Exception('Failed to update subscription: $e');
    }
  }

  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_apiUrl/subscriptions/$subscriptionId/cancel'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel subscription: ${response.body}');
      }
    } catch (e) {
      print('Error canceling subscription: $e');
      throw Exception('Failed to cancel subscription: $e');
    }
  }

  Future<String> createPaymentIntent({
    required double amount,
    required String currency,
    String? customerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/subscriptions/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'amount': (amount * 100).round(), // Convert to cents
          'currency': currency,
          'customerId': customerId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['clientSecret'];
      } else {
        throw Exception('Failed to create payment intent: ${response.body}');
      }
    } catch (e) {
      print('Error creating payment intent: $e');
      throw Exception('Failed to create payment intent: $e');
    }
  }

  List<SubscriptionPlan> _getDefaultPlans() {
    return [
      SubscriptionPlan(
        id: 'basic',
        name: 'Basic',
        description: 'Perfect for individual landlords',
        monthlyPrice: 9.99,
        yearlyPrice: 99.99,
        features: [
          'Up to 3 properties',
          'Basic tenant management',
          'Payment tracking',
          'Email support',
        ],
        stripePriceIdMonthly: 'price_basic_monthly',
        stripePriceIdYearly: 'price_basic_yearly',
      ),
      SubscriptionPlan(
        id: 'pro',
        name: 'Professional',
        description: 'Best for growing property portfolios',
        monthlyPrice: 19.99,
        yearlyPrice: 199.99,
        features: [
          'Up to 15 properties',
          'Advanced tenant management',
          'Automated rent collection',
          'Maintenance request tracking',
          'Financial reports',
          'Priority support',
        ],
        isPopular: true,
        stripePriceIdMonthly: 'price_pro_monthly',
        stripePriceIdYearly: 'price_pro_yearly',
      ),
      SubscriptionPlan(
        id: 'enterprise',
        name: 'Enterprise',
        description: 'For large property management companies',
        monthlyPrice: 49.99,
        yearlyPrice: 499.99,
        features: [
          'Unlimited properties',
          'Multi-user accounts',
          'Advanced analytics',
          'API access',
          'Custom integrations',
          'Dedicated support',
        ],
        stripePriceIdMonthly: 'price_enterprise_monthly',
        stripePriceIdYearly: 'price_enterprise_yearly',
      ),
    ];
  }
}
