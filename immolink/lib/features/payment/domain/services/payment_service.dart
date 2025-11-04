import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immosync/features/payment/domain/models/payment.dart';
import 'package:immosync/core/config/db_config.dart';
import 'package:immosync/core/services/token_manager.dart';

class PaymentService {
  final String _apiUrl = DbConfig.apiUrl;
  final TokenManager _tokenManager = TokenManager();

  Future<Map<String, String>> _headers() async {
    return await _tokenManager.getHeaders();
  }

  Future<List<Payment>> getPaymentsByTenant(String tenantId) async {
    try {
      var response = await http.get(
        Uri.parse('$_apiUrl/payments/tenant/$tenantId'),
        headers: await _headers(),
      );
      if (response.statusCode == 401) {
        await _tokenManager.refreshToken(_apiUrl);
        response = await http.get(
          Uri.parse('$_apiUrl/payments/tenant/$tenantId'),
          headers: await _headers(),
        );
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Payment.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load payments');
      }
    } catch (e) {
      print('Network error in getPaymentsByTenant: $e');
      return []; // Return empty list when offline
    }
  }

  Future<List<Payment>> getPaymentsByProperty(String propertyId) async {
    try {
      var response = await http.get(
        Uri.parse('$_apiUrl/payments/property/$propertyId'),
        headers: await _headers(),
      );
      if (response.statusCode == 401) {
        await _tokenManager.refreshToken(_apiUrl);
        response = await http.get(
          Uri.parse('$_apiUrl/payments/property/$propertyId'),
          headers: await _headers(),
        );
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Payment.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load payments');
      }
    } catch (e) {
      print('Network error in getPaymentsByProperty: $e');
      return []; // Return empty list when offline
    }
  }

  Future<List<Payment>> getPaymentsByLandlord(String landlordId) async {
    try {
      var response = await http.get(
        Uri.parse('$_apiUrl/payments/landlord/$landlordId'),
        headers: await _headers(),
      );
      if (response.statusCode == 401) {
        await _tokenManager.refreshToken(_apiUrl);
        response = await http.get(
          Uri.parse('$_apiUrl/payments/landlord/$landlordId'),
          headers: await _headers(),
        );
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Payment.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load payments');
      }
    } catch (e) {
      print('Network error in getPaymentsByLandlord: $e');
      return []; // Return empty list when offline
    }
  }

  Future<Payment> getPaymentById(String id) async {
    try {
      var response = await http.get(
        Uri.parse('$_apiUrl/payments/$id'),
        headers: await _headers(),
      );
      if (response.statusCode == 401) {
        await _tokenManager.refreshToken(_apiUrl);
        response = await http.get(
          Uri.parse('$_apiUrl/payments/$id'),
          headers: await _headers(),
        );
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Payment.fromMap(data);
      } else {
        throw Exception('Failed to load payment');
      }
    } catch (e) {
      print('Network error in getPaymentById: $e');
      // Return a placeholder payment when offline
      return Payment(
        id: 'offline-$id',
        propertyId: '',
        tenantId: '',
        amount: 0.0,
        date: DateTime.now(),
        status: 'Unknown',
        type: 'rent',
        notes: 'Unable to load payment details while offline',
      );
    }
  }

  Future<Payment> createPayment(Payment payment) async {
    try {
      var response = await http.post(
        Uri.parse('$_apiUrl/payments'),
        headers: await _headers(),
        body: json.encode(payment.toMap()),
      );
      if (response.statusCode == 401) {
        await _tokenManager.refreshToken(_apiUrl);
        response = await http.post(
          Uri.parse('$_apiUrl/payments'),
          headers: await _headers(),
          body: json.encode(payment.toMap()),
        );
      }

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Payment.fromMap(data);
      } else {
        throw Exception('Failed to create payment');
      }
    } catch (e) {
      print('Network error in createPayment: $e');
      // Return the payment with a temporary ID to simulate creation
      return payment.copyWith(
        id: 'offline-${DateTime.now().millisecondsSinceEpoch}',
        status: 'Pending',
      );
    }
  }

  Future<String> createPaymentIntent({
    required double amount,
    required String propertyId,
    required String tenantId,
    String? paymentType,
    String currency = 'usd',
  }) async {
    try {
      var response = await http.post(
        Uri.parse('$_apiUrl/payments/create-payment-intent'),
        headers: await _headers(),
        body: json.encode({
          'amount': amount,
          'currency': currency,
          'propertyId': propertyId,
          'tenantId': tenantId,
          'paymentType': paymentType ?? 'rent',
        }),
      );
      if (response.statusCode == 401) {
        await _tokenManager.refreshToken(_apiUrl);
        response = await http.post(
          Uri.parse('$_apiUrl/payments/create-payment-intent'),
          headers: await _headers(),
          body: json.encode({
            'amount': amount,
            'currency': currency,
            'propertyId': propertyId,
            'tenantId': tenantId,
            'paymentType': paymentType ?? 'rent',
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

  Future<Payment> updatePayment(Payment payment) async {
    try {
      var response = await http.put(
        Uri.parse('$_apiUrl/payments/${payment.id}'),
        headers: await _headers(),
        body: json.encode(payment.toMap()),
      );
      if (response.statusCode == 401) {
        await _tokenManager.refreshToken(_apiUrl);
        response = await http.put(
          Uri.parse('$_apiUrl/payments/${payment.id}'),
          headers: await _headers(),
          body: json.encode(payment.toMap()),
        );
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Payment.fromMap(data);
      } else {
        throw Exception('Failed to update payment');
      }
    } catch (e) {
      print('Network error in updatePayment: $e');
      // Return the updated payment to simulate successful update
      return payment.copyWith(
        status: payment.status,
      );
    }
  }

  Future<void> deletePayment(String id) async {
    try {
      var response = await http.delete(
        Uri.parse('$_apiUrl/payments/$id'),
        headers: await _headers(),
      );
      if (response.statusCode == 401) {
        await _tokenManager.refreshToken(_apiUrl);
        response = await http.delete(
          Uri.parse('$_apiUrl/payments/$id'),
          headers: await _headers(),
        );
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to delete payment');
      }
    } catch (e) {
      print('Network error in deletePayment: $e');
      // In offline mode, we just log the error but don't throw
      // This allows the UI to proceed as if the delete was successful
    }
  }

  Future<Payment> cancelPayment(String id) async {
    try {
      var response = await http.patch(
        Uri.parse('$_apiUrl/payments/$id/cancel'),
        headers: await _headers(),
      );
      if (response.statusCode == 401) {
        await _tokenManager.refreshToken(_apiUrl);
        response = await http.patch(
          Uri.parse('$_apiUrl/payments/$id/cancel'),
          headers: await _headers(),
        );
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Payment.fromMap(data);
      } else {
        throw Exception('Failed to cancel payment');
      }
    } catch (e) {
      print('Network error in cancelPayment: $e');
      // Return a cancelled payment to simulate successful cancellation
      throw Exception('Unable to cancel payment. Please try again.');
    }
  }

  Future<String> downloadReceipt(String paymentId) async {
    try {
      var response = await http.get(
        Uri.parse('$_apiUrl/payments/$paymentId/receipt'),
        headers: await _headers(),
      );
      if (response.statusCode == 401) {
        await _tokenManager.refreshToken(_apiUrl);
        response = await http.get(
          Uri.parse('$_apiUrl/payments/$paymentId/receipt'),
          headers: await _headers(),
        );
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['receiptUrl'] as String;
      } else {
        throw Exception('Failed to generate receipt');
      }
    } catch (e) {
      print('Network error in downloadReceipt: $e');
      throw Exception('Unable to download receipt. Please try again.');
    }
  }
}
