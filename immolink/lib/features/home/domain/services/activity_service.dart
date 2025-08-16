import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/activity.dart';
import '../../../../core/config/db_config.dart';

class ActivityService {
  static String get baseUrl => DbConfig.apiUrl;

  // Get recent activities for a user
  Future<List<Activity>> getRecentActivities(String userId, {int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/activities/user/$userId?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Activity.fromJson(item)).toList();
      } else {
        print('Failed to fetch activities: ${response.statusCode}');
        return _getMockActivities(); // Fallback to mock data
      }
    } catch (e) {
      print('Error fetching activities: $e');
      return _getMockActivities(); // Fallback to mock data
    }
  }

  // Create a new activity
  Future<bool> createActivity({
    required String userId,
    required String title,
    required String description,
    required String type,
    String? relatedId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/activities'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'title': title,
          'description': description,
          'type': type,
          'relatedId': relatedId,
          'metadata': metadata,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error creating activity: $e');
      return false;
    }
  }

  // Mock data for when the API is not available
  List<Activity> _getMockActivities() {
    final now = DateTime.now();
    return [
      Activity(
        id: '1',
        title: 'Rent Payment Processed',
        description: 'Monthly rent payment of \$1,200 was successfully processed',
        type: 'payment',
        timestamp: now.subtract(Duration(hours: 2)),
        relatedId: 'payment_123',
        metadata: {'amount': 1200, 'method': 'auto'},
      ),
      Activity(
        id: '2',
        title: 'Maintenance Request Submitted',
        description: 'Submitted a request for kitchen sink repair',
        type: 'maintenance',
        timestamp: now.subtract(Duration(days: 1)),
        relatedId: 'maintenance_456',
        metadata: {'category': 'plumbing', 'priority': 'medium'},
      ),
      Activity(
        id: '3',
        title: 'New Message from Landlord',
        description: 'Received a message about upcoming property inspection',
        type: 'message',
        timestamp: now.subtract(Duration(days: 2)),
        relatedId: 'message_789',
        metadata: {'from': 'John Smith'},
      ),
      Activity(
        id: '4',
        title: 'Lease Agreement Updated',
        description: 'Lease agreement has been updated with new terms',
        type: 'property',
        timestamp: now.subtract(Duration(days: 5)),
        relatedId: 'property_101',
        metadata: {'documentType': 'lease'},
      ),
      Activity(
        id: '5',
        title: 'Service Booking Confirmed',
        description: 'Trash collection service booking confirmed for weekly pickup',
        type: 'service',
        timestamp: now.subtract(Duration(days: 7)),
        relatedId: 'service_202',
        metadata: {'service': 'trash_collection', 'frequency': 'weekly'},
      ),
    ];
  }

  // Get activities by type
  Future<List<Activity>> getActivitiesByType(String userId, String type) async {
    final activities = await getRecentActivities(userId, limit: 50);
    return activities.where((activity) => activity.type == type).toList();
  }

  // Delete an activity
  Future<bool> deleteActivity(String activityId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/activities/$activityId'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting activity: $e');
      return false;
    }
  }
}