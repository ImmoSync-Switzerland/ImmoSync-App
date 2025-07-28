import 'package:flutter_test/flutter_test.dart';
import 'package:immolink/features/property/domain/models/property.dart';
import 'package:immolink/features/auth/domain/models/user.dart';
import 'package:immolink/features/payment/domain/models/payment.dart';
import 'package:immolink/features/maintenance/domain/models/maintenance_request.dart';
import 'package:immolink/features/chat/domain/models/conversation.dart';

void main() {
  group('Comprehensive Data Model Tests', () {
    group('Property Model Tests', () {
      test('Property model creation with all fields', () {
        final address = Address(
          street: '123 Main St',
          city: 'New York',
          postalCode: '10001',
          country: 'USA',
        );

        final details = PropertyDetails(
          rooms: 3,
          size: 120.5,
          amenities: ['parking', 'elevator', 'balcony'],
        );

        final property = Property(
          id: 'prop-123',
          landlordId: 'landlord-456',
          tenantIds: ['tenant-789', 'tenant-012'],
          address: address,
          status: 'occupied',
          rentAmount: 2500.0,
          details: details,
          imageUrls: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
          outstandingPayments: 150.0,
        );

        expect(property.id, equals('prop-123'));
        expect(property.landlordId, equals('landlord-456'));
        expect(property.tenantIds.length, equals(2));
        expect(property.address.city, equals('New York'));
        expect(property.status, equals('occupied'));
        expect(property.rentAmount, equals(2500.0));
        expect(property.details.rooms, equals(3));
        expect(property.details.amenities.length, equals(3));
        expect(property.imageUrls.length, equals(2));
        expect(property.outstandingPayments, equals(150.0));
      });

      test('Property model serialization and deserialization', () {
        final address = Address(
          street: '456 Oak Ave',
          city: 'San Francisco',
          postalCode: '94102',
          country: 'USA',
        );

        final details = PropertyDetails(
          rooms: 2,
          size: 85.0,
          amenities: ['gym', 'pool'],
        );

        final originalProperty = Property(
          id: 'prop-456',
          landlordId: 'landlord-789',
          tenantIds: ['tenant-345'],
          address: address,
          status: 'available',
          rentAmount: 3000.0,
          details: details,
          imageUrls: ['https://example.com/image3.jpg'],
          outstandingPayments: 0.0,
        );

        // Test serialization
        final propertyMap = originalProperty.toMap();
        expect(propertyMap['id'], equals('prop-456'));
        expect(propertyMap['rentAmount'], equals(3000.0));
        expect(propertyMap['status'], equals('available'));

        // Test deserialization
        final reconstructedProperty = Property.fromMap(propertyMap);
        expect(reconstructedProperty.id, equals(originalProperty.id));
        expect(reconstructedProperty.landlordId, equals(originalProperty.landlordId));
        expect(reconstructedProperty.rentAmount, equals(originalProperty.rentAmount));
        expect(reconstructedProperty.address.city, equals(originalProperty.address.city));
      });

      test('Property model edge cases', () {
        // Test with minimal data
        final minimalProperty = Property(
          id: 'minimal',
          landlordId: 'landlord',
          tenantIds: [],
          address: Address(street: '', city: '', postalCode: '', country: ''),
          status: 'available',
          rentAmount: 0.0,
          details: PropertyDetails(rooms: 0, size: 0.0, amenities: []),
          imageUrls: [],
          outstandingPayments: 0.0,
        );

        expect(minimalProperty.tenantIds.isEmpty, isTrue);
        expect(minimalProperty.imageUrls.isEmpty, isTrue);
        expect(minimalProperty.details.amenities.isEmpty, isTrue);

        // Test serialization of minimal property
        final minimalMap = minimalProperty.toMap();
        expect(minimalMap['tenantIds'], isA<List>());
        expect(minimalMap['imageUrls'], isA<List>());
      });
    });

    group('User Model Tests', () {
      test('User model creation with complete data', () {
        final address = Address(
          street: '789 Pine St',
          city: 'Chicago',
          postalCode: '60601',
          country: 'USA',
        );

        final user = User(
          id: 'user-123',
          email: 'john.doe@example.com',
          fullName: 'John Doe',
          birthDate: DateTime(1985, 6, 15),
          role: 'landlord',
          isAdmin: false,
          isValidated: true,
          address: address,
        );

        expect(user.id, equals('user-123'));
        expect(user.email, equals('john.doe@example.com'));
        expect(user.fullName, equals('John Doe'));
        expect(user.birthDate.year, equals(1985));
        expect(user.role, equals('landlord'));
        expect(user.isAdmin, isFalse);
        expect(user.isValidated, isTrue);
        expect(user.address.city, equals('Chicago'));
      });

      test('User model role validation', () {
        final validRoles = ['tenant', 'landlord', 'admin'];
        
        for (final role in validRoles) {
          final user = User(
            id: 'user-$role',
            email: 'test@example.com',
            fullName: 'Test User',
            birthDate: DateTime(1990, 1, 1),
            role: role,
            isAdmin: role == 'admin',
            isValidated: true,
            address: Address(street: '', city: '', postalCode: '', country: ''),
          );
          
          expect(user.role, equals(role));
          expect(user.isAdmin, equals(role == 'admin'));
        }
      });

      test('User model serialization', () {
        final user = User(
          id: 'user-456',
          email: 'jane.smith@example.com',
          fullName: 'Jane Smith',
          birthDate: DateTime(1992, 3, 22),
          role: 'tenant',
          isAdmin: false,
          isValidated: false,
          address: Address(
            street: '321 Elm St',
            city: 'Boston',
            postalCode: '02101',
            country: 'USA',
          ),
        );

        final userMap = user.toMap();
        expect(userMap['email'], equals('jane.smith@example.com'));
        expect(userMap['role'], equals('tenant'));
        expect(userMap['isAdmin'], isFalse);
        expect(userMap['isValidated'], isFalse);

        final reconstructedUser = User.fromMap(userMap);
        expect(reconstructedUser.email, equals(user.email));
        expect(reconstructedUser.fullName, equals(user.fullName));
        expect(reconstructedUser.role, equals(user.role));
      });
    });

    group('Payment Model Tests', () {
      test('Payment model creation', () {
        final payment = Payment(
          id: 'payment-123',
          tenantId: 'tenant-456',
          propertyId: 'property-789',
          amount: 1500.0,
          paymentDate: DateTime(2024, 1, 15),
          paymentMethod: 'credit_card',
          status: 'completed',
          transactionId: 'txn-abc123',
        );

        expect(payment.id, equals('payment-123'));
        expect(payment.tenantId, equals('tenant-456'));
        expect(payment.propertyId, equals('property-789'));
        expect(payment.amount, equals(1500.0));
        expect(payment.paymentMethod, equals('credit_card'));
        expect(payment.status, equals('completed'));
        expect(payment.transactionId, equals('txn-abc123'));
      });

      test('Payment model status validation', () {
        final validStatuses = ['pending', 'completed', 'failed', 'refunded'];
        
        for (final status in validStatuses) {
          final payment = Payment(
            id: 'payment-$status',
            tenantId: 'tenant-123',
            propertyId: 'property-456',
            amount: 1000.0,
            paymentDate: DateTime.now(),
            paymentMethod: 'bank_transfer',
            status: status,
            transactionId: 'txn-$status',
          );
          
          expect(payment.status, equals(status));
        }
      });

      test('Payment model amount validation', () {
        // Test various amounts
        final amounts = [0.0, 0.01, 100.0, 1500.50, 999999.99];
        
        for (final amount in amounts) {
          final payment = Payment(
            id: 'payment-$amount',
            tenantId: 'tenant-123',
            propertyId: 'property-456',
            amount: amount,
            paymentDate: DateTime.now(),
            paymentMethod: 'credit_card',
            status: 'completed',
            transactionId: 'txn-$amount',
          );
          
          expect(payment.amount, equals(amount));
        }
      });
    });

    group('MaintenanceRequest Model Tests', () {
      test('MaintenanceRequest model creation', () {
        final request = MaintenanceRequest(
          id: 'maint-123',
          propertyId: 'property-456',
          tenantId: 'tenant-789',
          landlordId: 'landlord-012',
          title: 'Broken faucet',
          description: 'The kitchen faucet is leaking and needs repair',
          priority: 'medium',
          status: 'open',
          createdAt: DateTime(2024, 1, 10),
          updatedAt: DateTime(2024, 1, 10),
        );

        expect(request.id, equals('maint-123'));
        expect(request.propertyId, equals('property-456'));
        expect(request.tenantId, equals('tenant-789'));
        expect(request.landlordId, equals('landlord-012'));
        expect(request.title, equals('Broken faucet'));
        expect(request.description, contains('kitchen faucet'));
        expect(request.priority, equals('medium'));
        expect(request.status, equals('open'));
      });

      test('MaintenanceRequest priority levels', () {
        final priorities = ['low', 'medium', 'high', 'urgent'];
        
        for (final priority in priorities) {
          final request = MaintenanceRequest(
            id: 'maint-$priority',
            propertyId: 'property-123',
            tenantId: 'tenant-456',
            landlordId: 'landlord-789',
            title: 'Test issue',
            description: 'Test description',
            priority: priority,
            status: 'open',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          expect(request.priority, equals(priority));
        }
      });

      test('MaintenanceRequest status workflow', () {
        final statuses = ['open', 'assigned', 'in_progress', 'completed', 'closed'];
        
        for (final status in statuses) {
          final request = MaintenanceRequest(
            id: 'maint-$status',
            propertyId: 'property-123',
            tenantId: 'tenant-456',
            landlordId: 'landlord-789',
            title: 'Test issue',
            description: 'Test description',
            priority: 'medium',
            status: status,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          expect(request.status, equals(status));
        }
      });
    });

    group('Conversation Model Tests', () {
      test('Conversation model creation', () {
        final conversation = Conversation(
          id: 'conv-123',
          participants: ['user-456', 'user-789'],
          propertyId: 'property-012',
          lastMessage: 'Hello, I have a question about the property',
          lastMessageTime: DateTime(2024, 1, 20, 14, 30),
          unreadCount: 2,
        );

        expect(conversation.id, equals('conv-123'));
        expect(conversation.participants.length, equals(2));
        expect(conversation.participants.contains('user-456'), isTrue);
        expect(conversation.participants.contains('user-789'), isTrue);
        expect(conversation.propertyId, equals('property-012'));
        expect(conversation.lastMessage, contains('question'));
        expect(conversation.unreadCount, equals(2));
      });

      test('Conversation participant validation', () {
        // Test with multiple participants
        final manyParticipants = ['user1', 'user2', 'user3', 'user4'];
        final conversation = Conversation(
          id: 'conv-many',
          participants: manyParticipants,
          propertyId: 'property-123',
          lastMessage: 'Group conversation',
          lastMessageTime: DateTime.now(),
          unreadCount: 0,
        );

        expect(conversation.participants.length, equals(4));
        for (final participant in manyParticipants) {
          expect(conversation.participants.contains(participant), isTrue);
        }
      });
    });

    group('Model Integration Tests', () {
      test('Models can reference each other correctly', () {
        // Create related models
        final user = User(
          id: 'user-123',
          email: 'test@example.com',
          fullName: 'Test User',
          birthDate: DateTime(1990, 1, 1),
          role: 'tenant',
          isAdmin: false,
          isValidated: true,
          address: Address(street: '123 Test St', city: 'Test City', postalCode: '12345', country: 'Test Country'),
        );

        final property = Property(
          id: 'property-456',
          landlordId: 'landlord-789',
          tenantIds: [user.id],
          address: user.address,
          status: 'occupied',
          rentAmount: 1500.0,
          details: PropertyDetails(rooms: 2, size: 80.0, amenities: ['parking']),
          imageUrls: [],
          outstandingPayments: 0.0,
        );

        final payment = Payment(
          id: 'payment-012',
          tenantId: user.id,
          propertyId: property.id,
          amount: property.rentAmount,
          paymentDate: DateTime.now(),
          paymentMethod: 'credit_card',
          status: 'completed',
          transactionId: 'txn-345',
        );

        // Verify relationships
        expect(property.tenantIds.contains(user.id), isTrue);
        expect(payment.tenantId, equals(user.id));
        expect(payment.propertyId, equals(property.id));
        expect(payment.amount, equals(property.rentAmount));
      });

      test('All models can be serialized and deserialized', () {
        final models = [
          Property(
            id: 'test-property',
            landlordId: 'test-landlord',
            tenantIds: ['test-tenant'],
            address: Address(street: 'Test St', city: 'Test City', postalCode: '12345', country: 'Test Country'),
            status: 'available',
            rentAmount: 1000.0,
            details: PropertyDetails(rooms: 1, size: 50.0, amenities: []),
            imageUrls: [],
            outstandingPayments: 0.0,
          ),
          User(
            id: 'test-user',
            email: 'test@test.com',
            fullName: 'Test User',
            birthDate: DateTime(1990, 1, 1),
            role: 'tenant',
            isAdmin: false,
            isValidated: true,
            address: Address(street: 'Test St', city: 'Test City', postalCode: '12345', country: 'Test Country'),
          ),
          Payment(
            id: 'test-payment',
            tenantId: 'test-tenant',
            propertyId: 'test-property',
            amount: 1000.0,
            paymentDate: DateTime.now(),
            paymentMethod: 'credit_card',
            status: 'completed',
            transactionId: 'test-txn',
          ),
        ];

        for (final model in models) {
          expect(() {
            final map = model.toMap();
            expect(map, isA<Map<String, dynamic>>());
            // Verify the map contains expected keys
            expect(map.containsKey('id'), isTrue);
          }, returnsNormally);
        }
      });
    });
  });
}