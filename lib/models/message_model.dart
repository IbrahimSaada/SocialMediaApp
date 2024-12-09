// models/message_model.dart

import 'media_model.dart';

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
  final bool isLoadingMessage; // New field to mark loading messages

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
    this.isLoadingMessage = false,
  });

  factory Message.loadingMessage() {
    return Message(
      messageId: -1,
      chatId: 0,
      senderId: 0,
      messageType: 'loading',
      messageContent: '',
      createdAt: DateTime.now().toLocal(),
      isEdited: false,
      isUnsent: false,
      mediaItems: [],
      isLoadingMessage: true,
    );
  }

  static DateTime _parseUtcThenLocal(String dateStr) {
    if (!dateStr.endsWith('Z')) {
      dateStr = dateStr + 'Z';
    }
    return DateTime.parse(dateStr).toLocal();
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    print('Parsing Message from JSON: $json');

    DateTime createdAt;
    if (json['createdAt'] is String) {
      createdAt = _parseUtcThenLocal(json['createdAt']);
    } else if (json['createdAt'] is DateTime) {
      createdAt = (json['createdAt']).toLocal();
    } else {
      throw Exception('Invalid format for createdAt');
    }

    DateTime? readAt;
    if (json['readAt'] != null) {
      if (json['readAt'] is String) {
        readAt = _parseUtcThenLocal(json['readAt']);
      } else if (json['readAt'] is DateTime) {
        readAt = (json['readAt']).toLocal();
      }
    }

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

    print('Parsed Message: $message');
    return message;
  }

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
    bool? isLoadingMessage,
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
      isLoadingMessage: isLoadingMessage ?? this.isLoadingMessage,
    );

    print('Updated Message with copyWith: $updatedMessage');
    return updatedMessage;
  }

  @override
  String toString() {
    return 'Message(messageId: $messageId, chatId: $chatId, senderId: $senderId, messageType: $messageType, messageContent: "$messageContent", createdAt: $createdAt, readAt: $readAt, isEdited: $isEdited, isUnsent: $isUnsent, mediaItems: ${mediaItems.length}, isLoadingMessage: $isLoadingMessage)';
  }
}
