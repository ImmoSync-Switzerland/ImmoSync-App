import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:immosync/bridge.dart' as frb;
import 'package:immosync/core/config/db_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'mobile_matrix_client.dart';
// Timeline ingestion is handled by MatrixFrbEventsAdapter; avoid duplicating here.

class MatrixChatService {
  static final MatrixChatService instance = MatrixChatService._();
  MatrixChatService._();

  bool _inited = false;
  String? _readyUserId;
  bool _loggedIn = false;
  bool _syncStarted = false;
  Future<void>? _initializationInProgress;
  StreamSubscription<frb.MatrixEvent>? _eventSub;
  Completer<void>? _firstEventCompleter;

  /// Check if the current platform supports the Matrix Rust bridge
  bool get _isRustBridgeSupported {
    return defaultTargetPlatform == TargetPlatform.windows || 
           defaultTargetPlatform == TargetPlatform.linux ||
           defaultTargetPlatform == TargetPlatform.macOS;
  }

  /// Get the appropriate Matrix client for the current platform
  MobileMatrixClient? get _mobileClient => _isRustBridgeSupported ? null : MobileMatrixClient.instance;

  Future<void> ensureInitialized({required String homeserver}) async {
    if (_inited) return;
    
    // Check for delete marker from previous device mismatch
    final dir = await getApplicationSupportDirectory();
    final markerFile = File('${dir.path}_delete_marker');
    
    if (await markerFile.exists()) {
      print('[MatrixChatService] Found delete marker, clearing old Matrix store...');
      try {
        final storeDir = Directory(dir.path);
        if (await storeDir.exists()) {
          await storeDir.delete(recursive: true);
          print('[MatrixChatService] Old Matrix store deleted successfully');
        }
        await markerFile.delete();
        print('[MatrixChatService] Delete marker removed');
      } catch (deleteError) {
        print('[MatrixChatService] Warning: Failed to delete old store: $deleteError');
        // Continue anyway - init will create fresh store
      }
    }
    
    if (_isRustBridgeSupported) {
      // Use Rust bridge on desktop platforms
      try {
        await frb.init(homeserver: homeserver, dataDir: dir.path);
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('already initialized') || msg.contains('client already initialized')) {
          // Idempotent init: another call already created the client. Treat as success.
          print('[MatrixChatService] init skipped (already initialized)');
        } else {
          rethrow;
        }
      }
    } else {
      // Use mobile client on mobile platforms
      print('[MatrixChatService] Using mobile Matrix client for ${defaultTargetPlatform.name}');
      await _mobileClient!.init(homeserver, dir.path);
    }
    
    _inited = true;
  }

  Future<void> login(
      {required String username, required String password}) async {
    if (_isRustBridgeSupported) {
      await frb.login(user: username, password: password);
    } else {
      final result = await _mobileClient!.login(username, password);
      print('[MatrixChatService] Mobile login successful: ${result['userId']}');
    }
    _loggedIn = true;
  }

  Future<String> sendMessage(
      {required String roomId, required String body}) async {
    if (_isRustBridgeSupported) {
      return frb.sendMessage(roomId: roomId, body: body);
    } else {
      return _mobileClient!.sendMessage(roomId, body);
    }
  }

  Future<void> startSync() async {
    if (_syncStarted) return;
    
    if (_isRustBridgeSupported) {
      try {
        await frb.startSync();
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('already running') || msg.contains('already started')) {
          print('[MatrixChatService] startSync skipped (already running)');
        } else {
          rethrow;
        }
      }
    } else {
      // Mobile client handles sync automatically after login
      print('[MatrixChatService] Mobile client sync is automatic');
    }
    _syncStarted = true;
  }

  void _ensureEventSubscription() {
    if (_eventSub != null) return;
    _firstEventCompleter ??= Completer<void>();
    try {
      _eventSub = frb.subscribeEvents().listen((event) {
        // Signal that at least one sync event has been received
        if (!(_firstEventCompleter?.isCompleted ?? true)) {
          _firstEventCompleter?.complete();
        }
        // Do not ingest events here to avoid duplicate ingestion and race conditions.
      }, onError: (e) {
        // Keep subscription alive despite errors
      });
    } catch (_) {
      // If subscription fails, leave completer as is; callers will timeout
    }
  }

  Future<void> waitForFirstSyncEvent({Duration timeout = const Duration(seconds: 5)}) async {
    _ensureEventSubscription();
    try {
      if (!(_firstEventCompleter?.isCompleted ?? true)) {
        await _firstEventCompleter!.future.timeout(timeout);
      }
    } catch (_) {
      // Timeout is acceptable; we proceed best-effort
    }
  }

  Future<void> stopSync() async {
    if (_isRustBridgeSupported) {
      await frb.stopSync();
    } else {
      // Mobile client doesn't need explicit sync stop
      print('[MatrixChatService] Mobile client sync management is automatic');
    }
    _syncStarted = false;
  }

  Future<void> markRead({required String roomId, required String eventId}) {
    if (_isRustBridgeSupported) {
      return frb.markRead(roomId: roomId, eventId: eventId);
    } else {
      return _mobileClient!.markRead(roomId, eventId);
    }
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
      if (r.statusCode == 503) {
        // Matrix service not configured on backend
        print('[MatrixChatService] Matrix service not configured on backend (503)');
        return {'configured': false};
      }
      if (r.statusCode != 200) return null;
      return json.decode(r.body) as Map<String, dynamic>;
    }

    var data = await fetchAccount();
    
    // Check if Matrix is configured on backend
    if (data != null && data['configured'] == false) {
      print('[MatrixChatService] WARNING: Matrix service not configured on backend');
      print('[MatrixChatService] Chat will use HTTP-only mode (no real-time updates)');
      _readyUserId = userId;
      _initializationInProgress = null;
      completer.complete();
      return; // Skip Matrix initialization
    }
    
    if (data == null) {
      // Attempt to provision the account, then fetch again
      print('[MatrixChatService] Account not found, attempting to provision...');
      try {
        final provisionResp = await http.post(Uri.parse('$api/matrix/provision'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'userId': userId}));
        
        if (provisionResp.statusCode == 503 || provisionResp.statusCode == 500) {
          print('[MatrixChatService] WARNING: Matrix provisioning failed (server not configured)');
          print('[MatrixChatService] Chat will use HTTP-only mode');
          _readyUserId = userId;
          _initializationInProgress = null;
          completer.complete();
          return; // Skip Matrix initialization
        }
      } catch (provisionError) {
        print('[MatrixChatService] Provision error: $provisionError');
      }
      
      data = await fetchAccount();
    }
    
    if (data == null) {
      print('[MatrixChatService] WARNING: Matrix account not available, using HTTP-only mode');
      _readyUserId = userId;
      _initializationInProgress = null;
      completer.complete();
      return; // Skip Matrix initialization
    }

    final homeserver = (data['homeserver'] as String?) ?? (data['baseUrl'] as String?) ?? '';
    final username = data['username'] as String?;
    final password = data['password'] as String?;
    print('[MatrixChatService] Credentials: homeserver=$homeserver, username=$username');
    print('[MatrixChatService] Password length: ${password?.length ?? 0} chars');
    print('[MatrixChatService] Password (first 8 chars): ${password?.substring(0, password.length > 8 ? 8 : password.length) ?? 'MISSING'}...');
    
    if (homeserver.isEmpty || username == null || password == null) {
      print('[MatrixChatService] WARNING: Incomplete credentials, using HTTP-only mode');
      _readyUserId = userId;
      _initializationInProgress = null;
      completer.complete();
      return; // Skip Matrix initialization
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
            
            // The store directory is locked by the Matrix client - force app restart
            print('[MatrixChatService] Store is locked, scheduling auto-restart...');
            print('[MatrixChatService] Store location: ${dir.path}');
            
            // Create a marker file so we know to delete the store on next startup
            final markerFile = File('${dir.path}_delete_marker');
            try {
              await markerFile.writeAsString('delete_on_restart');
              print('[MatrixChatService] Created delete marker file');
            } catch (markerError) {
              print('[MatrixChatService] Failed to create marker: $markerError');
            }
            
            // Schedule app restart (platform-specific)
            print('[MatrixChatService] Requesting app restart to clear Matrix store...');
            
            // Give user a brief notification before restart
            throw Exception(
              'Matrix device mismatch detected. App will restart automatically to clear store...'
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

    // Ensure we subscribed to events and wait for first sync tick to reduce crypto races
    _ensureEventSubscription();
    await waitForFirstSyncEvent(timeout: const Duration(seconds: 5));
    
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
