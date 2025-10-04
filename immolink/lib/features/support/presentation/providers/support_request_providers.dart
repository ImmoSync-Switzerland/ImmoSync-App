import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/support_request.dart';
import '../../domain/services/support_request_service.dart';

final supportRequestsProvider = FutureProvider.autoDispose<List<SupportRequest>>((ref) async {
  final svc = ref.watch(supportRequestServiceProvider);
  return svc.list();
});