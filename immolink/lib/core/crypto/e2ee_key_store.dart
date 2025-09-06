import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart';

/// Stores identity key pair and per-conversation symmetric keys.
class E2EEKeyStore {
  static const _identityPrivKeyKey = 'e2ee.identity.private';
  static const _identityPubKeyKey = 'e2ee.identity.public';
  static const _conversationKeyPrefix =
      'e2ee.conversation.'; // + conversationId
  final FlutterSecureStorage _storage;
  SimpleKeyPair? _identityKeyPair;
  SimplePublicKey? _identityPublicKey;

  E2EEKeyStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> init() async {
    final pub = await _storage.read(key: _identityPubKeyKey);
    final priv = await _storage.read(key: _identityPrivKeyKey);
    if (pub != null && priv != null) {
      final pubBytes = base64Decode(pub);
      final privBytes = base64Decode(priv);
      _identityPublicKey = SimplePublicKey(pubBytes, type: KeyPairType.x25519);
      // Reconstruct key pair from raw private key + public key bytes
      _identityKeyPair = SimpleKeyPairData(
        privBytes,
        publicKey: _identityPublicKey!,
        type: KeyPairType.x25519,
      );
    } else {
      await _generateIdentityKeyPair();
    }
  }

  Future<void> _generateIdentityKeyPair() async {
    final alg = X25519();
    final kp = await alg.newKeyPair();
    final rawPriv = await kp.extractPrivateKeyBytes();
    final publicKey = await kp.extractPublicKey();
    final rawPub = publicKey.bytes;
    await _storage.write(
        key: _identityPrivKeyKey, value: base64Encode(rawPriv));
    await _storage.write(key: _identityPubKeyKey, value: base64Encode(rawPub));
    _identityKeyPair = kp;
    _identityPublicKey = publicKey;
  }

  Future<String?> getPublicIdentityKeyBase64() async {
    if (_identityPublicKey == null) await init();
    return _identityPublicKey != null
        ? base64Encode(_identityPublicKey!.bytes)
        : null;
  }

  Future<String?> getConversationKey(String conversationId) async {
    return _storage.read(key: '$_conversationKeyPrefix$conversationId');
  }

  Future<void> storeConversationKey(
      String conversationId, List<int> keyBytes) async {
    await _storage.write(
        key: '$_conversationKeyPrefix$conversationId',
        value: base64Encode(keyBytes));
  }

  Future<void> deleteConversationKey(String conversationId) async {
    await _storage.delete(key: '$_conversationKeyPrefix$conversationId');
  }

  Future<List<int>> deriveConversationKey(
      {required List<int> otherUserPubKey}) async {
    if (_identityKeyPair == null) await init();
    final alg = X25519();
    // Validate remote key length (should be 32 for X25519)
    if (otherUserPubKey.isEmpty || otherUserPubKey.length != 32) {
      throw ArgumentError(
          'Invalid remote public key length: ${otherUserPubKey.length}');
    }
    SimpleKeyPair keyPair = _identityKeyPair!;
    // Log identity pub key length
    final idPub = await keyPair.extractPublicKey();
    debugPrint(
        '[E2EE][KeyStore] derive: identityPubLen=${idPub.bytes.length} remotePubLen=${otherUserPubKey.length}');
    Future<List<int>> _derive(SimpleKeyPair kp) async {
      final sharedSecret = await alg.sharedSecretKey(
        keyPair: kp,
        remotePublicKey:
            SimplePublicKey(otherUserPubKey, type: KeyPairType.x25519),
      );
      final sharedBytes = await sharedSecret.extractBytes();
      debugPrint('[E2EE][KeyStore] sharedBytesLen=${sharedBytes.length}');
      if (sharedBytes.isEmpty) {
        throw ArgumentError('Derived shared secret is empty after X25519');
      }
      try {
        final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
        final secret = await hkdf
            .deriveKey(secretKey: SecretKey(sharedBytes), info: [1, 2, 3]);
        final out = await secret.extractBytes();
        debugPrint('[E2EE][KeyStore] hkdfOutLen=${out.length}');
        if (out.length != 32) {
          throw StateError('HKDF output length unexpected: ${out.length}');
        }
        return out;
      } catch (e) {
        debugPrint(
            '[E2EE][KeyStore] HKDF failed ($e) – falling back to SHA256 digest');
        final digest = await Sha256().hash(sharedBytes);
        final out = digest.bytes; // 32 bytes
        debugPrint('[E2EE][KeyStore] fallback sha256 len=${out.length}');
        return out;
      }
    }

    try {
      return await _derive(keyPair);
    } catch (e) {
      debugPrint(
          '[E2EE][KeyStore] first derive failed: $e – regenerating identity key once');
      await _generateIdentityKeyPair();
      keyPair = _identityKeyPair!;
      try {
        return await _derive(keyPair);
      } catch (e2) {
        debugPrint('[E2EE][KeyStore] second derive failed: $e2');
        rethrow;
      }
    }
  }
}
