// models/message_model.dart

import 'media_item.dart';

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
  final List<MediaItem> mediaItems;

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
    required this.mediaItems,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    print('Parsing Message from JSON: $json'); // Print the initial JSON data

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

    // Parse media items
    List<MediaItem> mediaItems = [];
    if (json['mediaItems'] != null) {
      mediaItems = (json['mediaItems'] as List)
          .map((item) => MediaItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    final message = Message(
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
      mediaItems: mediaItems,
    );

    print('Parsed Message: $message'); // Print the parsed Message object
    return message;
  }

  // Add a copyWith method for easy updates
  Message copyWith({
    int? messageId,
    int? chatId,
    int? senderId,
    String? senderUsername,
    String? senderProfilePic,
    String? messageType,
    String? messageContent,
    DateTime? createdAt,
    DateTime? readAt,
    bool? isEdited,
    bool? isUnsent,
    List<MediaItem>? mediaItems,
  }) {
    final updatedMessage = Message(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderUsername: senderUsername ?? this.senderUsername,
      senderProfilePic: senderProfilePic ?? this.senderProfilePic,
      messageType: messageType ?? this.messageType,
      messageContent: messageContent ?? this.messageContent,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      isEdited: isEdited ?? this.isEdited,
      isUnsent: isUnsent ?? this.isUnsent,
      mediaItems: mediaItems ?? this.mediaItems,
    );

    print('Updated Message with copyWith: $updatedMessage'); // Print the updated Message object
    return updatedMessage;
  }
}
