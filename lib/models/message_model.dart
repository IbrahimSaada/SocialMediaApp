// models/message.dart

class Message {
  final int messageId;
  final int chatId;
  final int senderId;
  final String senderUsername;
  final String senderProfilePic;
  final String messageType;
  final String messageContent;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool isEdited;
  final bool isUnsent;
  final List<String> mediaUrls;

  Message({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.senderUsername,
    required this.senderProfilePic,
    required this.messageType,
    required this.messageContent,
    required this.createdAt,
    this.readAt,
    required this.isEdited,
    required this.isUnsent,
    required this.mediaUrls,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['messageId'],
      chatId: json['chatId'],
      senderId: json['senderId'],
      senderUsername: json['senderUsername'],
      senderProfilePic: json['senderProfilePic'],
      messageType: json['messageType'],
      messageContent: json['messageContent'],
      createdAt: DateTime.parse(json['createdAt']),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      isEdited: json['isEdited'],
      isUnsent: json['isUnsent'],
      mediaUrls: List<String>.from(json['mediaUrls']),
    );
  }
}
