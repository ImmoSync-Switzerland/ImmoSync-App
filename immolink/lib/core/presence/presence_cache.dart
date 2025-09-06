import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presence_ws_service.dart';

class PresenceInfo {
  final bool online;
  final DateTime lastSeen;
  const PresenceInfo({required this.online, required this.lastSeen});
}

class PresenceCache extends StateNotifier<Map<String, PresenceInfo>> {
  PresenceCache() : super(const {});

  void upsert(String userId, PresenceInfo info) {
    final copy = Map<String, PresenceInfo>.from(state);
    copy[userId] = info;
    state = UnmodifiableMapView(copy);
  }
}

final presenceCacheProvider =
    StateNotifierProvider<PresenceCache, Map<String, PresenceInfo>>((ref) {
  final cache = PresenceCache();
  final ws = ref.watch(presenceWsServiceProvider);
  ws.stream.listen((u) {
    cache.upsert(
        u.userId, PresenceInfo(online: u.online, lastSeen: u.lastSeen));
  });
  return cache;
});
