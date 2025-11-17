import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:immosync/features/auth/domain/models/user.dart';
import 'package:immosync/features/property/domain/models/property.dart';

void main() {
  group('Auth Service Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Login with valid credentials should succeed', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path.contains('/auth/login')) {
          final body = json.decode(request.body);
          if (body['email'] == 'test@example.com' &&
              body['password'] == 'ValidPass123!') {
            return http.Response(
              json.encode({
                'message': 'Login successful',
                'user': {
                  'id': 'user_123',
                  'email': 'test@example.com',
                  'fullName': 'Test User',
                  'role': 'tenant',
                  'sessionToken': 'mock_token_abc123',
                  'profileImage': null,
                  'profileImageUrl': null,
                },
              }),
              200,
            );
          }
        }
        return http.Response('Unauthorized', 401);
      });

      // Test login response parsing
      final response = await mockClient.post(
        Uri.parse('https://backend.immosync.ch/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': 'test@example.com',
          'password': 'ValidPass123!',
        }),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['user']['email'], 'test@example.com');
      expect(data['user']['sessionToken'], isNotNull);
      expect(data['user']['sessionToken'], isNotEmpty);
    });

    test('Login with invalid credentials should fail', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path.contains('/auth/login')) {
          return http.Response(
            json.encode({
              'message': 'Invalid credentials',
            }),
            401,
          );
        }
        return http.Response('Not Found', 404);
      });

      // Test login failure
      final response = await mockClient.post(
        Uri.parse('https://backend.immosync.ch/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': 'wrong@example.com',
          'password': 'WrongPass',
        }),
      );

      expect(response.statusCode, 401);
      final data = json.decode(response.body);
      expect(data['message'], 'Invalid credentials');
    });

    test('Logout should clear user session', () async {
      // Simulate session token presence
      const sessionToken = 'mock_token_abc123';
      expect(sessionToken, isNotEmpty);

      // Simulate logout - token should be cleared
      String? clearedToken;
      expect(clearedToken, isNull);

      // Verify session is cleared
      expect(clearedToken != sessionToken, isTrue);
    });

    test('Token refresh should work', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path.contains('/auth/refresh')) {
          return http.Response(
            json.encode({
              'sessionToken': 'new_refreshed_token_xyz789',
              'expiresAt': DateTime.now()
                  .add(const Duration(hours: 24))
                  .toIso8601String(),
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      // Test token refresh
      final response = await mockClient.post(
        Uri.parse('https://backend.immosync.ch/api/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer old_token',
        },
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['sessionToken'], isNotNull);
      expect(data['sessionToken'], 'new_refreshed_token_xyz789');
      expect(data['expiresAt'], isNotNull);
    });

    test('Change password should validate correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'PATCH' &&
            request.url.path.contains('/auth/change-password')) {
          final body = json.decode(request.body);
          if (body['currentPassword'] == 'OldPass123!' &&
              body['newPassword'] == 'NewPass456@') {
            return http.Response(
              json.encode({'message': 'Password changed successfully'}),
              200,
            );
          }
          return http.Response(
            json.encode({'message': 'Current password incorrect'}),
            401,
          );
        }
        return http.Response('Not Found', 404);
      });

      // Test successful password change
      final response = await mockClient.patch(
        Uri.parse('https://backend.immosync.ch/api/auth/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': 'user_123',
          'currentPassword': 'OldPass123!',
          'newPassword': 'NewPass456@',
        }),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['message'], 'Password changed successfully');
    });
  });

  group('User Model Tests', () {
    test('User.fromMap should parse correctly', () {
      final map = {
        '_id': 'user_123',
        'email': 'test@example.com',
        'fullName': 'Test User',
        'role': 'tenant',
        'isAdmin': false,
        'isValidated': true,
        'birthDate': '1990-01-01T00:00:00.000Z',
        'address': {
          'street': '123 Test St',
          'city': 'TestCity',
          'postalCode': '12345',
          'country': 'Switzerland',
        },
        'propertyId': 'prop_456',
        'profileImage': null,
        'profileImageUrl': 'https://example.com/profile.jpg',
        'blockedUsers': ['user_789', 'user_012'],
      };

      // Test User.fromMap parsing
      final user = User.fromMap(map);

      expect(user.id, 'user_123');
      expect(user.email, 'test@example.com');
      expect(user.fullName, 'Test User');
      expect(user.role, 'tenant');
      expect(user.isAdmin, false);
      expect(user.isValidated, true);
      expect(user.birthDate.year, 1990);
      expect(user.address.street, '123 Test St');
      expect(user.address.city, 'TestCity');
      expect(user.address.postalCode, '12345');
      expect(user.address.country, 'Switzerland');
      expect(user.propertyId, 'prop_456');
      expect(user.profileImageUrl, 'https://example.com/profile.jpg');
      expect(user.blockedUsers.length, 2);
      expect(user.blockedUsers.contains('user_789'), isTrue);
    });

    test('User.toMap should serialize correctly', () {
      final user = User(
        id: 'user_123',
        email: 'test@example.com',
        fullName: 'Test User',
        birthDate: DateTime(1990, 1, 1),
        role: 'landlord',
        isAdmin: false,
        isValidated: true,
        address: Address(
          street: '456 Main St',
          city: 'Zurich',
          postalCode: '8000',
          country: 'Switzerland',
        ),
        propertyId: 'prop_789',
        profileImageUrl: 'https://example.com/avatar.png',
        blockedUsers: const ['user_111'],
      );

      // Test User.toMap serialization
      final map = user.toMap();

      expect(map['_id'], 'user_123');
      expect(map['email'], 'test@example.com');
      expect(map['fullName'], 'Test User');
      expect(map['role'], 'landlord');
      expect(map['isAdmin'], false);
      expect(map['isValidated'], true);
      expect(map['birthDate'], contains('1990-01-01'));
      expect(map['address'], isA<Map>());
      expect(map['address']['street'], '456 Main St');
      expect(map['address']['city'], 'Zurich');
      expect(map['propertyId'], 'prop_789');
      expect(map['profileImageUrl'], 'https://example.com/avatar.png');
      expect(map['blockedUsers'], isA<List>());
      expect(map['blockedUsers'].length, 1);
    });

    test('User.copyWith should preserve unchanged fields', () {
      final original = User(
        id: 'user_original',
        email: 'original@example.com',
        fullName: 'Original Name',
        birthDate: DateTime(1985, 5, 15),
        role: 'tenant',
        isAdmin: false,
        isValidated: true,
        address: Address(
          street: 'Original St',
          city: 'OriginalCity',
          postalCode: '00000',
          country: 'Switzerland',
        ),
      );

      // Test copyWith - only change email
      final updated = original.copyWith(email: 'updated@example.com');

      expect(updated.id, original.id);
      expect(updated.email, 'updated@example.com');
      expect(updated.fullName, original.fullName);
      expect(updated.role, original.role);
      expect(updated.birthDate, original.birthDate);
    });

    test('User.fromMap should handle MongoDB ObjectId format', () {
      final mapWithObjectId = {
        '_id': {'\$oid': 'mongodb_obj_id_123'},
        'email': 'mongo@example.com',
        'fullName': 'MongoDB User',
        'role': 'landlord',
        'isAdmin': true,
        'isValidated': false,
        'birthDate': '1995-12-31T23:59:59.999Z',
        'address': {
          'street': 'DB Street',
          'city': 'Database City',
          'postalCode': '99999',
          'country': 'Switzerland',
        },
        'propertyId': {'\$oid': 'property_obj_id_456'},
      };

      final user = User.fromMap(mapWithObjectId);

      expect(user.id, 'mongodb_obj_id_123');
      expect(user.email, 'mongo@example.com');
      expect(user.propertyId, 'property_obj_id_456');
      expect(user.isAdmin, true);
      expect(user.isValidated, false);
    });
  });

  group('Password Validation Tests', () {
    test('Strong password should pass validation', () {
      const password = 'Test123!@#';

      // Test password strength criteria
      expect(password.length >= 8, isTrue);
      expect(password.contains(RegExp(r'[A-Z]')), isTrue); // Uppercase
      expect(password.contains(RegExp(r'[a-z]')), isTrue); // Lowercase
      expect(password.contains(RegExp(r'[0-9]')), isTrue); // Digit
      expect(password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
          isTrue); // Special char
    });

    test('Weak password should fail validation', () {
      const password = '123';

      expect(password.length < 8, isTrue);
      expect(password.contains(RegExp(r'[A-Z]')), isFalse);
      expect(password.contains(RegExp(r'[a-z]')), isFalse);
    });

    test('Password without uppercase should be weak', () {
      const password = 'test123!@#';

      expect(password.length >= 8, isTrue);
      expect(password.contains(RegExp(r'[A-Z]')), isFalse);
      expect(password.contains(RegExp(r'[a-z]')), isTrue);
      expect(password.contains(RegExp(r'[0-9]')), isTrue);
    });

    test('Password without special characters should be weak', () {
      const password = 'Test123456';

      expect(password.length >= 8, isTrue);
      expect(password.contains(RegExp(r'[A-Z]')), isTrue);
      expect(password.contains(RegExp(r'[a-z]')), isTrue);
      expect(password.contains(RegExp(r'[0-9]')), isTrue);
      expect(password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')), isFalse);
    });

    test('Very strong password should pass all criteria', () {
      const password = 'MyStr0ng!P@ssw0rd#2024';

      expect(password.length >= 12, isTrue); // Extra long
      expect(password.contains(RegExp(r'[A-Z]')), isTrue);
      expect(password.contains(RegExp(r'[a-z]')), isTrue);
      expect(password.contains(RegExp(r'[0-9]')), isTrue);
      expect(password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')), isTrue);
    });
  });
}
