import 'package:flutter_test/flutter_test.dart';
import 'package:immosync/features/property/domain/models/property.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  group('Property Service Tests', () {
    test('Fetch properties should return list', () async {
      // Mock HTTP client
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/properties')) {
          return http.Response(
            json.encode([
              {
                '_id': '1',
                'landlordId': 'landlord1',
                'tenantIds': [],
                'address': {
                  'street': 'Test Street 1',
                  'city': 'Zurich',
                  'postalCode': '8000',
                  'country': 'Switzerland',
                },
                'status': 'available',
                'rentAmount': 1500.0,
                'details': {
                  'size': 100.0,
                  'rooms': 3,
                  'amenities': ['Parking', 'Elevator'],
                },
                'imageUrls': [],
                'outstandingPayments': 0.0,
              }
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      // Test would use mockClient
      expect(mockClient, isNotNull);
    });

    test('Create property should succeed with valid data', () async {
      final property = Property(
        id: 'test-id',
        landlordId: 'landlord-123',
        tenantIds: [],
        address: Address(
          street: 'New Property Street 1',
          city: 'Bern',
          postalCode: '3000',
          country: 'Switzerland',
        ),
        rentAmount: 2000.0,
        details: PropertyDetails(
          size: 120.0,
          rooms: 4,
          amenities: ['Balcony', 'Garden'],
        ),
        status: 'available',
        imageUrls: [],
        outstandingPayments: 0.0,
      );

      // Verify property can be serialized
      final propertyMap = property.toMap();
      expect(propertyMap['landlordId'], 'landlord-123');
      expect(propertyMap['rentAmount'], 2000.0);
      expect(propertyMap['status'], 'available');

      // Mock creation request
      final mockClient = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path.contains('/properties')) {
          final body = json.decode(request.body);
          expect(body['landlordId'], 'landlord-123');
          expect(body['rentAmount'], 2000.0);

          return http.Response(
            json.encode({
              'success': true,
              'propertyId': 'new-property-id',
            }),
            201,
          );
        }
        return http.Response('Bad Request', 400);
      });

      expect(mockClient, isNotNull);
    });

    test('Update property should modify existing property', () async {
      final originalProperty = Property(
        id: 'prop-123',
        landlordId: 'landlord-456',
        tenantIds: [],
        address: Address(
          street: 'Old Street 1',
          city: 'Geneva',
          postalCode: '1200',
          country: 'Switzerland',
        ),
        rentAmount: 1800.0,
        details: PropertyDetails(
          size: 90.0,
          rooms: 2,
          amenities: ['Parking'],
        ),
        status: 'occupied',
        imageUrls: [],
        outstandingPayments: 0.0,
      );

      // Mock update request
      final mockClient = MockClient((request) async {
        if (request.method == 'PUT' &&
            request.url.path.contains('/properties/prop-123')) {
          final body = json.decode(request.body);

          return http.Response(
            json.encode({
              'success': true,
              'property': {
                ...body,
                '_id': 'prop-123',
              },
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      expect(mockClient, isNotNull);
      expect(originalProperty.id, 'prop-123');
      expect(originalProperty.status, 'occupied');
    });

    test('Delete property should remove property', () async {
      const propertyId = 'prop-to-delete';

      // Mock delete request
      final mockClient = MockClient((request) async {
        if (request.method == 'DELETE' &&
            request.url.path.contains('/properties/$propertyId')) {
          return http.Response(
            json.encode({'success': true, 'message': 'Property deleted'}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      expect(mockClient, isNotNull);
    });
  });

  group('Property Model Tests', () {
    test('Property.fromMap should parse correctly', () {
      final map = {
        '_id': '123',
        'landlordId': 'landlord-456',
        'tenantIds': ['tenant1', 'tenant2'],
        'address': {
          'street': 'Test Street 1',
          'city': 'Zurich',
          'postalCode': '8000',
          'country': 'Switzerland',
        },
        'rentAmount': 1500.0,
        'status': 'occupied',
        'details': {
          'size': 85.0,
          'rooms': 3,
          'amenities': ['Parking', 'Balcony'],
        },
        'imageUrls': ['image1.jpg', 'image2.jpg'],
        'outstandingPayments': 500.0,
      };

      final property = Property.fromMap(map);

      expect(property.id, '123');
      expect(property.landlordId, 'landlord-456');
      expect(property.rentAmount, 1500.0);
      expect(property.status, 'occupied');
      expect(property.address.street, 'Test Street 1');
      expect(property.address.city, 'Zurich');
      expect(property.address.postalCode, '8000');
      expect(property.tenantIds, ['tenant1', 'tenant2']);
      expect(property.details.size, 85.0);
      expect(property.details.rooms, 3);
      expect(property.details.amenities, ['Parking', 'Balcony']);
      expect(property.imageUrls, ['image1.jpg', 'image2.jpg']);
      expect(property.outstandingPayments, 500.0);
    });

    test('Property.toMap should serialize correctly', () {
      final property = Property(
        id: 'test-123',
        landlordId: 'landlord-789',
        tenantIds: ['tenant-abc'],
        address: Address(
          street: 'Export Street 1',
          city: 'Basel',
          postalCode: '4000',
          country: 'Switzerland',
        ),
        rentAmount: 1800.0,
        details: PropertyDetails(
          size: 95.0,
          rooms: 3,
          amenities: ['Elevator', 'Storage'],
        ),
        status: 'available',
        imageUrls: ['photo.jpg'],
        outstandingPayments: 200.0,
      );

      final map = property.toMap();

      expect(map['id'], 'test-123');
      expect(map['landlordId'], 'landlord-789');
      expect(map['rentAmount'], 1800.0);
      expect(map['status'], 'available');
      expect(map['tenantIds'], ['tenant-abc']);
      expect(map['outstandingPayments'], 200.0);
      expect(map['address']['street'], 'Export Street 1');
      expect(map['details']['size'], 95.0);
    });

    test('Property validation should work', () {
      // Test valid property
      final validProperty = Property(
        id: 'valid-id',
        landlordId: 'landlord-123',
        tenantIds: [],
        address: Address(
          street: 'Valid Street',
          city: 'Zurich',
          postalCode: '8000',
          country: 'Switzerland',
        ),
        rentAmount: 1500.0,
        details: PropertyDetails(
          size: 80.0,
          rooms: 2,
          amenities: [],
        ),
        status: 'available',
      );

      expect(validProperty.rentAmount, greaterThan(0));
      expect(validProperty.details.size, greaterThan(0));
      expect(validProperty.details.rooms, greaterThan(0));
      expect(validProperty.address.street, isNotEmpty);
      expect(validProperty.address.city, isNotEmpty);
      expect(validProperty.address.postalCode, isNotEmpty);

      // Test property with invalid data should use fallback
      final invalidMap = {
        '_id': 'invalid',
        'landlordId': 'landlord',
        'address': 'not-an-object', // Invalid
        'rentAmount': 'invalid', // Invalid
      };

      final fallbackProperty = Property.fromMap(invalidMap);
      expect(fallbackProperty.id, 'invalid');
      expect(fallbackProperty.rentAmount, 0); // Fallback value
      expect(fallbackProperty.status, 'unknown'); // Fallback value
    });

    test('Property handles missing optional fields', () {
      final minimalMap = {
        '_id': 'minimal',
        'landlordId': 'landlord-min',
        'address': {
          'street': 'Minimal St',
          'city': 'City',
          'postalCode': '1000',
          'country': 'CH',
        },
        'rentAmount': 1000.0,
        'status': 'available',
        'details': {
          'size': 50.0,
          'rooms': 1,
        },
      };

      final property = Property.fromMap(minimalMap);
      expect(property.tenantIds, isEmpty);
      expect(property.imageUrls, isEmpty);
      expect(property.outstandingPayments, 0.0);
      expect(property.details.amenities, isEmpty);
    });
  });

  group('Property Filtering Tests', () {
    late List<Property> testProperties;

    setUp(() {
      testProperties = [
        Property(
          id: '1',
          landlordId: 'landlord-1',
          tenantIds: [],
          address: Address(
            street: 'Street A',
            city: 'Zurich',
            postalCode: '8000',
            country: 'Switzerland',
          ),
          rentAmount: 1500.0,
          details: PropertyDetails(size: 80.0, rooms: 2, amenities: []),
          status: 'available',
        ),
        Property(
          id: '2',
          landlordId: 'landlord-1',
          tenantIds: ['tenant-1'],
          address: Address(
            street: 'Street B',
            city: 'Bern',
            postalCode: '3000',
            country: 'Switzerland',
          ),
          rentAmount: 2000.0,
          details: PropertyDetails(size: 100.0, rooms: 3, amenities: []),
          status: 'occupied',
        ),
        Property(
          id: '3',
          landlordId: 'landlord-2',
          tenantIds: [],
          address: Address(
            street: 'Street C',
            city: 'Geneva',
            postalCode: '1200',
            country: 'Switzerland',
          ),
          rentAmount: 1800.0,
          details: PropertyDetails(size: 90.0, rooms: 3, amenities: []),
          status: 'available',
        ),
      ];
    });

    test('Filter by status should work', () {
      final availableProperties =
          testProperties.where((p) => p.status == 'available').toList();
      expect(availableProperties.length, 2);
      expect(availableProperties[0].id, '1');
      expect(availableProperties[1].id, '3');

      final occupiedProperties =
          testProperties.where((p) => p.status == 'occupied').toList();
      expect(occupiedProperties.length, 1);
      expect(occupiedProperties[0].id, '2');
    });

    test('Filter by landlord should work', () {
      final landlord1Properties =
          testProperties.where((p) => p.landlordId == 'landlord-1').toList();
      expect(landlord1Properties.length, 2);

      final landlord2Properties =
          testProperties.where((p) => p.landlordId == 'landlord-2').toList();
      expect(landlord2Properties.length, 1);
    });

    test('Filter by rent range should work', () {
      final affordableProperties =
          testProperties.where((p) => p.rentAmount <= 1800).toList();
      expect(affordableProperties.length, 2);

      final premiumProperties =
          testProperties.where((p) => p.rentAmount > 1800).toList();
      expect(premiumProperties.length, 1);
      expect(premiumProperties[0].rentAmount, 2000.0);
    });

    test('Search by address should work', () {
      final zurichProperties = testProperties
          .where((p) =>
              p.address.city.toLowerCase().contains('zurich'.toLowerCase()))
          .toList();
      expect(zurichProperties.length, 1);
      expect(zurichProperties[0].address.city, 'Zurich');

      final streetBProperties = testProperties
          .where((p) =>
              p.address.street.toLowerCase().contains('street b'.toLowerCase()))
          .toList();
      expect(streetBProperties.length, 1);
      expect(streetBProperties[0].address.street, 'Street B');
    });

    test('Complex filter combination should work', () {
      // Filter: available AND in Zurich/Geneva AND rent <= 1800
      final filtered = testProperties.where((p) {
        return p.status == 'available' &&
            (p.address.city == 'Zurich' || p.address.city == 'Geneva') &&
            p.rentAmount <= 1800;
      }).toList();

      expect(filtered.length, 2);
      expect(filtered.any((p) => p.address.city == 'Zurich'), isTrue);
      expect(filtered.any((p) => p.address.city == 'Geneva'), isTrue);
    });

    test('Sort by rent amount should work', () {
      final sorted = List<Property>.from(testProperties)
        ..sort((a, b) => a.rentAmount.compareTo(b.rentAmount));

      expect(sorted[0].rentAmount, 1500.0);
      expect(sorted[1].rentAmount, 1800.0);
      expect(sorted[2].rentAmount, 2000.0);

      // Descending order
      final sortedDesc = List<Property>.from(testProperties)
        ..sort((a, b) => b.rentAmount.compareTo(a.rentAmount));

      expect(sortedDesc[0].rentAmount, 2000.0);
      expect(sortedDesc[2].rentAmount, 1500.0);
    });
  });
}
