import 'package:immosync/features/chat/domain/services/chat_service.dart';
import 'package:immosync/features/maintenance/domain/services/maintenance_service.dart';
import 'package:immosync/features/chat/domain/models/conversation.dart';
import 'package:immosync/features/maintenance/domain/models/maintenance_request.dart';

class DashboardService {
  final ChatService _chatService = ChatService();
  final MaintenanceService _maintenanceService = MaintenanceService();

  // Get recent messages for dashboard
  Future<List<Conversation>> getRecentMessages(String userId) async {
    try {
      return await _chatService.getRecentConversations(userId);
    } catch (e) {
      print('Error fetching recent messages for dashboard: $e');
      return [];
    }
  }

  // Get recent maintenance requests for dashboard
  Future<List<MaintenanceRequest>> getRecentMaintenanceRequests(
      String landlordId) async {
    try {
      return await _maintenanceService.getRecentMaintenanceRequests(landlordId);
    } catch (e) {
      print('Error fetching recent maintenance requests for dashboard: $e');
      return [];
    }
  }

  // Fetch all dashboard data at once
  Future<DashboardData> getDashboardData(String userId,
      {String? landlordId}) async {
    try {
      final futures = await Future.wait([
        getRecentMessages(userId),
        getRecentMaintenanceRequests(landlordId ?? userId),
      ]);

      return DashboardData(
        recentMessages: futures[0] as List<Conversation>,
        recentMaintenanceRequests: futures[1] as List<MaintenanceRequest>,
      );
    } catch (e) {
      print('Error fetching dashboard data: $e');
      return DashboardData(
        recentMessages: [],
        recentMaintenanceRequests: [],
      );
    }
  }
}

class DashboardData {
  final List<Conversation> recentMessages;
  final List<MaintenanceRequest> recentMaintenanceRequests;

  const DashboardData({
    required this.recentMessages,
    required this.recentMaintenanceRequests,
  });
}
