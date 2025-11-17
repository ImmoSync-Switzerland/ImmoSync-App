import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple script to test backend connectivity
/// Run with: dart run test_backend_connection.dart
void main() async {
  const apiUrl = 'https://backend.immosync.ch/api';

  print('=== Testing ImmoLink Backend Connectivity ===\n');

  // Test 1: Health Check
  print('1. Testing health endpoint...');
  try {
    final healthResponse = await http.get(
      Uri.parse('$apiUrl/health'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    print('   ✓ Health check status: ${healthResponse.statusCode}');
    print('   Response: ${healthResponse.body}\n');
  } catch (e) {
    print('   ✗ Health check failed: $e\n');
  }

  // Test 2: Stripe Connect - Available Payment Methods
  print('2. Testing Stripe Connect payment methods endpoint...');
  try {
    final paymentMethodsResponse = await http.get(
      Uri.parse('$apiUrl/connect/payment-methods/CH'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    print('   ✓ Payment methods status: ${paymentMethodsResponse.statusCode}');
    if (paymentMethodsResponse.statusCode == 200) {
      final methods = json.decode(paymentMethodsResponse.body);
      print('   Available methods: $methods');
    } else {
      print('   Response: ${paymentMethodsResponse.body}');
    }
    print('');
  } catch (e) {
    print('   ✗ Payment methods check failed: $e\n');
  }

  // Test 3: Check if Stripe Connect account endpoint is available
  print('3. Testing Stripe Connect account endpoint (expecting 404)...');
  try {
    final accountResponse = await http.get(
      Uri.parse('$apiUrl/connect/account/test-landlord-id'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    print('   Status: ${accountResponse.statusCode}');
    if (accountResponse.statusCode == 404) {
      print('   ✓ Endpoint exists (404 is expected for non-existent account)');
    } else if (accountResponse.statusCode == 200) {
      print('   ✓ Endpoint exists and found an account');
    } else {
      print('   ✗ Unexpected status code');
    }
    print('   Response: ${accountResponse.body}\n');
  } catch (e) {
    print('   ✗ Account endpoint test failed: $e\n');
  }

  print('=== Test Complete ===');
  print('\nIf all tests show ✗, the backend might be down or unreachable.');
  print('If tests show ✓, the backend is working and ready for the app.');
}
