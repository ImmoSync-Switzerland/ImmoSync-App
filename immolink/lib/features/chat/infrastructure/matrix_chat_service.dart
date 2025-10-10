import 'package:path_provider/path_provider.dart';
import 'package:immosync/bridge.dart' as frb;

class MatrixChatService {
  static final MatrixChatService instance = MatrixChatService._();
  MatrixChatService._();

  bool _inited = false;

  Future<void> ensureInitialized({required String homeserver}) async {
    if (_inited) return;
    final dir = await getApplicationSupportDirectory();
    await frb.init(homeserver: homeserver, dataDir: dir.path);
    _inited = true;
  }

  Future<void> login(
      {required String username, required String password}) async {
    await frb.login(user: username, password: password);
  }

  Future<String> sendMessage(
      {required String roomId, required String body}) async {
    return frb.sendMessage(roomId: roomId, body: body);
  }

  Future<void> startSync() async {
    await frb.startSync();
  }

  Future<void> stopSync() async {
    await frb.stopSync();
  }

  Future<void> markRead({required String roomId, required String eventId}) {
    return frb.markRead(roomId: roomId, eventId: eventId);
  }
}
