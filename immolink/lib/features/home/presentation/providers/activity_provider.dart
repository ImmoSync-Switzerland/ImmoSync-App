import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/activity.dart';
import '../../domain/services/activity_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Activity service provider
final activityServiceProvider = Provider<ActivityService>((ref) {
  return ActivityService();
});

// Recent activities provider for current user
final recentActivitiesProvider = StreamProvider<List<Activity>>((ref) async* {
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    yield [];
    return;
  }

  final activityService = ref.watch(activityServiceProvider);

  // Simulate a stream by fetching data periodically
  while (true) {
    try {
      final activities =
          await activityService.getRecentActivities(currentUser.id);
      yield activities;
    } catch (e) {
      print('[ActivityProvider] Error loading activities: $e');
      // Don't yield empty list on error - keep showing previous data
    }

    // Wait 30 seconds before next refresh
    await Future.delayed(const Duration(seconds: 30));
  }
});

// Activities by type provider
final activitiesByTypeProvider =
    StreamProvider.family<List<Activity>, String>((ref, type) async* {
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    yield [];
    return;
  }

  final activityService = ref.watch(activityServiceProvider);

  try {
    final activities =
        await activityService.getActivitiesByType(currentUser.id, type);
    yield activities;
  } catch (e) {
    print('Error loading activities by type: $e');
    yield [];
  }
});
