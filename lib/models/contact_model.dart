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

  Contact({
    required this.chatId,
    required this.initiatorUserId,
    required this.initiatorUsername,
    required this.initiatorProfilePic,
    required this.recipientUserId,
    required this.recipientUsername,
    required this.recipientProfilePic,
    required this.createdAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      chatId: json['chatId'],
      initiatorUserId: json['initiatorUserId'],
      initiatorUsername: json['initiatorUsername'],
      initiatorProfilePic: json['initiatorProfilePic'],
      recipientUserId: json['recipientUserId'],
      recipientUsername: json['recipientUsername'],
      recipientProfilePic: json['recipientProfilePic'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
