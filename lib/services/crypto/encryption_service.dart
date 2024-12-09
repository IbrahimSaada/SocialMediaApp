import 'dart:math';
import 'package:cryptography/cryptography.dart';

class EncryptionService {
  final Cipher cipher = AesGcm.with256bits();

  Future<List<int>> encryptMessage({
    required List<int> encryptionKey,
    required List<int> plaintext,
  }) async {
    final secretKey = SecretKey(encryptionKey);
    final nonce = _generateNonce();
    final secretBox = await cipher.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );
    print('Encryption Nonce: $nonce');
    print('Ciphertext: ${secretBox.cipherText}');
    print('MAC: ${secretBox.mac.bytes}');
    return nonce + secretBox.cipherText + secretBox.mac.bytes;
  }

  Future<List<int>> decryptMessage({
    required List<int> encryptionKey,
    required List<int> ciphertext,
  }) async {
    final secretKey = SecretKey(encryptionKey);
    final nonce = ciphertext.sublist(0, 12);
    final macBytes = ciphertext.sublist(ciphertext.length - 16);
    final cipherTextOnly = ciphertext.sublist(12, ciphertext.length - 16);

    print('Decryption Nonce: $nonce');
    print('Ciphertext: $cipherTextOnly');
    print('MAC: $macBytes');

    final secretBox = SecretBox(
      cipherTextOnly,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    return await cipher.decrypt(secretBox, secretKey: secretKey);
  }

  List<int> _generateNonce() {
    final rnd = Random.secure();
    return List<int>.generate(12, (_) => rnd.nextInt(256));
  }
}