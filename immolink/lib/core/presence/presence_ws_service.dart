import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/db_config.dart';
import '../crypto/e2ee_service.dart';


class PresenceUpdate {
  final String userId;
  final bool online;
  final DateTime lastSeen;
  PresenceUpdate({required this.userId, required this.online, required this.lastSeen});
}

class PresenceWsService {
  IO.Socket? _presenceSocket;
  IO.Socket? _chatSocket;
  final _controller = StreamController<PresenceUpdate>.broadcast();
  final _chatController = StreamController<Map<String, dynamic>>.broadcast();
  final _conversationController = StreamController<Map<String, dynamic>>.broadcast();
  List<Map<String, dynamic>> _pendingMessages = [];
  Timer? _pingTimer;
  String? _userId;
  String? _token;

  Stream<PresenceUpdate> get stream => _controller.stream;
  Stream<Map<String, dynamic>> get chatStream => _chatController.stream;
  Stream<Map<String, dynamic>> get conversationStream => _conversationController.stream;

  Future<void> connect({required String userId, required String token}) async {
    if (_presenceSocket != null) return;
    _userId = userId;
    _token = token;
    final base = DbConfig.wsUrl; // e.g. wss://host
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
        _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) => _ping());
      })
  ..on('connect_error', (err) { print('[WS][presence][connect_error] $err'); })
      ..on('presence:update', (data) {
        if (data is Map) {
          _controller.add(PresenceUpdate(
            userId: data['userId']?.toString() ?? '',
            online: data['online'] == true,
            lastSeen: DateTime.tryParse(data['lastSeen']?.toString() ?? '') ?? DateTime.now(),
          ));
        }
      })
      ..onDisconnect((_) => _scheduleReconnect())
      ..onError((err) { print('[WS][presence] error $err'); _scheduleReconnect(); });

    _chatSocket!
      ..onConnect((_) {
        print('[WS][chat] connected id=${_chatSocket?.id} pending=${_pendingMessages.length}');
        // Replay any queued conversation create or message events
        final queuedCreates = _pendingMessages.where((m) => m['__create'] == true).toList();
        final queuedMessages = _pendingMessages.where((m) => m['__create'] != true).toList();
        for (final c in queuedCreates) {
          _chatSocket!.emit('chat:create', {
            'otherUserId': c['otherUserId'],
            if (c['initialMessage'] != null) 'initialMessage': c['initialMessage']
          });
        }
        for (final m in queuedMessages) {
          _chatSocket!.emit('chat:message', m);
        }
        _pendingMessages.clear();
        print('[WS][chat] replay complete');
      })
  ..on('connect_error', (err) { print('[WS][chat][connect_error] $err'); })
      ..on('chat:message', (data) async {
        if (data is Map) {
          await _maybeDecryptAndForward(data, isAck: false);
        }
      })
      ..on('chat:ack', (data) async {
        if (data is Map) {
          await _maybeDecryptAndForward(data, isAck: true);
        }
      })
      ..on('chat:conversation:new', (data) {
        if (data is Map) _conversationController.add({...data, 'type': 'newConversation'});
      })
      ..on('chat:create:ack', (data) {
        if (data is Map) _conversationController.add({...data, 'type': 'createAck'});
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
  ..onError((err) { print('[WS][chat] error $err'); _scheduleReconnect(); });

    _presenceSocket!.connect();
    _chatSocket!.connect();
  }


  void _ping() {
    if (_userId == null) return;
  _presenceSocket?.emit('presence:ping');
  }

  void _scheduleReconnect() {
    _pingTimer?.cancel();
    if (_userId == null || _token == null) return;
    Future.delayed(const Duration(seconds: 3), () {
      final needs = _presenceSocket == null || _presenceSocket!.disconnected;
      if (needs) {
        try { _presenceSocket?.dispose(); _chatSocket?.dispose(); } catch (_) {}
        _presenceSocket = null; _chatSocket = null;
        connect(userId: _userId!, token: _token!);
  // Pending messages will flush on successful connect
      }
    });
  }

  Future<void> dispose() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    try { _presenceSocket?.dispose(); _chatSocket?.dispose(); } catch (_) {}
    _presenceSocket = null; _chatSocket = null;
  await _controller.close();
  await _chatController.close();
  await _conversationController.close();
  }

  // Decrypt if e2ee bundle exists. Since this service lacks direct Ref here, we expose
  // an injection point: caller must set a static ref provider before messages start.
  static Ref? _ref;
  static void bindRef(Ref ref) { _ref = ref; }

  Future<void> _maybeDecryptAndForward(Map data, {required bool isAck}) async {
    try {
      if (data['e2ee'] != null && data['conversationId'] != null && _ref != null) {
        final e2ee = _ref!.read(e2eeServiceProvider);
        final otherUserId = (data['senderId']?.toString() ?? '') == _userId
            ? (data['receiverId']?.toString() ?? '')
            : (data['senderId']?.toString() ?? '');
        if (otherUserId.isNotEmpty) {
          final clear = await e2ee.decryptMessage(
            conversationId: data['conversationId'].toString(),
            otherUserId: otherUserId,
            payload: Map<String,dynamic>.from(data['e2ee']),
          );
          if (clear != null) {
            data['content'] = clear;
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

  Future<void> sendChatMessage({required String conversationId, required String content, String? receiverId, WidgetRef? ref}) async {
    Map<String,dynamic> payload = {'conversationId': conversationId};
    if (receiverId != null) payload['receiverId'] = receiverId;
  print('[WS][sendChatMessage] conv=$conversationId recv=$receiverId connected=${_chatSocket?.connected}');
    // Try encrypt
    try {
  final effectiveRef = ref ?? _ref; // allow omission where static ref bound
    final e2ee = (effectiveRef is WidgetRef)
      ? effectiveRef.read(e2eeServiceProvider)
      : (_ref?.read(e2eeServiceProvider));
      final other = receiverId; // if null (group) skip E2EE
      if (other != null && e2ee != null) {
        final enc = await e2ee.encryptMessage(conversationId: conversationId, otherUserId: other, plaintext: content);
        if (enc != null) {
          payload['e2ee'] = enc; // place encrypted bundle
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
      print('[WS][sendChatMessage] queued (socket disconnected) pending=${_pendingMessages.length}');
      return;
    }
    _chatSocket!.emit('chat:message', payload);
    print('[WS][sendChatMessage] emitted payload keys=${payload.keys.toList()}');
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
    print('[WS][debug] presence connected=${_presenceSocket?.connected} chat connected=${_chatSocket?.connected} pending=${_pendingMessages.length}');
    if (_chatSocket?.connected == true) {
      _chatSocket!.emit('chat:typing', { 'conversationId': 'debug', 'isTyping': false });
      print('[WS][debug] emitted dummy typing event');
    }
  }

  void createConversation({required String otherUserId, String? initialMessage}) {
    if (_chatSocket == null || _chatSocket!.disconnected) {
      // Queue as special pending create
      _pendingMessages.add({'__create': true, 'otherUserId': otherUserId, 'initialMessage': initialMessage});
      return;
    }
    // Try encrypt initial message if provided
    if (initialMessage != null) {
      if (_ref != null) {
        final e2ee = _ref!.read(e2eeServiceProvider);
        e2ee.encryptMessage(conversationId: 'temp-$otherUserId', otherUserId: otherUserId, plaintext: initialMessage)
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
    _chatSocket!.emit('chat:typing', { 'conversationId': conversationId, 'isTyping': isTyping });
  }

  void markMessagesRead({required String conversationId, required List<String> messageIds}) {
    if (_chatSocket == null || _chatSocket!.disconnected) return;
    _chatSocket!.emit('chat:read', { 'conversationId': conversationId, 'messageIds': messageIds });
  }

  void markAllRead({required String conversationId, required List<String> messageIds}) {
    if (messageIds.isEmpty) return;
    markMessagesRead(conversationId: conversationId, messageIds: messageIds);
  }
}

final presenceWsServiceProvider = Provider<PresenceWsService>((ref) {
  final service = PresenceWsService();
  // Bind ref for decryption callbacks
  PresenceWsService.bindRef(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
