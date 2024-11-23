// notification_model.dart
import 'dart:convert';

class NotificationModel {
  final int notificationId;
  final int recipientUserId;
  final int? senderUserId;
  final String type;
  final int? relatedEntityId;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.notificationId,
    required this.recipientUserId,
    this.senderUserId,
    required this.type,
    this.relatedEntityId,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notification_id'],
      recipientUserId: json['recipient_user_id'],
      senderUserId: json['sender_user_id'],
      type: json['type'],
      relatedEntityId: json['related_entity_id'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'],
    );
  }
}
