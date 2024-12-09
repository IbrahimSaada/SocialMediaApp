// models/contact.dart

class Contact {
  final int chatId;
  final int initiatorUserId;
  final String initiatorUsername;
  final String initiatorProfilePic;
  final int recipientUserId;
  final String recipientUsername;
  final String recipientProfilePic;
  final DateTime createdAt;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  Contact({
    required this.chatId,
    required this.initiatorUserId,
    required this.initiatorUsername,
    required this.initiatorProfilePic,
    required this.recipientUserId,
    required this.recipientUsername,
    required this.recipientProfilePic,
    required this.createdAt,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
  });

  Contact copyWith({
    int? chatId,
    int? initiatorUserId,
    String? initiatorUsername,
    String? initiatorProfilePic,
    int? recipientUserId,
    String? recipientUsername,
    String? recipientProfilePic,
    DateTime? createdAt,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
  }) {
    return Contact(
      chatId: chatId ?? this.chatId,
      initiatorUserId: initiatorUserId ?? this.initiatorUserId,
      initiatorUsername: initiatorUsername ?? this.initiatorUsername,
      initiatorProfilePic: initiatorProfilePic ?? this.initiatorProfilePic,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      recipientUsername: recipientUsername ?? this.recipientUsername,
      recipientProfilePic: recipientProfilePic ?? this.recipientProfilePic,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  static DateTime _parseUtcThenLocal(String dateStr) {
    if (!dateStr.endsWith('Z')) {
      dateStr = dateStr + 'Z';
    }
    return DateTime.parse(dateStr).toLocal();
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      chatId: json['chatId'],
      initiatorUserId: json['initiatorUserId'],
      initiatorUsername: json['initiatorUsername'],
      initiatorProfilePic: json['initiatorProfilePic'],
      recipientUserId: json['recipientUserId'],
      recipientUsername: json['recipientUsername'],
      recipientProfilePic: json['recipientProfilePic'],
      createdAt: _parseUtcThenLocal(json['createdAt']),
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? _parseUtcThenLocal(json['lastMessageTime'])
          : DateTime.now().toLocal(),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}
