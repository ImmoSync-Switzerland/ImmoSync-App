import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity.dart';
import '../../../../core/config/db_config.dart';
import '../../../maintenance/domain/models/maintenance_request.dart';
import '../../../maintenance/domain/services/maintenance_service.dart';
import '../../../payment/domain/models/payment.dart';
import '../../../payment/domain/services/payment_service.dart';

class ActivityService {
  static String get baseUrl => DbConfig.apiUrl;
  static const String _cacheKey = 'cached_activities';
  static const Duration _cacheExpiry = Duration(hours: 1);

  final MaintenanceService _maintenanceService = MaintenanceService();
  final PaymentService _paymentService = PaymentService();

  // Get cached activities
  Future<List<Activity>?> _getCachedActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      if (cachedData == null) return null;

      final Map<String, dynamic> cache = json.decode(cachedData);
      final cacheTime = DateTime.parse(cache['timestamp']);

      // Check if cache is expired
      if (DateTime.now().difference(cacheTime) > _cacheExpiry) {
        print('[ActivityService] Cache expired, will fetch fresh data');
        return null;
      }

      final List<dynamic> activitiesJson = cache['activities'];
      final activities =
          activitiesJson.map((json) => Activity.fromMap(json)).toList();

      print(
          '[ActivityService] Loaded ${activities.length} activities from cache');
      return activities;
    } catch (e) {
      print('[ActivityService] Error reading cache: $e');
      return null;
    }
  }

  // Save activities to cache
  Future<void> _cacheActivities(List<Activity> activities) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'activities': activities.map((a) => a.toMap()).toList(),
      };
      await prefs.setString(_cacheKey, json.encode(cacheData));
      print('[ActivityService] Cached ${activities.length} activities');
    } catch (e) {
      print('[ActivityService] Error caching activities: $e');
    }
  }

  // Get recent activities for a user by aggregating real data
  Future<List<Activity>> getRecentActivities(String userId,
      {int limit = 10, bool forceRefresh = false}) async {
    try {
      // Try to load from cache first (unless force refresh)
      if (!forceRefresh) {
        final cachedActivities = await _getCachedActivities();
        if (cachedActivities != null && cachedActivities.isNotEmpty) {
          return cachedActivities.take(limit).toList();
        }
      }

      print('[ActivityService] Fetching fresh activities from server...');
      final List<Activity> activities = [];

      // Fetch maintenance requests
      try {
        final maintenanceRequests =
            await _maintenanceService.getMaintenanceRequestsByTenant(userId);
        for (var request in maintenanceRequests) {
          activities.add(_maintenanceRequestToActivity(request));
        }
      } catch (e) {
        print('[ActivityService] Error loading maintenance requests: $e');
      }

      // Fetch payments
      try {
        final payments = await _paymentService.getPaymentsByTenant(userId);
        for (var payment in payments) {
          activities.add(_paymentToActivity(payment));
        }
      } catch (e) {
        print('[ActivityService] Error loading payments: $e');
      }

      // Sort by timestamp (newest first)
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Cache the activities
      if (activities.isNotEmpty) {
        await _cacheActivities(activities);
      }

      // Return limited number of activities
      return activities.take(limit).toList();
    } catch (e) {
      print('[ActivityService] Error fetching activities: $e');

      // Try to return cached data as fallback
      final cachedActivities = await _getCachedActivities();
      if (cachedActivities != null) {
        print('[ActivityService] Returning cached data as fallback');
        return cachedActivities.take(limit).toList();
      }

      return [];
    }
  }

  // Convert maintenance request to activity
  Activity _maintenanceRequestToActivity(MaintenanceRequest request) {
    final statusText = _getMaintenanceStatusText(request.status);
    return Activity(
      id: 'maint_${request.id}',
      title: 'Maintenance: ${request.title}',
      description: '$statusText - ${request.category}',
      type: 'maintenance',
      timestamp: request.requestedDate,
      relatedId: request.id,
      metadata: {
        'category': request.category,
        'priority': request.priority,
        'status': request.status,
        'location': request.location,
      },
    );
  }

  String _getMaintenanceStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Request submitted';
      case 'in_progress':
        return 'In progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Request submitted';
    }
  }

  // Convert payment to activity
  Activity _paymentToActivity(Payment payment) {
    final statusText = _getPaymentStatusText(payment.status);
    return Activity(
      id: 'payment_${payment.id}',
      title: 'Payment: ${payment.type}',
      description: '$statusText - \$${payment.amount.toStringAsFixed(2)}',
      type: 'payment',
      timestamp: payment.date,
      relatedId: payment.id,
      metadata: {
        'amount': payment.amount,
        'type': payment.type,
        'status': payment.status,
        'method': payment.paymentMethod,
      },
    );
  }

  String _getPaymentStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Payment completed';
      case 'pending':
        return 'Payment pending';
      case 'failed':
        return 'Payment failed';
      case 'refunded':
        return 'Payment refunded';
      default:
        return 'Payment processed';
    }
  }

  // Get activities by type
  Future<List<Activity>> getActivitiesByType(String userId, String type) async {
    final activities = await getRecentActivities(userId, limit: 50);
    return activities.where((activity) => activity.type == type).toList();
  }
}
