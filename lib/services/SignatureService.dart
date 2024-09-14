// ignore_for_file: file_names

import 'dart:convert';
import 'package:crypto/crypto.dart';  // For HMAC-SHA256 signature generation
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SignatureService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Ensure secret key is stored
  Future<void> ensureSecretKey() async {
    String? storedKey = await _secureStorage.read(key: 'secretKey');
    if (storedKey == null) {
      const String secretKey = 'YourSharedSecretKeyForRequestSigning';  // Replace with your actual key
      await _secureStorage.write(key: 'secretKey', value: secretKey);
      // ignore: avoid_print
      print('Secret key re-stored in secure storage.');
    }
  }

  // Generate HMAC-SHA256 signature
  Future<String> generateHMAC(String data) async {
    // Ensure the secret key is stored
    await ensureSecretKey();

    // Retrieve the secret key
    String? secretKey = await _secureStorage.read(key: 'secretKey');
    if (secretKey == null) {
      throw Exception('Secret key not found');
    }

    var key = utf8.encode(secretKey);  // Convert secretKey to UTF8
    var bytes = utf8.encode(data);     // Convert data to UTF8

    var hmacSha256 = Hmac(sha256, key);
    var digest = hmacSha256.convert(bytes);

    // Return the Base64-encoded signature
    return base64.encode(digest.bytes);
  }
}
