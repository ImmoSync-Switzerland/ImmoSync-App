import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immosync/core/config/db_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';

/// Service for handling Stripe Connect payments between tenants and landlords
class StripeConnectPaymentService {
  final String _apiUrl = DbConfig.apiUrl;
  final Ref? _ref;

  StripeConnectPaymentService({Ref? ref}) : _ref = ref;

  /// Get headers with authorization token if available
  Map<String, String> _getHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_ref != null) {
      try {
        final auth = _ref.read(authProvider);
        final token = auth.sessionToken;
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
          print(
              '[StripeConnect] Using auth token: ${token.substring(0, 20)}...');
        } else {
          print('[StripeConnect][WARN] No auth token available');
        }
      } catch (e) {
        print('[StripeConnect][ERROR] Could not get auth token: $e');
      }
    } else {
      print('[StripeConnect][WARN] No Ref provided, cannot include auth token');
    }
    return headers;
  }

  /// Create a Stripe Connect account for a landlord
  Future<StripeConnectAccount> createConnectAccount({
    required String landlordId,
    required String email,
    String? businessType,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      final url = '$_apiUrl/connect/create-account';
      print('[StripeConnect] Creating account at: $url');
      print(
          '[StripeConnect] Payload: landlordId=$landlordId, email=$email, businessType=${businessType ?? 'individual'}');

      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: json.encode({
          'landlordId': landlordId,
          'email': email,
          'businessType': businessType ?? 'individual',
          'additionalInfo': additionalInfo,
        }),
      );

      print('[StripeConnect] Response status: ${response.statusCode}');
      print('[StripeConnect] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return StripeConnectAccount.fromJson(data);
      } else {
        final error = json.decode(response.body);
        final errorMessage = error['message'] ??
            error['error'] ??
            'Failed to create Connect account';
        print('[StripeConnect][ERROR] API Error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[StripeConnect][ERROR] Exception: $e');
      throw Exception('Error creating Connect account: $e');
    }
  }

  /// Get the Stripe Connect account details for a landlord
  Future<StripeConnectAccount> getConnectAccount(String landlordId) async {
    try {
      final url = '$_apiUrl/connect/account/$landlordId';
      print('[StripeConnect] Getting account from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );

      print(
          '[StripeConnect] Get account response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StripeConnectAccount.fromJson(data);
      } else if (response.statusCode == 404) {
        print('[StripeConnect] No account found for landlord $landlordId');
        throw Exception('No Connect account found for this landlord');
      } else {
        print('[StripeConnect][ERROR] Failed to get account: ${response.body}');
        throw Exception('Failed to get Connect account');
      }
    } catch (e) {
      print('[StripeConnect][ERROR] Exception getting account: $e');
      throw Exception('Error getting Connect account: $e');
    }
  }

  /// Create an onboarding link for landlord to complete Stripe Connect setup
  Future<String> createOnboardingLink({
    required String accountId,
    String? refreshUrl,
    String? returnUrl,
  }) async {
    try {
      final url = '$_apiUrl/connect/create-onboarding-link';
      print('[StripeConnect] Creating onboarding link at: $url');
      print('[StripeConnect] AccountId: $accountId');

      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: json.encode({
          'accountId': accountId,
          'refreshUrl': refreshUrl ?? '${DbConfig.apiUrl}/refresh',
          'returnUrl': returnUrl ?? '${DbConfig.apiUrl}/return',
        }),
      );

      print(
          '[StripeConnect] Onboarding link response status: ${response.statusCode}');
      print('[StripeConnect] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['url'];
      } else {
        print(
            '[StripeConnect][ERROR] Failed to create onboarding link: ${response.body}');
        throw Exception('Failed to create onboarding link');
      }
    } catch (e) {
      print('[StripeConnect][ERROR] Exception creating onboarding link: $e');
      throw Exception('Error creating onboarding link: $e');
    }
  }

  /// Check if landlord has completed onboarding
  Future<bool> isOnboardingComplete(String landlordId) async {
    try {
      final account = await getConnectAccount(landlordId);
      return account.chargesEnabled && account.detailsSubmitted;
    } catch (e) {
      return false;
    }
  }

  /// Create a payment intent for tenant to pay landlord
  Future<TenantPaymentIntent> createTenantPayment({
    required String tenantId,
    required String landlordId,
    required String propertyId,
    required double amount,
    String currency = 'chf',
    String paymentType = 'rent',
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/connect/create-tenant-payment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'tenantId': tenantId,
          'landlordId': landlordId,
          'propertyId': propertyId,
          'amount': amount,
          'currency': currency.toLowerCase(),
          'paymentType': paymentType,
          'description': description ?? 'Rent payment for property $propertyId',
          'metadata': metadata,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return TenantPaymentIntent.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create payment');
      }
    } catch (e) {
      throw Exception('Error creating payment: $e');
    }
  }

  /// Confirm a payment after tenant completes Stripe checkout
  Future<PaymentResult> confirmPayment({
    required String paymentIntentId,
    String? paymentMethodId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/connect/confirm-payment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'paymentIntentId': paymentIntentId,
          'paymentMethodId': paymentMethodId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentResult.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to confirm payment');
      }
    } catch (e) {
      throw Exception('Error confirming payment: $e');
    }
  }

  /// Get payment history for a landlord
  Future<List<ConnectPayment>> getLandlordPayments({
    required String landlordId,
    int? limit,
    String? startingAfter,
  }) async {
    try {
      print('[StripeConnect] Fetching landlord payments for: $landlordId');
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (startingAfter != null) queryParams['starting_after'] = startingAfter;

      final uri = Uri.parse('$_apiUrl/connect/landlord-payments/$landlordId')
          .replace(queryParameters: queryParams);

      print('[StripeConnect] Request URL: $uri');
      final headers = _getHeaders();
      final response = await http.get(uri, headers: headers);

      print('[StripeConnect] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List;
        print('[StripeConnect] Received ${data.length} payments');
        return data.map((p) => ConnectPayment.fromJson(p)).toList();
      } else {
        print('[StripeConnect][ERROR] Failed response: ${response.body}');
        throw Exception(
            'Failed to get landlord payments: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('[StripeConnect][ERROR] Error getting landlord payments: $e');
      print('[StripeConnect][ERROR] Stack trace: $stackTrace');
      throw Exception('Error getting landlord payments: $e');
    }
  }

  /// Get payment history for a tenant
  Future<List<ConnectPayment>> getTenantPayments({
    required String tenantId,
    int? limit,
  }) async {
    try {
      print('[StripeConnect] Fetching tenant payments for: $tenantId');
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();

      final uri = Uri.parse('$_apiUrl/connect/tenant-payments/$tenantId')
          .replace(queryParameters: queryParams);

      final headers = _getHeaders();
      final response = await http.get(uri, headers: headers);

      print(
          '[StripeConnect] Tenant payments response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List;
        print('[StripeConnect] Received ${data.length} tenant payments');
        return data.map((p) => ConnectPayment.fromJson(p)).toList();
      } else {
        print('[StripeConnect][ERROR] Failed response: ${response.body}');
        throw Exception(
            'Failed to get tenant payments: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('[StripeConnect][ERROR] Error getting tenant payments: $e');
      print('[StripeConnect][ERROR] Stack trace: $stackTrace');
      throw Exception('Error getting tenant payments: $e');
    }
  }

  /// Get balance for a landlord's Connect account
  Future<AccountBalance> getAccountBalance(String landlordId) async {
    try {
      print('[StripeConnect] Fetching balance for landlord: $landlordId');
      final headers = _getHeaders();
      final response = await http.get(
        Uri.parse('$_apiUrl/connect/balance/$landlordId'),
        headers: headers,
      );

      print('[StripeConnect] Balance response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[StripeConnect] Balance data: $data');
        return AccountBalance.fromJson(data);
      } else {
        print(
            '[StripeConnect][ERROR] Failed balance response: ${response.body}');
        throw Exception(
            'Failed to get account balance: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('[StripeConnect][ERROR] Error getting account balance: $e');
      print('[StripeConnect][ERROR] Stack trace: $stackTrace');
      throw Exception('Error getting account balance: $e');
    }
  }

  /// Create a payout to landlord's bank account
  Future<Payout> createPayout({
    required String landlordId,
    required double amount,
    String currency = 'chf',
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/connect/create-payout'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'landlordId': landlordId,
          'amount': amount,
          'currency': currency.toLowerCase(),
          'description': description,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return Payout.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create payout');
      }
    } catch (e) {
      throw Exception('Error creating payout: $e');
    }
  }

  /// Get payout history for landlord
  Future<List<Payout>> getPayouts({
    required String landlordId,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();

      final uri = Uri.parse('$_apiUrl/connect/payouts/$landlordId')
          .replace(queryParameters: queryParams);

      print('[StripeConnectService.getPayouts] Fetching payouts from: $uri');

      final response = await http.get(
        uri,
        headers: _getHeaders(),
      );

      print(
          '[StripeConnectService.getPayouts] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List;
        return data.map((p) => Payout.fromJson(p)).toList();
      } else {
        print(
            '[StripeConnectService.getPayouts] Failed with status ${response.statusCode}: ${response.body}');
        throw Exception('Failed to get payouts');
      }
    } catch (e) {
      print('[StripeConnectService.getPayouts] Error: $e');
      throw Exception('Error getting payouts: $e');
    }
  }

  /// Create a refund for a payment
  Future<Refund> createRefund({
    required String paymentIntentId,
    double? amount,
    String? reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/connect/create-refund'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'paymentIntentId': paymentIntentId,
          'amount': amount,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return Refund.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create refund');
      }
    } catch (e) {
      throw Exception('Error creating refund: $e');
    }
  }

  /// Get available payment methods for a country
  Future<List<PaymentMethodInfo>> getAvailablePaymentMethods(
      String countryCode) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_apiUrl/connect/payment-methods/${countryCode.toUpperCase()}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((m) => PaymentMethodInfo.fromJson(m)).toList();
      } else {
        // Return default payment methods
        return [
          PaymentMethodInfo(
            type: 'card',
            name: 'Credit/Debit Card',
            icon: 'credit_card',
            instant: true,
          ),
        ];
      }
    } catch (e) {
      print('Error getting payment methods: $e');
      return [
        PaymentMethodInfo(
          type: 'card',
          name: 'Credit/Debit Card',
          icon: 'credit_card',
          instant: true,
        ),
      ];
    }
  }
}

// Models

class StripeConnectAccount {
  final String id;
  final String landlordId;
  final String accountId;
  final bool chargesEnabled;
  final bool detailsSubmitted;
  final bool payoutsEnabled;
  final String? country;
  final String? currency;
  final DateTime createdAt;

  StripeConnectAccount({
    required this.id,
    required this.landlordId,
    required this.accountId,
    required this.chargesEnabled,
    required this.detailsSubmitted,
    required this.payoutsEnabled,
    this.country,
    this.currency,
    required this.createdAt,
  });

  factory StripeConnectAccount.fromJson(Map<String, dynamic> json) {
    return StripeConnectAccount(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      landlordId: json['landlordId']?.toString() ?? '',
      accountId: json['accountId']?.toString() ?? '',
      chargesEnabled: json['chargesEnabled'] ?? false,
      detailsSubmitted: json['detailsSubmitted'] ?? false,
      payoutsEnabled: json['payoutsEnabled'] ?? false,
      country: json['country'],
      currency: json['currency'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'landlordId': landlordId,
      'accountId': accountId,
      'chargesEnabled': chargesEnabled,
      'detailsSubmitted': detailsSubmitted,
      'payoutsEnabled': payoutsEnabled,
      'country': country,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class TenantPaymentIntent {
  final String paymentIntentId;
  final String clientSecret;
  final double amount;
  final String currency;
  final String status;

  TenantPaymentIntent({
    required this.paymentIntentId,
    required this.clientSecret,
    required this.amount,
    required this.currency,
    required this.status,
  });

  factory TenantPaymentIntent.fromJson(Map<String, dynamic> json) {
    return TenantPaymentIntent(
      paymentIntentId: json['paymentIntentId'] ?? json['id'] ?? '',
      clientSecret: json['clientSecret'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'chf',
      status: json['status'] ?? 'requires_payment_method',
    );
  }
}

class PaymentResult {
  final String paymentIntentId;
  final String status;
  final double amount;
  final String currency;
  final DateTime? paidAt;
  final String? receiptUrl;

  PaymentResult({
    required this.paymentIntentId,
    required this.status,
    required this.amount,
    required this.currency,
    this.paidAt,
    this.receiptUrl,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      paymentIntentId: json['paymentIntentId'] ?? json['id'] ?? '',
      status: json['status'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'chf',
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      receiptUrl: json['receiptUrl'],
    );
  }
}

class ConnectPayment {
  final String id;
  final String paymentIntentId;
  final double amount;
  final String currency;
  final String status;
  final String? tenantId;
  final String? landlordId;
  final String? propertyId;
  final String paymentType;
  final DateTime createdAt;
  final String? description;
  final Map<String, dynamic>? metadata;

  ConnectPayment({
    required this.id,
    required this.paymentIntentId,
    required this.amount,
    required this.currency,
    required this.status,
    this.tenantId,
    this.landlordId,
    this.propertyId,
    required this.paymentType,
    required this.createdAt,
    this.description,
    this.metadata,
  });

  factory ConnectPayment.fromJson(Map<String, dynamic> json) {
    return ConnectPayment(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      paymentIntentId: json['paymentIntentId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'chf',
      status: json['status'] ?? '',
      tenantId: json['tenantId'],
      landlordId: json['landlordId'],
      propertyId: json['propertyId'],
      paymentType: json['paymentType'] ?? 'rent',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      description: json['description'],
      metadata: json['metadata'],
    );
  }
}

class AccountBalance {
  final double available;
  final double pending;
  final String currency;
  final List<BalanceTransaction>? recentTransactions;

  AccountBalance({
    required this.available,
    required this.pending,
    required this.currency,
    this.recentTransactions,
  });

  factory AccountBalance.fromJson(Map<String, dynamic> json) {
    return AccountBalance(
      available: (json['available'] ?? 0).toDouble(),
      pending: (json['pending'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'chf',
      recentTransactions: json['recentTransactions'] != null
          ? (json['recentTransactions'] as List)
              .map((t) => BalanceTransaction.fromJson(t))
              .toList()
          : null,
    );
  }
}

class BalanceTransaction {
  final String id;
  final double amount;
  final String currency;
  final String type;
  final DateTime createdAt;

  BalanceTransaction({
    required this.id,
    required this.amount,
    required this.currency,
    required this.type,
    required this.createdAt,
  });

  factory BalanceTransaction.fromJson(Map<String, dynamic> json) {
    return BalanceTransaction(
      id: json['id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'chf',
      type: json['type'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class Payout {
  final String id;
  final double amount;
  final String currency;
  final String status;
  final DateTime createdAt;
  final DateTime? arrivalDate;
  final String? description;

  Payout({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.arrivalDate,
    this.description,
  });

  factory Payout.fromJson(Map<String, dynamic> json) {
    return Payout(
      id: json['id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'chf',
      status: json['status'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      arrivalDate: json['arrivalDate'] != null
          ? DateTime.parse(json['arrivalDate'])
          : null,
      description: json['description'],
    );
  }
}

class Refund {
  final String id;
  final String paymentIntentId;
  final double amount;
  final String currency;
  final String status;
  final String? reason;
  final DateTime createdAt;

  Refund({
    required this.id,
    required this.paymentIntentId,
    required this.amount,
    required this.currency,
    required this.status,
    this.reason,
    required this.createdAt,
  });

  factory Refund.fromJson(Map<String, dynamic> json) {
    return Refund(
      id: json['id'] ?? '',
      paymentIntentId: json['paymentIntentId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'chf',
      status: json['status'] ?? '',
      reason: json['reason'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class PaymentMethodInfo {
  final String type;
  final String name;
  final String icon;
  final bool instant;
  final String? description;

  PaymentMethodInfo({
    required this.type,
    required this.name,
    required this.icon,
    required this.instant,
    this.description,
  });

  factory PaymentMethodInfo.fromJson(Map<String, dynamic> json) {
    return PaymentMethodInfo(
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      instant: json['instant'] ?? false,
      description: json['description'],
    );
  }
}
