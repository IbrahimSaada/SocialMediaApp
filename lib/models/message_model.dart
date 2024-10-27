// models/message_model.dart

class Message {
  final int messageId;
  final int chatId;
  final int senderId;
  final String? senderUsername;
  final String? senderProfilePic;
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
    this.senderUsername,
    this.senderProfilePic,
    required this.messageType,
    required this.messageContent,
    required this.createdAt,
    this.readAt,
    required this.isEdited,
    required this.isUnsent,
    required this.mediaUrls,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Handle 'createdAt'
    DateTime createdAt;
    if (json['createdAt'] is String) {
      createdAt = DateTime.parse(json['createdAt']);
    } else if (json['createdAt'] is DateTime) {
      createdAt = json['createdAt'];
    } else {
      throw Exception('Invalid format for createdAt');
    }

    // Handle 'readAt'
    DateTime? readAt;
    if (json['readAt'] != null) {
      if (json['readAt'] is String) {
        readAt = DateTime.parse(json['readAt']);
      } else if (json['readAt'] is DateTime) {
        readAt = json['readAt'];
      }
    }

    return Message(
      messageId: json['messageId'] ?? 0,
      chatId: json['chatId'] ?? 0,
      senderId: json['senderId'] ?? 0,
      senderUsername: json['senderUsername'],
      senderProfilePic: json['senderProfilePic'],
      messageType: json['messageType'] ?? 'text',
      messageContent: json['messageContent'] ?? '',
      createdAt: createdAt,
      readAt: readAt,
      isEdited: json['isEdited'] ?? false,
      isUnsent: json['isUnsent'] ?? false,
      mediaUrls: json['mediaUrls'] != null ? List<String>.from(json['mediaUrls']) : [],
    );
  }
}
