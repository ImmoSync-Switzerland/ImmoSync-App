import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/db_config.dart';
import '../crypto/e2ee_service.dart';

// Global ref holder for components needing access outside widget tree (e.g., history decryption)
class PresenceWsServiceRefHolder {
  static Ref? ref;
  static void bind(Ref r) {
    ref = r;
  }
}

class PresenceUpdate {
  final String userId;
  final bool online;
  final DateTime lastSeen;
  PresenceUpdate(
      {required this.userId, required this.online, required this.lastSeen});
}

class PresenceWsService {
  // Toggle to fully disable legacy WebSocket layer (Matrix-only mode)
  static const bool _disabled = true;
  IO.Socket? _presenceSocket;
  IO.Socket? _chatSocket;
  final _controller = StreamController<PresenceUpdate>.broadcast();
  final _chatController = StreamController<Map<String, dynamic>>.broadcast();
  final _conversationController =
      StreamController<Map<String, dynamic>>.broadcast();
  List<Map<String, dynamic>> _pendingMessages = [];
  // Track inflight emits to allow lightweight retries if no ack is observed
  final Map<String, Map<String, dynamic>> _inflightByClientId = {};
  // Pending read receipts keyed by conversationId (values are messageId sets)
  final Map<String, Set<String>> _pendingReads = {};
  Timer? _pingTimer;
  String? _userId;
  String? _token;

  Stream<PresenceUpdate> get stream => _controller.stream;
  Stream<Map<String, dynamic>> get chatStream => _chatController.stream;
  Stream<Map<String, dynamic>> get conversationStream =>
      _conversationController.stream;

  Future<void> connect({required String userId, required String token}) async {
    if (_disabled) {
      // Matrix-only mode: no WS connections
      return;
    }
    // If sockets already exist, only keep them if identity (userId/token) matches.
    if (_presenceSocket != null) {
      final sameIdentity = (_userId == userId) && (_token == token);
      if (sameIdentity) {
        // Already connected with correct identity. If any reads were queued while temporarily disconnected,
        // flush them now instead of waiting for a reconnect event.
        if (_chatSocket?.connected == true && _pendingReads.isNotEmpty) {
          final entries = Map<String, Set<String>>.from(_pendingReads);
          _pendingReads.clear();
          entries.forEach((convId, ids) {
            if (ids.isNotEmpty) {
              try {
                _chatSocket!.emit('chat:read', {
                  'conversationId': convId,
                  'messageIds': ids.toList(),
                });
                // ignore: avoid_print
                print(
                    '[WS][chat] flushed pending reads (immediate) conv=$convId count=${ids.length}');
              } catch (_) {}
            }
          });
        }
        return; // already connected with correct identity
      }
      // Identity changed (e.g., switched user). Tear down old sockets and state.
      _teardownSockets();
    }
    _userId = userId;
    _token = token;
    var base = DbConfig.wsUrl; // e.g. wss://host or wss://host/
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    print('[WS][connect] attempting user=$userId base=$base');
    final opt = IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setAuth({'token': token})
        .build();
    _presenceSocket = IO.io('$base/presence', opt);
    _chatSocket = IO.io('$base/chat', opt);

    _presenceSocket!
      ..onConnect((_) {
        print('[WS][presence] connected id=${_presenceSocket?.id}');
        _pingTimer =
            Timer.periodic(const Duration(seconds: 25), (_) => _ping());
      })
      ..on('connect_error', (err) {
        print('[WS][presence][connect_error] $err');
      })
      ..on('reconnect_attempt', (attempt) {
        print('[WS][presence][reconnect_attempt] $attempt');
      })
      ..on('reconnecting', (attempt) {
        print('[WS][presence][reconnecting] $attempt');
      })
      ..on('reconnect_failed', (_) {
        print('[WS][presence][reconnect_failed]');
      })
      ..on('presence:update', (data) {
        if (data is Map) {
          _controller.add(PresenceUpdate(
            userId: data['userId']?.toString() ?? '',
            online: data['online'] == true,
            lastSeen: DateTime.tryParse(data['lastSeen']?.toString() ?? '') ??
                DateTime.now(),
          ));
        }
      })
      ..onDisconnect((_) => _scheduleReconnect())
      ..onError((err) {
        print('[WS][presence] error $err');
        _scheduleReconnect();
      });

    _chatSocket!
      ..onConnect((_) {
        print(
            '[WS][chat] connected id=${_chatSocket?.id} pending=${_pendingMessages.length}');
        // Replay any queued conversation create or message events
        final queuedCreates =
            _pendingMessages.where((m) => m['__create'] == true).toList();
        final queuedMessages =
            _pendingMessages.where((m) => m['__create'] != true).toList();
        for (final c in queuedCreates) {
          _chatSocket!.emit('chat:create', {
            'otherUserId': c['otherUserId'],
            if (c['initialMessage'] != null)
              'initialMessage': c['initialMessage']
          });
        }
        for (final m in queuedMessages) {
          _chatSocket!.emit('chat:message', m);
        }
        _pendingMessages.clear();
        // Flush any pending read receipts accumulated while disconnected
        if (_pendingReads.isNotEmpty) {
          final entries = Map<String, Set<String>>.from(_pendingReads);
          _pendingReads.clear();
          entries.forEach((convId, ids) {
            if (ids.isNotEmpty) {
              _chatSocket!.emit('chat:read', {
                'conversationId': convId,
                'messageIds': ids.toList(),
              });
              // ignore: avoid_print
              print(
                  '[WS][chat] flushed pending read receipts for conv=$convId count=${ids.length}');
            }
          });
          // ignore: avoid_print
          print('[WS][chat] flushed for ${entries.length} conversation(s)');
        }
        print('[WS][chat] replay complete');
      })
      ..on('connect_error', (err) {
        print('[WS][chat][connect_error] $err');
      })
      ..on('reconnect_attempt', (attempt) {
        print('[WS][chat][reconnect_attempt] $attempt');
      })
      ..on('reconnecting', (attempt) {
        print('[WS][chat][reconnecting] $attempt');
      })
      ..on('reconnect_failed', (_) {
        print('[WS][chat][reconnect_failed]');
      })
      ..on('chat:message', (data) async {
        if (data is Map) {
          // ignore: avoid_print
          print('[WS][recv][message] keys=${data.keys.toList()}');
          await _maybeDecryptAndForward(data, isAck: false);
        }
      })
      ..on('chat:ack', (data) async {
        if (data is Map) {
          // ignore: avoid_print
          print('[WS][recv][ack] keys=${data.keys.toList()}');
          final cId = data['clientMessageId']?.toString();
          if (cId != null) {
            _inflightByClientId.remove(cId);
          }
          await _maybeDecryptAndForward(data, isAck: true);
        }
      })
      ..on('chat:conversation:new', (data) {
        if (data is Map)
          _conversationController.add({...data, 'type': 'newConversation'});
      })
      ..on('chat:create:ack', (data) {
        if (data is Map)
          _conversationController.add({...data, 'type': 'createAck'});
      })
      ..on('chat:typing', (data) {
        if (data is Map) _chatController.add({...data, 'type': 'typing'});
      })
      ..on('chat:read', (data) {
        if (data is Map) _chatController.add({...data, 'type': 'read'});
      })
      ..on('chat:delivered', (data) {
        if (data is Map) _chatController.add({...data, 'type': 'delivered'});
      })
      ..onDisconnect((_) => _scheduleReconnect())
      ..onError((err) {
        print('[WS][chat] error $err');
        _scheduleReconnect();
      });

    _presenceSocket!.connect();
    _chatSocket!.connect();
  }

  void _ping() {
    if (_userId == null) return;
    _presenceSocket?.emit('presence:ping');
  }

  void _scheduleReconnect() {
    _pingTimer?.cancel();
    final uid = _userId;
    final tkn = _token;
    if (uid == null || tkn == null) return;
    Future.delayed(const Duration(seconds: 3), () {
      // Identity may have changed in the meantime; re-check
      if (_userId == null || _token == null) return;
      final needs = _presenceSocket == null || _presenceSocket!.disconnected;
      if (needs) {
        try {
          _presenceSocket?.dispose();
          _chatSocket?.dispose();
        } catch (_) {}
        _presenceSocket = null;
        _chatSocket = null;
        connect(userId: _userId!, token: _token!);
        // Pending events (messages + reads) will flush on connect
      }
    });
  }

  Future<void> dispose() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    try {
      _presenceSocket?.dispose();
      _chatSocket?.dispose();
    } catch (_) {}
    _presenceSocket = null;
    _chatSocket = null;
    await _controller.close();
    await _chatController.close();
    await _conversationController.close();
  }

  // Public reset for auth/logout: disconnect sockets and clear identity.
  void resetConnections() {
    _teardownSockets();
    _userId = null;
    _token = null;
  }

  // Internal helper to drop sockets, timers, and pending queue without closing streams.
  void _teardownSockets() {
    _pingTimer?.cancel();
    _pingTimer = null;
    try {
      _presenceSocket?.dispose();
      _chatSocket?.dispose();
    } catch (_) {}
    _presenceSocket = null;
    _chatSocket = null;
    _pendingMessages.clear();
    // Clear any read receipts queued under the old identity to avoid cross-account leakage
    _pendingReads.clear();
  }

  // Decrypt if e2ee bundle exists. Since this service lacks direct Ref here, we expose
  // an injection point: caller must set a static ref provider before messages start.
  static Ref? _ref;
  static void bindRef(Ref ref) {
    _ref = ref;
  }

  Future<void> _maybeDecryptAndForward(Map data, {required bool isAck}) async {
    try {
      if (data['e2ee'] != null &&
          data['conversationId'] != null &&
          _ref != null) {
        final e2ee = _ref!.read(e2eeServiceProvider);
        final otherUserId = (data['senderId']?.toString() ?? '') == _userId
            ? (data['receiverId']?.toString() ?? '')
            : (data['senderId']?.toString() ?? '');
        if (otherUserId.isNotEmpty) {
          final clear = await e2ee.decryptMessage(
            conversationId: data['conversationId'].toString(),
            otherUserId: otherUserId,
            payload: Map<String, dynamic>.from(data['e2ee']),
          );
          if (clear != null) {
            data['content'] = clear;
            // Provide a decryptedPreview for conversation list updates (UI can prefer this)
            data['decryptedPreview'] = clear;
            if (data['receiverId'] != null &&
                data['receiverId'] == data['senderId']) {
              print(
                  '[WS][decrypt][anomaly] decrypted message with receiver==sender id=${data['_id'] ?? 'n/a'} sender=${data['senderId']}');
            }
          } else {
            data['content'] = '[encrypted]';
          }
        }
      }
    } catch (_) {
      data['content'] = data['content'] ?? '[decrypt-failed]';
    }
    _chatController.add({...data, 'type': isAck ? 'ack' : 'message'});
  }

  Future<bool> sendChatMessage(
      {required String conversationId,
      required String content,
      String? receiverId,
      WidgetRef? ref}) async {
    Map<String, dynamic> payload = {
      'conversationId': conversationId,
      if (_userId != null)
        'senderId': _userId, // explicit sender id for server attribution
      'clientTime': DateTime.now().toIso8601String(),
      'messageType': 'text',
      // lightweight client-generated id for local correlation (optional for server)
      'clientMessageId':
          '${DateTime.now().millisecondsSinceEpoch}-${(_userId ?? 'u')}',
    };
    if (receiverId != null) payload['receiverId'] = receiverId;
    bool encryptionUsed = false;
    print(
        '[WS][sendChatMessage] conv=$conversationId recv=$receiverId connected=${_chatSocket?.connected}');
    if (receiverId != null && _userId != null && receiverId == _userId) {
      print(
          '[WS][sendChatMessage][warn] receiverId equals senderId ($_userId) – this should not happen for 1:1 chat');
    }
    // Try encrypt
    try {
      final effectiveRef = ref ?? _ref; // allow omission where static ref bound
      final e2ee = (effectiveRef is WidgetRef)
          ? effectiveRef.read(e2eeServiceProvider)
          : (_ref?.read(e2eeServiceProvider));
      final other = receiverId; // if null (group) skip E2EE
      if (other != null && e2ee != null) {
        final enc = await e2ee.encryptMessage(
            conversationId: conversationId,
            otherUserId: other,
            plaintext: content);
        if (enc != null) {
          payload['e2ee'] = enc; // place encrypted bundle
          encryptionUsed = true;
        } else {
          payload['content'] = content; // fallback plaintext
        }
      } else {
        payload['content'] = content;
      }
    } catch (_) {
      payload['content'] = content; // fallback
    }
    if (_chatSocket == null || _chatSocket!.disconnected) {
      _pendingMessages.add(payload);
      print(
          '[WS][sendChatMessage] queued (socket disconnected) pending=${_pendingMessages.length}');
      return encryptionUsed;
    }
    _chatSocket!.emit('chat:message', payload);
    print(
        '[WS][sendChatMessage] emitted payload keys=${payload.keys.toList()}');
    final cId = payload['clientMessageId']?.toString();
    if (cId != null) {
      _inflightByClientId[cId] = payload;
      // Simple retry after 3 seconds if still inflight and connected
      Future.delayed(const Duration(seconds: 3), () {
        final still = _inflightByClientId[cId];
        if (still != null && _chatSocket?.connected == true) {
          try {
            // ignore: avoid_print
            print('[WS][sendChatMessage][retry] clientMessageId=$cId');
            _chatSocket!.emit('chat:message', still);
          } catch (_) {}
        }
      });
    }

    // Do not mirror plaintext to REST; rely on Matrix E2EE for content.
    return encryptionUsed;
  }

  void flushPending() {
    if (_chatSocket == null || _chatSocket!.disconnected) return;
    for (final m in _pendingMessages) {
      _chatSocket!.emit('chat:message', m);
    }
    _pendingMessages.clear();
  }

  // DEBUG helper to print current socket state & send a no-op test message
  void debugStatus() {
    print(
        '[WS][debug] presence connected=${_presenceSocket?.connected} chat connected=${_chatSocket?.connected} pending=${_pendingMessages.length}');
    if (_chatSocket?.connected == true) {
      _chatSocket!
          .emit('chat:typing', {'conversationId': 'debug', 'isTyping': false});
      print('[WS][debug] emitted dummy typing event');
    }
  }

  void createConversation(
      {required String otherUserId, String? initialMessage}) {
    if (_chatSocket == null || _chatSocket!.disconnected) {
      // Queue as special pending create
      _pendingMessages.add({
        '__create': true,
        'otherUserId': otherUserId,
        'initialMessage': initialMessage
      });
      return;
    }
    // Try encrypt initial message if provided
    if (initialMessage != null) {
      if (_ref != null) {
        final e2ee = _ref!.read(e2eeServiceProvider);
        e2ee
            .encryptMessage(
                conversationId: 'temp-$otherUserId',
                otherUserId: otherUserId,
                plaintext: initialMessage)
            .then((enc) {
          if (enc != null) {
            _chatSocket!.emit('chat:create', {
              'otherUserId': otherUserId,
              'initialE2EE': enc,
            });
          } else {
            _chatSocket!.emit('chat:create', {
              'otherUserId': otherUserId,
              'initialMessage': initialMessage,
            });
          }
        });
      } else {
        _chatSocket!.emit('chat:create', {
          'otherUserId': otherUserId,
          'initialMessage': initialMessage,
        });
      }
    } else {
      _chatSocket!.emit('chat:create', {'otherUserId': otherUserId});
    }
  }

  void sendTyping({required String conversationId, required bool isTyping}) {
    if (_chatSocket == null || _chatSocket!.disconnected) return;
    _chatSocket!.emit('chat:typing',
        {'conversationId': conversationId, 'isTyping': isTyping});
  }

  void markMessagesRead(
      {required String conversationId, required List<String> messageIds}) {
    if (_chatSocket == null || _chatSocket!.disconnected) {
      // Accumulate to flush on next connect
      final set = _pendingReads.putIfAbsent(conversationId, () => <String>{});
      set.addAll(messageIds);
      // ignore: avoid_print
      print(
          '[WS][chat] queue read conv=$conversationId count=${messageIds.length} (socket disconnected)');
      return;
    }
    _chatSocket!.emit('chat:read', {
      'conversationId': conversationId,
      'messageIds': messageIds,
    });
    // ignore: avoid_print
    print(
        '[WS][chat] emit read conv=$conversationId count=${messageIds.length}');
  }

  void markAllRead(
      {required String conversationId, required List<String> messageIds}) {
    if (messageIds.isEmpty) return;
    markMessagesRead(conversationId: conversationId, messageIds: messageIds);
  }
}

final presenceWsServiceProvider = Provider<PresenceWsService>((ref) {
  final service = PresenceWsService();
  // Bind ref for decryption callbacks
  PresenceWsService.bindRef(ref);
  PresenceWsServiceRefHolder.bind(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
