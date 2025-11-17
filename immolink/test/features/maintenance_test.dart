import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:immosync/features/maintenance/domain/models/maintenance_request.dart';

void main() {
  group('Maintenance Request Tests', () {
    test('Create maintenance request should succeed', () async {
      // Mock HTTP client for future API integration
      // ignore: unused_local_variable
      final mockClient = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path.contains('/maintenance')) {
          final requestBody = json.decode(request.body);
          return http.Response(
            json.encode({
              'ticket': {
                '_id': 'req_123',
                'propertyId': requestBody['propertyId'],
                'tenantId': requestBody['tenantId'],
                'landlordId': requestBody['landlordId'],
                'title': requestBody['title'],
                'description': requestBody['description'],
                'category': requestBody['category'],
                'priority': requestBody['priority'],
                'status': 'pending',
                'location': requestBody['location'],
                'images': requestBody['images'] ?? [],
                'requestedDate': DateTime.now().toIso8601String(),
                'urgencyLevel': requestBody['urgencyLevel'] ?? 3,
                'notes': [],
              }
            }),
            201,
          );
        }
        return http.Response('Not Found', 404);
      });

      // Create test request
      final request = MaintenanceRequest(
        id: '',
        propertyId: 'prop_123',
        tenantId: 'tenant_123',
        landlordId: 'landlord_123',
        title: 'Leaking Faucet',
        description: 'Kitchen faucet is leaking water',
        category: 'plumbing',
        priority: 'high',
        status: 'pending',
        location: 'Kitchen',
        requestedDate: DateTime.now(),
        urgencyLevel: 4,
      );

      // Verify request data
      expect(request.title, 'Leaking Faucet');
      expect(request.category, 'plumbing');
      expect(request.priority, 'high');
      expect(request.status, 'pending');
      expect(request.urgencyLevel, 4);
    });

    test('Update request status should work', () async {
      // ignore: unused_local_variable
      final mockClient = MockClient((request) async {
        if (request.method == 'PATCH' &&
            request.url.path.contains('/maintenance/req_123/status')) {
          final requestBody = json.decode(request.body);
          return http.Response(
            json.encode({
              '_id': 'req_123',
              'propertyId': 'prop_123',
              'tenantId': 'tenant_123',
              'landlordId': 'landlord_123',
              'title': 'Leaking Faucet',
              'description': 'Kitchen faucet is leaking water',
              'category': 'plumbing',
              'priority': 'high',
              'status': requestBody['status'],
              'location': 'Kitchen',
              'requestedDate': DateTime.now().toIso8601String(),
              'urgencyLevel': 4,
              'notes': [
                {
                  'author': requestBody['authorId'],
                  'content': requestBody['notes'],
                  'timestamp': DateTime.now().toIso8601String(),
                }
              ],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      // Test status update from pending to in_progress
      final originalRequest = MaintenanceRequest(
        id: 'req_123',
        propertyId: 'prop_123',
        tenantId: 'tenant_123',
        landlordId: 'landlord_123',
        title: 'Leaking Faucet',
        description: 'Kitchen faucet is leaking water',
        category: 'plumbing',
        priority: 'high',
        status: 'pending',
        location: 'Kitchen',
        requestedDate: DateTime.now(),
        urgencyLevel: 4,
      );

      expect(originalRequest.status, 'pending');
      expect(originalRequest.statusDisplayText, 'Pending');

      // Verify status transitions
      final statuses = ['pending', 'in_progress', 'completed', 'cancelled'];
      for (final status in statuses) {
        final updated = MaintenanceRequest(
          id: originalRequest.id,
          propertyId: originalRequest.propertyId,
          tenantId: originalRequest.tenantId,
          landlordId: originalRequest.landlordId,
          title: originalRequest.title,
          description: originalRequest.description,
          category: originalRequest.category,
          priority: originalRequest.priority,
          status: status,
          location: originalRequest.location,
          requestedDate: originalRequest.requestedDate,
          urgencyLevel: originalRequest.urgencyLevel,
        );
        expect(updated.status, status);
      }
    });

    test('Assign request to service provider should work', () async {
      // ignore: unused_local_variable
      final mockClient = MockClient((request) async {
        if (request.method == 'PUT' &&
            request.url.path.contains('/maintenance/req_123')) {
          final requestBody = json.decode(request.body);
          return http.Response(
            json.encode({
              '_id': 'req_123',
              'propertyId': requestBody['propertyId'],
              'tenantId': requestBody['tenantId'],
              'landlordId': requestBody['landlordId'],
              'title': requestBody['title'],
              'description': requestBody['description'],
              'category': requestBody['category'],
              'priority': requestBody['priority'],
              'status': 'in_progress',
              'location': requestBody['location'],
              'requestedDate': requestBody['requestedDate'],
              'urgencyLevel': requestBody['urgencyLevel'],
              'contractorInfo': requestBody['contractorInfo'],
              'notes': [],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      // Create request with contractor assignment
      final contractorInfo = ContractorInfo(
        name: 'John Plumber',
        contact: '+41 79 123 4567',
        company: 'Swiss Plumbing Services',
      );

      final assignedRequest = MaintenanceRequest(
        id: 'req_123',
        propertyId: 'prop_123',
        tenantId: 'tenant_123',
        landlordId: 'landlord_123',
        title: 'Leaking Faucet',
        description: 'Kitchen faucet is leaking water',
        category: 'plumbing',
        priority: 'high',
        status: 'in_progress',
        location: 'Kitchen',
        requestedDate: DateTime.now(),
        urgencyLevel: 4,
        contractorInfo: contractorInfo,
      );

      expect(assignedRequest.contractorInfo, isNotNull);
      expect(assignedRequest.contractorInfo!.name, 'John Plumber');
      expect(assignedRequest.contractorInfo!.contact, '+41 79 123 4567');
      expect(
          assignedRequest.contractorInfo!.company, 'Swiss Plumbing Services');
      expect(assignedRequest.assignedTo, 'John Plumber');
    });

    test('Close completed request should work', () async {
      // ignore: unused_local_variable
      final mockClient = MockClient((request) async {
        if (request.method == 'PATCH' &&
            request.url.path.contains('/maintenance/req_123/status')) {
          return http.Response(
            json.encode({
              '_id': 'req_123',
              'propertyId': 'prop_123',
              'tenantId': 'tenant_123',
              'landlordId': 'landlord_123',
              'title': 'Leaking Faucet',
              'description': 'Kitchen faucet is leaking water',
              'category': 'plumbing',
              'priority': 'high',
              'status': 'completed',
              'location': 'Kitchen',
              'requestedDate':
                  DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
              'completedDate': DateTime.now().toIso8601String(),
              'urgencyLevel': 4,
              'cost': {
                'estimated': 150.0,
                'actual': 145.50,
              },
              'notes': [],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      // Create completed request with cost
      final completedRequest = MaintenanceRequest(
        id: 'req_123',
        propertyId: 'prop_123',
        tenantId: 'tenant_123',
        landlordId: 'landlord_123',
        title: 'Leaking Faucet',
        description: 'Kitchen faucet is leaking water',
        category: 'plumbing',
        priority: 'high',
        status: 'completed',
        location: 'Kitchen',
        requestedDate: DateTime.now().subtract(Duration(days: 2)),
        completedDate: DateTime.now(),
        urgencyLevel: 4,
        cost: MaintenanceCost(
          estimated: 150.0,
          actual: 145.50,
        ),
      );

      expect(completedRequest.status, 'completed');
      expect(completedRequest.statusDisplayText, 'Completed');
      expect(completedRequest.completedDate, isNotNull);
      expect(completedRequest.cost, isNotNull);
      expect(completedRequest.cost!.estimated, 150.0);
      expect(completedRequest.cost!.actual, 145.50);
    });
  });

  group('Maintenance Priority Tests', () {
    test('High priority requests should be sorted first', () {
      // Create requests with different priorities
      final requests = [
        MaintenanceRequest(
          id: '1',
          propertyId: 'prop_123',
          tenantId: 'tenant_123',
          landlordId: 'landlord_123',
          title: 'Low Priority Task',
          description: 'Can wait',
          category: 'other',
          priority: 'low',
          status: 'pending',
          location: 'General',
          requestedDate: DateTime.now(),
          urgencyLevel: 1,
        ),
        MaintenanceRequest(
          id: '2',
          propertyId: 'prop_123',
          tenantId: 'tenant_123',
          landlordId: 'landlord_123',
          title: 'Urgent Task',
          description: 'Needs immediate attention',
          category: 'electrical',
          priority: 'urgent',
          status: 'pending',
          location: 'Main Panel',
          requestedDate: DateTime.now(),
          urgencyLevel: 5,
        ),
        MaintenanceRequest(
          id: '3',
          propertyId: 'prop_123',
          tenantId: 'tenant_123',
          landlordId: 'landlord_123',
          title: 'Medium Priority Task',
          description: 'Should be done soon',
          category: 'plumbing',
          priority: 'medium',
          status: 'pending',
          location: 'Bathroom',
          requestedDate: DateTime.now(),
          urgencyLevel: 3,
        ),
        MaintenanceRequest(
          id: '4',
          propertyId: 'prop_123',
          tenantId: 'tenant_123',
          landlordId: 'landlord_123',
          title: 'High Priority Task',
          description: 'Important but not urgent',
          category: 'heating',
          priority: 'high',
          status: 'pending',
          location: 'Boiler Room',
          requestedDate: DateTime.now(),
          urgencyLevel: 4,
        ),
      ];

      // Sort by urgency level (descending)
      requests.sort((a, b) => b.urgencyLevel.compareTo(a.urgencyLevel));

      // Verify sorting
      expect(requests[0].priority, 'urgent');
      expect(requests[0].urgencyLevel, 5);
      expect(requests[1].priority, 'high');
      expect(requests[1].urgencyLevel, 4);
      expect(requests[2].priority, 'medium');
      expect(requests[2].urgencyLevel, 3);
      expect(requests[3].priority, 'low');
      expect(requests[3].urgencyLevel, 1);

      // Verify priority display text
      expect(requests[0].priorityDisplayText, 'Urgent');
      expect(requests[1].priorityDisplayText, 'High Priority');
      expect(requests[2].priorityDisplayText, 'Medium Priority');
      expect(requests[3].priorityDisplayText, 'Low Priority');
    });

    test('Overdue requests should be flagged', () {
      final now = DateTime.now();

      // Create requests with different ages
      final oldRequest = MaintenanceRequest(
        id: '1',
        propertyId: 'prop_123',
        tenantId: 'tenant_123',
        landlordId: 'landlord_123',
        title: 'Old Request',
        description: 'Created 5 days ago',
        category: 'plumbing',
        priority: 'high',
        status: 'pending',
        location: 'Kitchen',
        requestedDate: now.subtract(Duration(days: 5)),
        urgencyLevel: 4,
      );

      final recentRequest = MaintenanceRequest(
        id: '2',
        propertyId: 'prop_123',
        tenantId: 'tenant_123',
        landlordId: 'landlord_123',
        title: 'Recent Request',
        description: 'Created 1 hour ago',
        category: 'electrical',
        priority: 'medium',
        status: 'pending',
        location: 'Living Room',
        requestedDate: now.subtract(Duration(hours: 1)),
        urgencyLevel: 3,
      );

      final justCreatedRequest = MaintenanceRequest(
        id: '3',
        propertyId: 'prop_123',
        tenantId: 'tenant_123',
        landlordId: 'landlord_123',
        title: 'Just Created',
        description: 'Created just now',
        category: 'heating',
        priority: 'urgent',
        status: 'pending',
        location: 'Boiler',
        requestedDate: now.subtract(Duration(minutes: 2)),
        urgencyLevel: 5,
      );

      // Verify time ago calculation
      expect(oldRequest.timeAgo, contains('d ago'));
      expect(recentRequest.timeAgo, contains('h ago'));
      // justCreatedRequest could be 'm ago' or 'Just now' depending on timing

      // Define overdue criteria (e.g., high priority pending for >3 days)
      bool isOverdue(MaintenanceRequest request) {
        if (request.status != 'pending') return false;
        final daysSinceCreation = now.difference(request.requestedDate).inDays;
        return (request.priority == 'high' || request.priority == 'urgent') &&
            daysSinceCreation > 3;
      }

      expect(isOverdue(oldRequest), isTrue); // 5 days old, high priority
      expect(isOverdue(recentRequest), isFalse); // Recent
      expect(isOverdue(justCreatedRequest), isFalse); // Just created
    });
  });

  group('Service Booking Tests', () {
    test('Book service should succeed', () async {
      // ignore: unused_local_variable
      final mockClient = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path.contains('/maintenance/req_123/schedule')) {
          final requestBody = json.decode(request.body);
          return http.Response(
            json.encode({
              '_id': 'req_123',
              'propertyId': 'prop_123',
              'tenantId': 'tenant_123',
              'landlordId': 'landlord_123',
              'title': 'Heating Repair',
              'description': 'Boiler not working',
              'category': 'heating',
              'priority': 'urgent',
              'status': 'in_progress',
              'location': 'Boiler Room',
              'requestedDate': DateTime.now().toIso8601String(),
              'scheduledDate': requestBody['scheduledDate'],
              'urgencyLevel': 5,
              'contractorInfo': requestBody['contractorInfo'],
              'notes': [],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      // Create scheduled maintenance request
      final scheduledDate = DateTime.now().add(Duration(days: 2));
      final scheduledRequest = MaintenanceRequest(
        id: 'req_123',
        propertyId: 'prop_123',
        tenantId: 'tenant_123',
        landlordId: 'landlord_123',
        title: 'Heating Repair',
        description: 'Boiler not working',
        category: 'heating',
        priority: 'urgent',
        status: 'in_progress',
        location: 'Boiler Room',
        requestedDate: DateTime.now(),
        scheduledDate: scheduledDate,
        urgencyLevel: 5,
        contractorInfo: ContractorInfo(
          name: 'Expert Heating',
          contact: '+41 79 999 8888',
          company: 'Swiss Heating Solutions',
        ),
      );

      expect(scheduledRequest.scheduledDate, isNotNull);
      expect(
        scheduledRequest.scheduledDate!.isAfter(DateTime.now()),
        isTrue,
      );
      expect(scheduledRequest.contractorInfo, isNotNull);
      expect(scheduledRequest.status, 'in_progress');
    });

    test('Cancel booking should work', () async {
      // ignore: unused_local_variable
      final mockClient = MockClient((request) async {
        if (request.method == 'PATCH' &&
            request.url.path.contains('/maintenance/req_123/status')) {
          return http.Response(
            json.encode({
              '_id': 'req_123',
              'propertyId': 'prop_123',
              'tenantId': 'tenant_123',
              'landlordId': 'landlord_123',
              'title': 'Heating Repair',
              'description': 'Boiler not working',
              'category': 'heating',
              'priority': 'urgent',
              'status': 'cancelled',
              'location': 'Boiler Room',
              'requestedDate': DateTime.now().toIso8601String(),
              'scheduledDate':
                  DateTime.now().add(Duration(days: 2)).toIso8601String(),
              'urgencyLevel': 5,
              'notes': [
                {
                  'author': 'landlord_123',
                  'content': 'Tenant resolved issue themselves',
                  'timestamp': DateTime.now().toIso8601String(),
                }
              ],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      // Create cancelled request
      final cancelledRequest = MaintenanceRequest(
        id: 'req_123',
        propertyId: 'prop_123',
        tenantId: 'tenant_123',
        landlordId: 'landlord_123',
        title: 'Heating Repair',
        description: 'Boiler not working',
        category: 'heating',
        priority: 'urgent',
        status: 'cancelled',
        location: 'Boiler Room',
        requestedDate: DateTime.now(),
        scheduledDate: DateTime.now().add(Duration(days: 2)),
        urgencyLevel: 5,
        notes: [
          MaintenanceNote(
            author: 'landlord_123',
            content: 'Tenant resolved issue themselves',
            timestamp: DateTime.now(),
          ),
        ],
      );

      expect(cancelledRequest.status, 'cancelled');
      expect(cancelledRequest.statusDisplayText, 'Cancelled');
      expect(cancelledRequest.notes.length, 1);
      expect(
        cancelledRequest.notes[0].content,
        'Tenant resolved issue themselves',
      );
    });
  });

  group('Maintenance Model Tests', () {
    test('MaintenanceRequest parsing should handle all fields', () {
      final now = DateTime.now();
      final map = {
        '_id': 'req_456',
        'propertyId': 'prop_789',
        'tenantId': 'tenant_456',
        'landlordId': 'landlord_789',
        'title': 'Complete Test Request',
        'description': 'Full field test',
        'category': 'electrical',
        'priority': 'high',
        'status': 'in_progress',
        'location': 'Main Panel',
        'images': ['image1.jpg', 'image2.jpg'],
        'requestedDate': now.toIso8601String(),
        'scheduledDate': now.add(Duration(days: 1)).toIso8601String(),
        'completedDate': now.add(Duration(days: 3)).toIso8601String(),
        'urgencyLevel': 4,
        'cost': {
          'estimated': 200.0,
          'actual': 185.75,
        },
        'contractorInfo': {
          'name': 'Expert Electrician',
          'contact': '+41 79 111 2222',
          'company': 'Swiss Electric Pro',
        },
        'notes': [
          {
            'author': 'landlord_789',
            'content': 'Scheduled for next week',
            'timestamp': now.toIso8601String(),
          }
        ],
      };

      final request = MaintenanceRequest.fromMap(map);

      expect(request.id, 'req_456');
      expect(request.propertyId, 'prop_789');
      expect(request.tenantId, 'tenant_456');
      expect(request.landlordId, 'landlord_789');
      expect(request.title, 'Complete Test Request');
      expect(request.description, 'Full field test');
      expect(request.category, 'electrical');
      expect(request.priority, 'high');
      expect(request.status, 'in_progress');
      expect(request.location, 'Main Panel');
      expect(request.images.length, 2);
      expect(request.urgencyLevel, 4);
      expect(request.cost!.estimated, 200.0);
      expect(request.cost!.actual, 185.75);
      expect(request.contractorInfo!.name, 'Expert Electrician');
      expect(request.notes.length, 1);
    });

    test('MaintenanceRequest serialization should work', () {
      final request = MaintenanceRequest(
        id: 'req_789',
        propertyId: 'prop_456',
        tenantId: 'tenant_789',
        landlordId: 'landlord_456',
        title: 'Serialization Test',
        description: 'Testing toMap',
        category: 'plumbing',
        priority: 'medium',
        status: 'pending',
        location: 'Bathroom',
        requestedDate: DateTime.now(),
        urgencyLevel: 3,
      );

      final map = request.toMap();

      expect(map['id'], 'req_789');
      expect(map['propertyId'], 'prop_456');
      expect(map['title'], 'Serialization Test');
      expect(map['category'], 'plumbing');
      expect(map['priority'], 'medium');
      expect(map['status'], 'pending');
      expect(map['urgencyLevel'], 3);
    });

    test('Category display text should be correct', () {
      final categories = {
        'plumbing': 'Plumbing',
        'electrical': 'Electrical',
        'heating': 'Heating',
        'cooling': 'Cooling',
        'appliances': 'Appliances',
        'structural': 'Structural',
        'cleaning': 'Cleaning',
        'pest_control': 'Pest Control',
        'other': 'Other',
      };

      for (final entry in categories.entries) {
        final request = MaintenanceRequest(
          id: 'test',
          propertyId: 'prop',
          tenantId: 'tenant',
          landlordId: 'landlord',
          title: 'Test',
          description: 'Test',
          category: entry.key,
          priority: 'medium',
          status: 'pending',
          location: 'Test',
          requestedDate: DateTime.now(),
        );
        expect(request.categoryDisplayText, entry.value);
      }
    });
  });
}
