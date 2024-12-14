class BlockedUserException implements Exception {
  final String reason;
  final bool isBlockedBy;
  final bool isUserBlocked;

  BlockedUserException({
    required this.reason,
    required this.isBlockedBy,
    required this.isUserBlocked,
  });

  @override
  String toString() {
    return 'BlockedUserException: $reason';
  }
}