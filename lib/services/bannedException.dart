class BannedException implements Exception {
  final String reason;
  final String expiresAt;

  BannedException(this.reason, this.expiresAt);

  @override
  String toString() => 'BannedException: $reason (expires at: $expiresAt)';
}
