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
  
  // For now, we'll simulate a stream by fetching data periodically
  // In a real implementation, this could be a WebSocket or periodic polling
  try {
    final activities = await activityService.getRecentActivities(currentUser.id);
    yield activities;
  } catch (e) {
    print('Error loading activities: $e');
    yield [];
  }
});

// Activities by type provider
final activitiesByTypeProvider = StreamProvider.family<List<Activity>, String>((ref, type) async* {
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null) {
    yield [];
    return;
  }

  final activityService = ref.watch(activityServiceProvider);
  
  try {
    final activities = await activityService.getActivitiesByType(currentUser.id, type);
    yield activities;
  } catch (e) {
    print('Error loading activities by type: $e');
    yield [];
  }
});

// Activity creation provider
final activityCreationProvider = StateNotifierProvider<ActivityCreationNotifier, AsyncValue<void>>((ref) {
  return ActivityCreationNotifier(ref.watch(activityServiceProvider));
});

class ActivityCreationNotifier extends StateNotifier<AsyncValue<void>> {
  final ActivityService _activityService;

  ActivityCreationNotifier(this._activityService) : super(const AsyncValue.data(null));

  Future<void> createActivity({
    required String userId,
    required String title,
    required String description,
    required String type,
    String? relatedId,
    Map<String, dynamic>? metadata,
  }) async {
    state = const AsyncValue.loading();

    try {
      final success = await _activityService.createActivity(
        userId: userId,
        title: title,
        description: description,
        type: type,
        relatedId: relatedId,
        metadata: metadata,
      );

      if (success) {
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.error('Failed to create activity', StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}