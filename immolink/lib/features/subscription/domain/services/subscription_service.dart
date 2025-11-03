import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immosync/core/config/db_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:crypto/crypto.dart';
import 'package:immosync/features/subscription/domain/models/subscription.dart';
import 'package:flutter/widgets.dart';
import '../../../../l10n/app_localizations.dart';

class SubscriptionService {
  final String _apiUrl = DbConfig.apiUrl;

  // ===== Auth helpers (align with other services) =====
  String? _buildUiJwt(String userId) {
    try {
      final secret = dotenv.dotenv.isInitialized
          ? (dotenv.dotenv.env['JWT_SECRET'] ?? '')
          : '';
      if (secret.isEmpty) return null;
      final header = {'alg': 'HS256', 'typ': 'JWT'};
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final payload = {'sub': userId, 'iat': now, 'exp': now + 300};
      String b64Url(Map obj) {
        final jsonStr = json.encode(obj);
        final b64 = base64Url.encode(utf8.encode(jsonStr));
        return b64.replaceAll('=', '');
      }
      final h = b64Url(header);
      final p = b64Url(payload);
      final data = utf8.encode('$h.$p');
      final key = utf8.encode(secret);
      final sig = Hmac(sha256, key).convert(data);
      final s = base64Url.encode(sig.bytes).replaceAll('=', '');
      return '$h.$p.$s';
    } catch (_) {
      return null;
    }
  }

  Future<void> _tryLoginExchangeWithUiJwt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null || userId.isEmpty) return;
      final assertion = _buildUiJwt(userId);
      if (assertion == null) return;
      final ex = await http.post(
        Uri.parse('$_apiUrl/auth/login-exchange'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $assertion',
        },
      );
      if (ex.statusCode == 200) {
        final data = json.decode(ex.body) as Map<String, dynamic>;
        final newToken = data['token'] as String?;
        if (newToken != null && newToken.isNotEmpty) {
          await prefs.setString('sessionToken', newToken);
          final prefix = newToken.substring(0, newToken.length < 8 ? newToken.length : 8);
          print('AUTH DEBUG [SubscriptionService]: obtained token; prefix=$prefix');
        }
      } else {
        print('AUTH DEBUG [SubscriptionService]: UI-JWT exchange failed ${ex.statusCode} ${ex.body}');
      }
    } catch (e) {
      print('AUTH DEBUG [SubscriptionService]: UI-JWT exchange error: $e');
    }
  }

  Future<Map<String, String>> _headers() async {
    final base = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('sessionToken');
      if (token != null && token.isNotEmpty) {
        base['Authorization'] = 'Bearer $token';
        base['x-access-token'] = token;
      }
    } catch (_) {}
    return base;
  }

  Future<List<SubscriptionPlan>> getAvailablePlans() async {
    try {
      var response = await http.get(
        Uri.parse('$_apiUrl/subscriptions/plans'),
        headers: await _headers(),
      );
      if (response.statusCode == 401) {
        await _tryLoginExchangeWithUiJwt();
        response = await http.get(
          Uri.parse('$_apiUrl/subscriptions/plans'),
          headers: await _headers(),
        );
      }

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
      var response = await http.get(
        Uri.parse('$_apiUrl/subscriptions/user/$userId'),
        headers: await _headers(),
      );
      if (response.statusCode == 401) {
        await _tryLoginExchangeWithUiJwt();
        response = await http.get(
          Uri.parse('$_apiUrl/subscriptions/user/$userId'),
          headers: await _headers(),
        );
      }

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
        await _tryLoginExchangeWithUiJwt();
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
        await _tryLoginExchangeWithUiJwt();
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
        await _tryLoginExchangeWithUiJwt();
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
        await _tryLoginExchangeWithUiJwt();
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
