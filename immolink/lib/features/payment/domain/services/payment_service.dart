import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immosync/features/payment/domain/models/payment.dart';
import 'package:immosync/core/config/db_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:crypto/crypto.dart';

class PaymentService {
  final String _apiUrl = DbConfig.apiUrl;

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
          print('AUTH DEBUG [PaymentService]: obtained token; prefix=$prefix');
        }
      } else {
        print('AUTH DEBUG [PaymentService]: UI-JWT exchange failed ${ex.statusCode} ${ex.body}');
      }
    } catch (e) {
      print('AUTH DEBUG [PaymentService]: UI-JWT exchange error: $e');
    }
  }

  Future<Map<String, String>> _headers() async {
    final base = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('sessionToken');
      if (token != null && token.isNotEmpty) {
        base['Authorization'] = 'Bearer $token';
        base['x-access-token'] = token;
      }
    } catch (_) {}
    return base;
  }

  Future<List<Payment>> getPaymentsByTenant(String tenantId) async {
    try {
      var response = await http.get(
        Uri.parse('$_apiUrl/payments/tenant/$tenantId'),
        headers: await _headers(),
      );
      if (response.statusCode == 401) {
        await _tryLoginExchangeWithUiJwt();
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
        await _tryLoginExchangeWithUiJwt();
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
        await _tryLoginExchangeWithUiJwt();
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
        await _tryLoginExchangeWithUiJwt();
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
        await _tryLoginExchangeWithUiJwt();
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
        await _tryLoginExchangeWithUiJwt();
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
        await _tryLoginExchangeWithUiJwt();
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
        await _tryLoginExchangeWithUiJwt();
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
        await _tryLoginExchangeWithUiJwt();
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
        await _tryLoginExchangeWithUiJwt();
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
