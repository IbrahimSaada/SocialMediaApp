import 'package:cryptography/cryptography.dart';
import 'dart:typed_data';

class SessionKeys {
  final List<int> encryptionKey;
  final List<int> macKey;

  SessionKeys({required this.encryptionKey, required this.macKey});
}

class KeyExchangeService {
  final X25519 algorithm = X25519();

  Future<List<int>> deriveSharedSecret({
    required List<int> ourPrivateKey,
    required List<int> theirPublicKey,
  }) async {
    print(
        'deriveSharedSecret: ourPrivateKey length=${ourPrivateKey.length}, theirPublicKey length=${theirPublicKey.length}');
    final ourKeyPair = await algorithm.newKeyPairFromSeed(ourPrivateKey);
    final theirPublicKeyObj =
        SimplePublicKey(theirPublicKey, type: KeyPairType.x25519);

    // Compute shared secret
    final sharedSecret = await algorithm.sharedSecretKey(
      keyPair: ourKeyPair,
      remotePublicKey: theirPublicKeyObj,
    );

    final secretBytes = await sharedSecret.extractBytes();
    print('Shared secret extracted: $secretBytes');
    print('Shared secret length: ${secretBytes.length}');
    return secretBytes;
  }

  Future<SessionKeys> deriveSessionKeys(List<int> sharedSecret) async {
    // Validate shared secret
    if (sharedSecret.isEmpty) {
      throw ArgumentError('Shared secret must not be empty');
    }
    if (sharedSecret.length != 32) {
      throw ArgumentError(
          'Shared secret length is not 32 bytes: ${sharedSecret.length}');
    }
    print('Received shared secret: $sharedSecret');
    print('Shared secret length: ${sharedSecret.length}');

    // Convert sharedSecret explicitly
    final pseudoRandomKey = SecretKey(Uint8List.fromList(sharedSecret));
    print('Pseudo-random key initialized: $pseudoRandomKey');

    // Perform manual HKDF key derivation
    try {
      final hmac = Hmac(Sha256());
      const outputLength = 64; // Total derived key length
      const blockSize = 32; // HMAC output size
      final info = Uint8List(0); // Optional info field for HKDF
      final n = (outputLength / blockSize).ceil(); // Number of blocks
      final derivedKey = <int>[];

      // Initial block is empty
      var previousBlock = <int>[];
      for (int i = 1; i <= n; i++) {
        final data = Uint8List.fromList(previousBlock + info + [i]);
        final mac = await hmac.calculateMac(
          data,
          secretKey: pseudoRandomKey,
        );
        previousBlock = mac.bytes;
        derivedKey.addAll(previousBlock);
      }

      // Extract encryption and MAC keys
      final encryptionKey = derivedKey.sublist(0, 32);
      final macKey = derivedKey.sublist(32, 64);

      print('Derived encryption key: $encryptionKey');
      print('Derived MAC key: $macKey');

      return SessionKeys(encryptionKey: encryptionKey, macKey: macKey);
    } catch (e) {
      print('Error during HKDF key derivation: $e');
      rethrow;
    }
  }
}