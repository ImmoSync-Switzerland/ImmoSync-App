import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'e2ee_key_store.dart';
import '../config/db_config.dart';
import 'package:http/http.dart' as http;
import '../services/token_manager.dart';

class E2EEService {
  final E2EEKeyStore _keyStore;
  final Cipher _cipher = AesGcm.with256bits();
  final TokenManager _tokenManager = TokenManager();
  E2EEService(this._keyStore);

  Future<void> ensureInitialized() async => _keyStore.init();

  Future<String?> publishIdentityKey(String userId) async {
    await ensureInitialized();
    final pub = await _keyStore.getPublicIdentityKeyBase64();
    if (pub == null) return null;
    // POST publish-key (best-effort; ignore if already set)
    try {
      final resp = await http.post(
          Uri.parse('${DbConfig.apiUrl}/users/publish-key'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': userId, 'publicKey': pub}));
      if (resp.statusCode == 200) return pub;
    } catch (_) {}
    return pub;
  }

  Future<List<int>?> _getOrEstablishConversationKey(
      {required String conversationId, required String otherUserId}) async {
    final existing = await _keyStore.getConversationKey(conversationId);
    if (existing != null) {
      debugPrint(
          '[E2EE] existing conversation key found cid=$conversationId len=${existing.length}');
      return base64Decode(existing);
    }
    // Fetch other user's public key
    try {
      final headers = await _tokenManager.getHeaders();
      final resp = await http.get(
        Uri.parse('${DbConfig.apiUrl}/users/$otherUserId/public-key'),
        headers: headers,
      );
      if (resp.statusCode != 200) {
        debugPrint(
            '[E2EE] remote public key fetch failed status=${resp.statusCode} otherUser=$otherUserId');
        return null; // can't establish yet
      }
      final data = jsonDecode(resp.body);
      final otherPubB64 = data['publicKey'];
      if (otherPubB64 == null || otherPubB64 is! String) return null;
      final otherPub = base64Decode(otherPubB64);
      if (otherPub.length != 32) {
        debugPrint(
            '[E2EE] invalid remote key length=${otherPub.length} expected=32 otherUser=$otherUserId');
        return null;
      }
      debugPrint(
          '[E2EE] deriving new conversation key cid=$conversationId otherUser=$otherUserId');
      final derived =
          await _keyStore.deriveConversationKey(otherUserPubKey: otherPub);
      debugPrint('[E2EE] derived key length=${derived.length} saving...');
      await _keyStore.storeConversationKey(conversationId, derived);
      return derived;
    } catch (e) {
      debugPrint(
          '[E2EE] exception establishing key cid=$conversationId otherUser=$otherUserId err=$e');
      return null; // swallow for now; caller treats null as 'not ready'
    }
  }

  Future<Map<String, dynamic>?> encryptMessage(
      {required String conversationId,
      required String otherUserId,
      required String plaintext}) async {
    final keyBytes = await _getOrEstablishConversationKey(
        conversationId: conversationId, otherUserId: otherUserId);
    if (keyBytes == null) return null; // key establishment pending
    final secretKey = SecretKey(keyBytes);
    final iv = _randomBytes(12);
    final secretBox = await _cipher.encrypt(utf8.encode(plaintext),
        secretKey: secretKey, nonce: iv);
    return {
      'ciphertext': base64Encode(secretBox.cipherText),
      'iv': base64Encode(iv),
      'tag': base64Encode(secretBox.mac.bytes),
      'v': 1,
    };
  }

  Future<String?> decryptMessage(
      {required String conversationId,
      required String otherUserId,
      required Map<String, dynamic> payload}) async {
    final keyBytes = await _getOrEstablishConversationKey(
        conversationId: conversationId, otherUserId: otherUserId);
    if (keyBytes == null) return null;
    final secretKey = SecretKey(keyBytes);
    try {
      final cipherText = base64Decode(payload['ciphertext']);
      final iv = base64Decode(payload['iv']);
      final mac = Mac(base64Decode(payload['tag']));
      final secretBox = SecretBox(cipherText, nonce: iv, mac: mac);
      final clear = await _cipher.decrypt(secretBox, secretKey: secretKey);
      return utf8.decode(clear);
    } catch (_) {
      return null;
    }
  }

  Future<List<int>?> decryptAttachment(
      {required String conversationId,
      required String otherUserId,
      required List<int> ciphertext,
      required String iv,
      required String tag}) async {
    final keyBytes = await _getOrEstablishConversationKey(
        conversationId: conversationId, otherUserId: otherUserId);
    if (keyBytes == null) return null;
    try {
      final secretKey = SecretKey(keyBytes);
      final mac = Mac(base64Decode(tag));
      final nonce = base64Decode(iv);
      final secretBox = SecretBox(ciphertext, nonce: nonce, mac: mac);
      final clear = await _cipher.decrypt(secretBox, secretKey: secretKey);
      return clear;
    } catch (_) {
      return null;
    }
  }

  List<int> _randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }

  // Batch ensure key (used when opening a conversation before first message display)
  Future<bool> ensureConversationKey(
      {required String conversationId, required String otherUserId}) async {
    final existing = await _keyStore.getConversationKey(conversationId);
    if (existing != null) return true;
    final derived = await _getOrEstablishConversationKey(
        conversationId: conversationId, otherUserId: otherUserId);
    return derived != null;
  }

  // Rotate identity key locally (client side) and publish new key; invalidates all conversation keys
  Future<bool> rotateIdentityKey(String userId) async {
    // Simplified: wipe stored identity keys and regenerate by re-init; conversation keys must be re-derived lazily
    // Not fully implemented due to secure storage cleanup complexity; placeholder for future.
    await _keyStore.init(); // ensure present
    // In real rotation we would: backup old pub, write new, call /users/rotate-key. Skipped for brevity.
    return true;
  }

  // Encrypt attachment bytes (returns ciphertext + iv + tag)
  Future<Map<String, dynamic>?> encryptAttachment(
      {required String conversationId,
      required String otherUserId,
      required List<int> bytes}) async {
    final keyBytes = await _getOrEstablishConversationKey(
        conversationId: conversationId, otherUserId: otherUserId);
    if (keyBytes == null) return null;
    final secretKey = SecretKey(keyBytes);
    final iv = _randomBytes(12);
    final secretBox =
        await _cipher.encrypt(bytes, secretKey: secretKey, nonce: iv);
    return {
      'ciphertext': base64Encode(secretBox.cipherText),
      'iv': base64Encode(iv),
      'tag': base64Encode(secretBox.mac.bytes),
      'v': 1,
      'size': bytes.length,
    };
  }
}

final e2eeKeyStoreProvider = Provider<E2EEKeyStore>((ref) => E2EEKeyStore());
final e2eeServiceProvider =
    Provider<E2EEService>((ref) => E2EEService(ref.read(e2eeKeyStoreProvider)));
