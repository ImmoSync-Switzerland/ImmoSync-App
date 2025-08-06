import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('Testing HTTP connection...');
  
  // Test HTTP first
  try {
    print('\n=== Testing HTTP ===');
    final httpResponse = await http.get(
      Uri.parse('http://backend.immosync.ch/api/health'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'ImmoLink-Flutter-Test/1.0.0',
      },
    ).timeout(Duration(seconds: 10));
    
    print('HTTP Status: ${httpResponse.statusCode}');
    print('HTTP Body: ${httpResponse.body}');
    print('HTTP Headers: ${httpResponse.headers}');
  } catch (e) {
    print('HTTP Error: $e');
  }
  
  // Test HTTPS
  try {
    print('\n=== Testing HTTPS ===');
    final httpsResponse = await http.get(
      Uri.parse('https://backend.immosync.ch/api/health'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'ImmoLink-Flutter-Test/1.0.0',
      },
    ).timeout(Duration(seconds: 10));
    
    print('HTTPS Status: ${httpsResponse.statusCode}');
    print('HTTPS Body: ${httpsResponse.body}');
    print('HTTPS Headers: ${httpsResponse.headers}');
  } catch (e) {
    print('HTTPS Error: $e');
  }
  
  // Test with disabled certificate verification
  try {
    print('\n=== Testing HTTPS with disabled cert verification ===');
    HttpOverrides.global = MyHttpOverrides();
    
    final httpsUnsafeResponse = await http.get(
      Uri.parse('https://backend.immosync.ch/api/health'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'ImmoLink-Flutter-Test/1.0.0',
      },
    ).timeout(Duration(seconds: 10));
    
    print('HTTPS (unsafe) Status: ${httpsUnsafeResponse.statusCode}');
    print('HTTPS (unsafe) Body: ${httpsUnsafeResponse.body}');
  } catch (e) {
    print('HTTPS (unsafe) Error: $e');
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
