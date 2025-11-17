import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('Backend Connectivity Tests', () {
    const String apiUrl = 'https://backend.immosync.ch/api';

    test('Test backend connectivity', () async {
      try {
        print('Testing connectivity to: $apiUrl');

        // Try to reach the backend with a simple request
        final response = await http.get(
          Uri.parse('$apiUrl/documents/landlord/test_landlord'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 10));

        print('Backend response status: ${response.statusCode}');
        print('Backend response body: ${response.body}');

        // We expect either 200 (success) or 401/404 (endpoint exists but no data/auth)
        // What we don't want is connection timeout or network errors
        expect(response.statusCode, anyOf([200, 401, 404, 500]));
      } catch (e) {
        print('Backend connectivity error: $e');
        // Fail the test if we can't connect at all
        expect(e.toString(), contains('should be reachable'));
      }
    });

    test('Test document upload endpoint accessibility', () async {
      try {
        print('Testing document upload endpoint accessibility');

        // Try to reach the upload endpoint (should fail with 400 due to no file, but that's ok)
        final request = http.MultipartRequest(
            'POST', Uri.parse('$apiUrl/documents/upload'));
        request.fields['name'] = 'test';
        request.fields['description'] = 'test';
        request.fields['category'] = 'test';
        request.fields['uploadedBy'] = 'test_user';

        final response =
            await request.send().timeout(const Duration(seconds: 10));
        final responseData = await response.stream.bytesToString();

        print('Upload endpoint response status: ${response.statusCode}');
        print('Upload endpoint response: $responseData');

        // We expect 400 (bad request due to missing file) - this means the endpoint is reachable
        // We don't want timeout or connection errors
        expect(response.statusCode, anyOf([400, 401, 500]));
      } catch (e) {
        print('Upload endpoint connectivity error: $e');
        // Fail the test if we can't connect at all
        expect(e.toString(), contains('should be reachable'));
      }
    });
  });
}
