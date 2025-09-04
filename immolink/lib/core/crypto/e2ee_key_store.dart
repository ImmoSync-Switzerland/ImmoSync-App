import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cryptography/cryptography.dart';

/// Stores identity key pair and per-conversation symmetric keys.
class E2EEKeyStore {
  static const _identityPrivKeyKey = 'e2ee.identity.private';
  static const _identityPubKeyKey = 'e2ee.identity.public';
  static const _conversationKeyPrefix = 'e2ee.conversation.'; // + conversationId
  final FlutterSecureStorage _storage;
  SimpleKeyPair? _identityKeyPair;
  SimplePublicKey? _identityPublicKey;

  E2EEKeyStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

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
  await _storage.write(key: _identityPrivKeyKey, value: base64Encode(rawPriv));
  await _storage.write(key: _identityPubKeyKey, value: base64Encode(rawPub));
  _identityKeyPair = kp;
  _identityPublicKey = publicKey;
  }

  Future<String?> getPublicIdentityKeyBase64() async {
    if (_identityPublicKey == null) await init();
    return _identityPublicKey != null ? base64Encode(_identityPublicKey!.bytes) : null;
  }

  Future<String?> getConversationKey(String conversationId) async {
    return _storage.read(key: '$_conversationKeyPrefix$conversationId');
  }

  Future<void> storeConversationKey(String conversationId, List<int> keyBytes) async {
    await _storage.write(key: '$_conversationKeyPrefix$conversationId', value: base64Encode(keyBytes));
  }

  Future<void> deleteConversationKey(String conversationId) async {
    await _storage.delete(key: '$_conversationKeyPrefix$conversationId');
  }

  Future<List<int>> deriveConversationKey({required List<int> otherUserPubKey}) async {
    if (_identityKeyPair == null) await init();
    final alg = X25519();
    final shared = await alg.sharedSecretKey(keyPair: _identityKeyPair!, remotePublicKey: SimplePublicKey(otherUserPubKey, type: KeyPairType.x25519));
  final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  final secret = await hkdf.deriveKey(secretKey: shared, info: [1,2,3]);
  return secret.extractBytes();
  }
}
