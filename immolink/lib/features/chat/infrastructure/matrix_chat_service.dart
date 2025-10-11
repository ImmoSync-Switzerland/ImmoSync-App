import 'package:path_provider/path_provider.dart';
import 'package:immosync/bridge.dart' as frb;
import 'package:immosync/core/config/db_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MatrixChatService {
  static final MatrixChatService instance = MatrixChatService._();
  MatrixChatService._();

  bool _inited = false;
  String? _readyUserId;
  bool _loggedIn = false;
  bool _syncStarted = false;

  Future<void> ensureInitialized({required String homeserver}) async {
    if (_inited) return;
    final dir = await getApplicationSupportDirectory();
    await frb.init(homeserver: homeserver, dataDir: dir.path);
    _inited = true;
  }

  Future<void> login(
      {required String username, required String password}) async {
    await frb.login(user: username, password: password);
    _loggedIn = true;
  }

  Future<String> sendMessage(
      {required String roomId, required String body}) async {
    return frb.sendMessage(roomId: roomId, body: body);
  }

  Future<void> startSync() async {
    if (_syncStarted) return;
    await frb.startSync();
    _syncStarted = true;
  }

  Future<void> stopSync() async {
    await frb.stopSync();
    _syncStarted = false;
  }

  Future<void> markRead({required String roomId, required String eventId}) {
    return frb.markRead(roomId: roomId, eventId: eventId);
  }

  /// Ensure the native Matrix bridge is fully ready (FRB initialized, client
  /// created, user logged in, sync started) for the given app user.
  /// This is safe to call repeatedly and will no-op if already ready.
  Future<void> ensureReadyForUser(String userId) async {
    if (_readyUserId == userId) return;
    // Fetch or provision account credentials from backend
    final api = DbConfig.apiUrl;
    Future<Map<String, dynamic>?> fetchAccount() async {
      final r = await http.get(Uri.parse('$api/matrix/account/$userId'));
      if (r.statusCode != 200) return null;
      return json.decode(r.body) as Map<String, dynamic>;
    }

    var data = await fetchAccount();
    if (data == null) {
      // Attempt to provision the account, then fetch again
      await http.post(Uri.parse('$api/matrix/provision'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'userId': userId}));
      data = await fetchAccount();
    }
    if (data == null) {
      throw Exception('Matrix account not available for user $userId');
    }

    final homeserver = (data['baseUrl'] as String?) ?? '';
    final username = data['username'] as String?;
    final password = data['password'] as String?;
    if (homeserver.isEmpty || username == null || password == null) {
      throw Exception('Incomplete Matrix credentials for user $userId');
    }

    await ensureInitialized(homeserver: homeserver);
    if (!_loggedIn) {
      await login(username: username, password: password);
    }
    if (!_syncStarted) {
      await startSync();
    }
    _readyUserId = userId;
  }
}
