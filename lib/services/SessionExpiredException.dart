class SessionExpiredException implements Exception {
  final String message;
  SessionExpiredException([this.message = 'SessionExpired']);

  @override
  String toString() => 'SessionExpiredException: $message';
}
