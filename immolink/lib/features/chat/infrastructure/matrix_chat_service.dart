import 'package:path_provider/path_provider.dart';
import 'package:immosync/bridge.dart' as frb;
import 'package:immosync/core/config/db_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class MatrixChatService {
  static final MatrixChatService instance = MatrixChatService._();
  MatrixChatService._();

  bool _inited = false;
  String? _readyUserId;
  bool _loggedIn = false;
  bool _syncStarted = false;
  Future<void>? _initializationInProgress;

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
    print('[MatrixChatService] ensureReadyForUser called for userId=$userId');
    
    // Validate userId before proceeding
    if (userId.isEmpty || userId == 'null' || userId == 'unknown-user') {
      print('[MatrixChatService] ERROR: Invalid userId "$userId", skipping Matrix initialization');
      throw Exception('Invalid userId for Matrix initialization: $userId');
    }
    
    if (_readyUserId == userId) {
      print('[MatrixChatService] Already ready for user $userId');
      return;
    }
    
    // If initialization is already in progress, wait for it to complete
    if (_initializationInProgress != null) {
      print('[MatrixChatService] Initialization already in progress, waiting...');
      await _initializationInProgress;
      print('[MatrixChatService] Previous initialization completed');
      return;
    }
    
    // Mark initialization as in progress
    final completer = Completer<void>();
    _initializationInProgress = completer.future;
    
    try {
      // Fetch or provision account credentials from backend
      final api = DbConfig.apiUrl;
    print('[MatrixChatService] Fetching Matrix account from $api/matrix/account/$userId');
    
    Future<Map<String, dynamic>?> fetchAccount() async {
      final r = await http.get(Uri.parse('$api/matrix/account/$userId'));
      print('[MatrixChatService] Fetch account response: ${r.statusCode}');
      if (r.statusCode != 200) return null;
      return json.decode(r.body) as Map<String, dynamic>;
    }

    var data = await fetchAccount();
    if (data == null) {
      // Attempt to provision the account, then fetch again
      print('[MatrixChatService] Account not found, attempting to provision...');
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
    print('[MatrixChatService] Credentials: homeserver=$homeserver, username=$username');
    
    if (homeserver.isEmpty || username == null || password == null) {
      throw Exception('Incomplete Matrix credentials for user $userId');
    }

    print('[MatrixChatService] Initializing Matrix client...');
    
    // Try to initialize, if it fails with device mismatch, clear and retry
    try {
      await ensureInitialized(homeserver: homeserver);
    } catch (e) {
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('account in the store doesn\'t match') || 
          errorMsg.contains('device mismatch')) {
        print('[MatrixChatService] Device mismatch during init, clearing store...');
        final dir = await getApplicationSupportDirectory();
        final storeDir = Directory(dir.path);
        if (await storeDir.exists()) {
          print('[MatrixChatService] Deleting store directory: ${dir.path}');
          await storeDir.delete(recursive: true);
          print('[MatrixChatService] Store deleted, reinitializing...');
        }
        _inited = false;
        await ensureInitialized(homeserver: homeserver);
        print('[MatrixChatService] Reinitialized with fresh store');
      } else {
        rethrow;
      }
    }
    
    if (!_loggedIn) {
      print('[MatrixChatService] Logging in as $username...');
      try {
        await login(username: username, password: password);
        print('[MatrixChatService] Login successful');
      } catch (e) {
        // Check if it's a device mismatch error during login
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('account in the store doesn\'t match') || 
            errorMsg.contains('device mismatch') ||
            errorMsg.contains('crypto store')) {
          print('[MatrixChatService] Device mismatch detected during login, clearing store and retrying...');
          try {
            // Stop sync if running to release file handles
            if (_syncStarted) {
              try {
                print('[MatrixChatService] Stopping sync to release file handles...');
                await stopSync();
                await Future.delayed(Duration(milliseconds: 500)); // Give time for handles to close
              } catch (stopError) {
                print('[MatrixChatService] Error stopping sync: $stopError');
              }
            }
            
            // Reset state BEFORE deleting to invalidate the client
            _inited = false;
            _loggedIn = false;
            _syncStarted = false;
            
            final dir = await getApplicationSupportDirectory();
            final storeDir = Directory(dir.path);
            
            // Try to delete with retries
            int retries = 3;
            bool deleted = false;
            for (int i = 0; i < retries && !deleted; i++) {
              if (i > 0) {
                print('[MatrixChatService] Retry $i after ${i * 500}ms delay...');
                await Future.delayed(Duration(milliseconds: i * 500));
              }
              
              if (await storeDir.exists()) {
                try {
                  print('[MatrixChatService] Deleting store directory: ${dir.path}');
                  await storeDir.delete(recursive: true);
                  deleted = true;
                  print('[MatrixChatService] Store deleted, reinitializing...');
                } catch (deleteError) {
                  if (i == retries - 1) {
                    rethrow; // Rethrow on last retry
                  }
                  print('[MatrixChatService] Delete attempt ${i + 1} failed: $deleteError');
                }
              } else {
                deleted = true; // Already gone
              }
            }
            
            // Reinitialize and login with fresh store
            await ensureInitialized(homeserver: homeserver);
            await login(username: username, password: password);
            print('[MatrixChatService] Login successful after store clear');
          } catch (clearError) {
            print('[MatrixChatService] Failed to recover from device mismatch: $clearError');
            final dir = await getApplicationSupportDirectory();
            
            // The store directory is locked by the Matrix client and can't be deleted while the app is running.
            // We need to close the app first, then delete the directory.
            print('');
            print('═══════════════════════════════════════════════════════════════');
            print('  MATRIX DEVICE MISMATCH - MANUAL ACTION REQUIRED');
            print('═══════════════════════════════════════════════════════════════');
            print('');
            print('The Matrix store contains data from a different device.');
            print('To fix this, please follow these steps:');
            print('');
            print('1. Close this app completely');
            print('2. Delete this folder:');
            print('   ${dir.path}');
            print('3. Restart the app');
            print('');
            print('This only needs to be done once. After clearing the store,');
            print('the app will work normally with a fresh device.');
            print('═══════════════════════════════════════════════════════════════');
            print('');
            
            throw Exception(
              'Matrix device mismatch detected. Please close the app, delete the folder '
              '"${dir.path}", and restart. See console for detailed instructions.'
            );
          }
        } else {
          rethrow;
        }
      }
    } else {
      print('[MatrixChatService] Already logged in');
    }
    
    if (!_syncStarted) {
      print('[MatrixChatService] Starting Matrix sync...');
      await startSync();
      print('[MatrixChatService] Sync started successfully');
    } else {
      print('[MatrixChatService] Sync already running');
    }
    
      _readyUserId = userId;
      print('[MatrixChatService] Matrix ready for user $userId');
      
      // Mark initialization as complete
      _initializationInProgress = null;
      completer.complete();
    } catch (e) {
      // Mark initialization as failed
      _initializationInProgress = null;
      completer.completeError(e);
      rethrow;
    }
  }
}
