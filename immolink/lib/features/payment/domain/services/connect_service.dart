import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immosync/core/config/db_config.dart';

class ConnectService {
  final String _apiUrl = DbConfig.apiUrl;

  // Create Stripe Connect account for landlord
  Future<Map<String, dynamic>> createConnectAccount({
    required String landlordId,
    required String email,
    String businessType = 'individual',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/connect/create-account'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'landlordId': landlordId,
          'email': email,
          'businessType': businessType,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create Connect account: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating Connect account: $e');
    }
  }

  // Create onboarding link for landlord
  Future<String> createOnboardingLink({
    required String accountId,
    String? refreshUrl,
    String? returnUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/connect/create-onboarding-link'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'accountId': accountId,
          'refreshUrl': refreshUrl,
          'returnUrl': returnUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['url'];
      } else {
        throw Exception('Failed to create onboarding link: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating onboarding link: $e');
    }
  }

  // Get Connect account status
  Future<Map<String, dynamic>> getAccountStatus(String landlordId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/connect/account-status/$landlordId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get account status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting account status: $e');
    }
  }

  // Create AccountSession for embedded components
  Future<String> createAccountSession({
    required String accountId,
    Map<String, dynamic>? components,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/connect/account-session'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'accountId': accountId,
          'components': components,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['client_secret'];
      } else {
        throw Exception('Failed to create account session: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating account session: $e');
    }
  }

  // Create payment intent for tenant-to-landlord payment
  Future<Map<String, dynamic>> createTenantPayment({
    required String tenantId,
    required String propertyId,
    required double amount,
    String currency = 'chf',
    String paymentType = 'rent',
    String? description,
    String? preferredPaymentMethod,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/connect/create-tenant-payment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'tenantId': tenantId,
          'propertyId': propertyId,
          'amount': amount,
          'currency': currency,
          'paymentType': paymentType,
          'description': description,
          'preferredPaymentMethod': preferredPaymentMethod,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create payment');
      }
    } catch (e) {
      throw Exception('Error creating payment: $e');
    }
  }

  // Create setup intent for recurring payments
  Future<Map<String, dynamic>> createSetupIntent(String paymentMethodType) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/connect/create-setup-intent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'payment_method_type': paymentMethodType,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create setup intent: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating setup intent: $e');
    }
  }

  // Get available payment methods for region
  Future<List<PaymentMethod>> getAvailablePaymentMethods(String countryCode) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/connect/payment-methods/${countryCode.toLowerCase()}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PaymentMethod.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get payment methods: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting payment methods: $e');
    }
  }
}

class PaymentMethod {
  final String type;
  final String name;
  final String icon;
  final bool instant;
  final String? description;

  PaymentMethod({
    required this.type,
    required this.name,
    required this.icon,
    required this.instant,
    this.description,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      type: json['type'],
      name: json['name'],
      icon: json['icon'],
      instant: json['instant'] ?? false,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'icon': icon,
      'instant': instant,
      'description': description,
    };
  }
}
