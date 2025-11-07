import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immosync/core/config/db_config.dart';
import 'package:immosync/core/services/token_manager.dart';
import 'package:immosync/features/subscription/domain/models/subscription.dart';
import 'package:flutter/widgets.dart';
import '../../../../l10n/app_localizations.dart';

class SubscriptionService {
  final String _apiUrl = DbConfig.apiUrl;
  final TokenManager _tokenManager = TokenManager();

  Future<Map<String, String>> _headers() async {
    return await _tokenManager.getHeaders();
  }

  Future<List<SubscriptionPlan>> getAvailablePlans() async {
    try {
      print('[SubscriptionService] Fetching subscription plans from: $_apiUrl/subscriptions/plans');
      var response = await http.get(
        Uri.parse('$_apiUrl/subscriptions/plans'),
        headers: await _headers(),
      );
      if (response.statusCode == 401) {
        await _tokenManager.refreshToken(_apiUrl);
        response = await http.get(
          Uri.parse('$_apiUrl/subscriptions/plans'),
          headers: await _headers(),
        );
      }

      print('[SubscriptionService] Plans response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('[SubscriptionService] Received ${data.length} plans from API');
        print('[SubscriptionService] Raw plans data: ${json.encode(data)}');
        
        final plans = data.map((json) {
          try {
            return SubscriptionPlan.fromMap(json);
          } catch (e) {
            print('[SubscriptionService][ERROR] Error parsing plan: $e');
            print('[SubscriptionService][ERROR] Plan data: ${json}');
            rethrow;
          }
        }).toList();
        
        print('[SubscriptionService] Successfully parsed ${plans.length} plans');
        for (var plan in plans) {
          print('  - ${plan.name}: Monthly: ${plan.monthlyPrice}, Yearly: ${plan.yearlyPrice}');
        }
        
        return plans;
      } else {
        print('[SubscriptionService][ERROR] Failed to load plans from Stripe: ${response.statusCode}');
        print('[SubscriptionService][ERROR] Response body: ${response.body}');
        print('[SubscriptionService] Falling back to default plans...');
        return _getDefaultPlans();
      }
    } catch (e, stackTrace) {
      print('[SubscriptionService][ERROR] Error getting subscription plans from Stripe: $e');
      print('[SubscriptionService][ERROR] Stack trace: $stackTrace');
      print('[SubscriptionService] Falling back to default plans...');
      return _getDefaultPlans();
    }
  }

  Future<UserSubscription?> getUserSubscription(String userId) async {
    try {
      print('[SubscriptionService] Fetching subscription for user: $userId');
      var response = await http.get(
        Uri.parse('$_apiUrl/subscriptions/user/$userId'),
        headers: await _headers(),
      );
      if (response.statusCode == 401) {
        await _tokenManager.refreshToken(_apiUrl);
        response = await http.get(
          Uri.parse('$_apiUrl/subscriptions/user/$userId'),
          headers: await _headers(),
        );
      }

      print('[SubscriptionService] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[SubscriptionService] Raw subscription data: ${json.encode(data)}');
        
        if (data != null) {
          try {
            final subscription = UserSubscription.fromMap(data);
            print('[SubscriptionService] Successfully parsed subscription:');
            print('  - ID: ${subscription.id}');
            print('  - Status: ${subscription.status}');
            print('  - Plan ID: ${subscription.planId}');
            print('  - Stripe Sub ID: ${subscription.stripeSubscriptionId}');
            print('  - Billing Interval: ${subscription.billingInterval}');
            print('  - Amount: ${subscription.amount}');
            print('  - Next Billing: ${subscription.nextBillingDate}');
            return subscription;
          } catch (e, stackTrace) {
            print('[SubscriptionService][ERROR] Error parsing subscription data: $e');
            print('[SubscriptionService][ERROR] Stack trace: $stackTrace');
            print('[SubscriptionService][ERROR] Raw data was: ${json.encode(data)}');
            return null;
          }
        }
        return null;
      } else if (response.statusCode == 404) {
        print('[SubscriptionService] No subscription found for user $userId');
        return null; // No subscription found
      } else {
        print('[SubscriptionService][ERROR] Failed to get user subscription: ${response.statusCode}');
        print('[SubscriptionService][ERROR] Response body: ${response.body}');
        throw Exception('Failed to load user subscription');
      }
    } catch (e, stackTrace) {
      print('[SubscriptionService][ERROR] Error getting user subscription: $e');
      print('[SubscriptionService][ERROR] Stack trace: $stackTrace');
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
      var response = await http.post(
        Uri.parse('$_apiUrl/subscriptions/create'),
        headers: await _headers(),
        body: json.encode({
          'userId': userId,
          'planId': planId,
          'billingInterval': billingInterval,
          'paymentMethodId': paymentMethodId,
        }),
      );
      if (response.statusCode == 401) {
        await _tokenManager.refreshToken(_apiUrl);
        response = await http.post(
          Uri.parse('$_apiUrl/subscriptions/create'),
          headers: await _headers(),
          body: json.encode({
            'userId': userId,
            'planId': planId,
            'billingInterval': billingInterval,
            'paymentMethodId': paymentMethodId,
          }),
        );
      }

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
      var response = await http.put(
        Uri.parse('$_apiUrl/subscriptions/$subscriptionId'),
        headers: await _headers(),
        body: json.encode({
          'planId': planId,
          'billingInterval': billingInterval,
        }),
      );
      if (response.statusCode == 401) {
        await _tokenManager.refreshToken(_apiUrl);
        response = await http.put(
          Uri.parse('$_apiUrl/subscriptions/$subscriptionId'),
          headers: await _headers(),
          body: json.encode({
            'planId': planId,
            'billingInterval': billingInterval,
          }),
        );
      }

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
      var response = await http.delete(
        Uri.parse('$_apiUrl/subscriptions/$subscriptionId/cancel'),
        headers: await _headers(),
      );
      if (response.statusCode == 401) {
        await _tokenManager.refreshToken(_apiUrl);
        response = await http.delete(
          Uri.parse('$_apiUrl/subscriptions/$subscriptionId/cancel'),
          headers: await _headers(),
        );
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel subscription: ${response.body}');
      }
    } catch (e) {
      print('Error canceling subscription: $e');
      throw Exception('Failed to cancel subscription: $e');
    }
  }

  /// Create a Stripe Customer Portal session for managing subscription
  /// Returns the URL to the Stripe Customer Portal
  Future<String> createCustomerPortalSession({
    required String customerId,
    String? returnUrl,
  }) async {
    try {
      print('[SubscriptionService] Creating customer portal session for: $customerId');
      
      var response = await http.post(
        Uri.parse('$_apiUrl/subscriptions/create-portal-session'),
        headers: await _headers(),
        body: json.encode({
          'customerId': customerId,
          'returnUrl': returnUrl ?? 'immosync://subscription',
        }),
      );
      
      if (response.statusCode == 401) {
        await _tokenManager.refreshToken(_apiUrl);
        response = await http.post(
          Uri.parse('$_apiUrl/subscriptions/create-portal-session'),
          headers: await _headers(),
          body: json.encode({
            'customerId': customerId,
            'returnUrl': returnUrl ?? 'immosync://subscription',
          }),
        );
      }

      print('[SubscriptionService] Portal session response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final url = data['url'] as String;
        print('[SubscriptionService] Portal URL created: $url');
        return url;
      } else {
        print('[SubscriptionService][ERROR] Failed to create portal session: ${response.body}');
        throw Exception('Failed to create portal session: ${response.statusCode}');
      }
    } catch (e) {
      print('[SubscriptionService][ERROR] Error creating portal session: $e');
      throw Exception('Failed to create portal session: $e');
    }
  }

  Future<String> createPaymentIntent({
    required double amount,
    required String currency,
    String? customerId,
  }) async {
    try {
      var response = await http.post(
        Uri.parse('$_apiUrl/subscriptions/create-payment-intent'),
        headers: await _headers(),
        body: json.encode({
          'amount': (amount * 100).round(), // Convert to cents
          'currency': currency,
          'customerId': customerId,
        }),
      );
      if (response.statusCode == 401) {
        await _tokenManager.refreshToken(_apiUrl);
        response = await http.post(
          Uri.parse('$_apiUrl/subscriptions/create-payment-intent'),
          headers: await _headers(),
          body: json.encode({
            'amount': (amount * 100).round(),
            'currency': currency,
            'customerId': customerId,
          }),
        );
      }

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

  List<SubscriptionPlan> _getDefaultPlans({BuildContext? context}) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    String t(String Function(AppLocalizations l) selector, String fallback) =>
        l10n != null ? selector(l10n) : fallback;
    return [
      SubscriptionPlan(
        id: 'basic',
        name: t((l) => l.planBasic, 'Basic'),
        description: t(
            (l) => l.planBasicDescription, 'Perfect for individual landlords'),
        monthlyPrice: 9.99,
        yearlyPrice: 99.99,
        features: [
          t((l) => l.featureUpToThreeProperties, 'Up to 3 properties'),
          t((l) => l.featureBasicTenantManagement, 'Basic tenant management'),
          t((l) => l.featurePaymentTracking, 'Payment tracking'),
          t((l) => l.featureEmailSupport, 'Email support'),
        ],
        stripePriceIdMonthly: 'price_basic_monthly',
        stripePriceIdYearly: 'price_basic_yearly',
      ),
      SubscriptionPlan(
        id: 'pro',
        name: t((l) => l.planProfessional, 'Professional'),
        description: t((l) => l.planProfessionalDescription,
            'Best for growing property portfolios'),
        monthlyPrice: 19.99,
        yearlyPrice: 199.99,
        features: [
          t((l) => l.featureUpToFifteenProperties, 'Up to 15 properties'),
          t((l) => l.featureAdvancedTenantManagement,
              'Advanced tenant management'),
          t((l) => l.featureAutomatedRentCollection,
              'Automated rent collection'),
          t((l) => l.featureMaintenanceRequestTracking,
              'Maintenance request tracking'),
          t((l) => l.featureFinancialReports, 'Financial reports'),
          t((l) => l.featurePrioritySupport, 'Priority support'),
        ],
        isPopular: true,
        stripePriceIdMonthly: 'price_pro_monthly',
        stripePriceIdYearly: 'price_pro_yearly',
      ),
      SubscriptionPlan(
        id: 'enterprise',
        name: t((l) => l.planEnterprise, 'Enterprise'),
        description: t((l) => l.planEnterpriseDescription,
            'For large property management companies'),
        monthlyPrice: 49.99,
        yearlyPrice: 499.99,
        features: [
          t((l) => l.featureUnlimitedProperties, 'Unlimited properties'),
          t((l) => l.featureMultiUserAccounts, 'Multi-user accounts'),
          t((l) => l.featureAdvancedAnalytics, 'Advanced analytics'),
          t((l) => l.featureApiAccess, 'API access'),
          t((l) => l.featureCustomIntegrations, 'Custom integrations'),
          t((l) => l.featureDedicatedSupport, 'Dedicated support'),
        ],
        stripePriceIdMonthly: 'price_enterprise_monthly',
        stripePriceIdYearly: 'price_enterprise_yearly',
      ),
    ];
  }
}
