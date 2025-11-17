import 'package:flutter_test/flutter_test.dart';
import 'package:immosync/features/property/domain/models/property.dart';
import 'package:immosync/features/auth/domain/models/user.dart';

void main() {
  group('Model Tests', () {
    test('Property model can be created and serialized', () {
      final address = Address(
        street: '123 Test St',
        city: 'Test City',
        postalCode: '12345',
        country: 'Test Country',
      );

      final details = PropertyDetails(
        rooms: 3,
        size: 100.0,
        amenities: ['parking', 'elevator'],
      );

      final property = Property(
        id: 'test-id',
        landlordId: 'landlord-id',
        tenantIds: ['tenant-1'],
        address: address,
        status: 'available',
        rentAmount: 1500.0,
        details: details,
        imageUrls: ['http://example.com/image.jpg'],
        outstandingPayments: 0.0,
      );

      expect(property.id, equals('test-id'));
      expect(property.rentAmount, equals(1500.0));

      final map = property.toMap();
      expect(map['rentAmount'], equals(1500.0));
      expect(map['status'], equals('available'));
    });

    test('User model can be created and serialized', () {
      final address = Address(
        street: '456 User St',
        city: 'User City',
        postalCode: '67890',
        country: 'User Country',
      );

      final user = User(
        id: 'user-id',
        email: 'test@example.com',
        fullName: 'Test User',
        birthDate: DateTime(1990, 1, 1),
        role: 'tenant',
        isAdmin: false,
        isValidated: true,
        address: address,
      );

      expect(user.email, equals('test@example.com'));
      expect(user.role, equals('tenant'));

      final map = user.toMap();
      expect(map['email'], equals('test@example.com'));
      expect(map['role'], equals('tenant'));
    });
  });
}
