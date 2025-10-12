import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/support_request.dart';
import '../../domain/services/support_request_service.dart';

/// Provides only open (and in-progress) support requests for quick access.
final openSupportRequestsProvider =
    FutureProvider<List<SupportRequest>>((ref) async {
  final svc = ref.watch(supportRequestServiceProvider);
  // Backend supports status filter for single status; fetch open and in_progress then merge.
  final open = await svc.list(status: 'open');
  final inProg = await svc.list(status: 'in_progress');
  // Deduplicate by id
  final map = {
    for (var r in [...open, ...inProg]) r.id: r
  };
  return map.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});
