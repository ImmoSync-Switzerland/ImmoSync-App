import '../models/activity.dart';
import '../../../../core/config/db_config.dart';
import '../../../maintenance/domain/models/maintenance_request.dart';
import '../../../maintenance/domain/services/maintenance_service.dart';
import '../../../payment/domain/models/payment.dart';
import '../../../payment/domain/services/payment_service.dart';

class ActivityService {
  static String get baseUrl => DbConfig.apiUrl;
  final MaintenanceService _maintenanceService = MaintenanceService();
  final PaymentService _paymentService = PaymentService();

  // Get recent activities for a user by aggregating real data
  Future<List<Activity>> getRecentActivities(String userId,
      {int limit = 10}) async {
    try {
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

      // Return limited number of activities
      return activities.take(limit).toList();
    } catch (e) {
      print('[ActivityService] Error fetching activities: $e');
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
