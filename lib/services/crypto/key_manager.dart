import 'dart:async';

class UserKeyPair {
  final List<int> privateKey;
  final List<int> publicKey;
  UserKeyPair({required this.privateKey, required this.publicKey});
}
