// models/notification_model.dart

class NotificationModel {
  final int notificationId;
  final int recipientUserId;
  final int? senderUserId;
  final String type;
  final int? relatedEntityId;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final int? commentId; // For comment and reply notifications

  NotificationModel({
    required this.notificationId,
    required this.recipientUserId,
    this.senderUserId,
    required this.type,
    this.relatedEntityId,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.commentId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'] ?? json['notification_id'],
      recipientUserId: json['recipientUserId'] ?? json['recipient_user_id'],
      senderUserId: json['senderUserId'] ?? json['sender_user_id'],
      type: json['type'] ?? '',
      relatedEntityId: json['relatedEntityId'] ?? json['related_entity_id'],
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      commentId: json['commentId'] ?? json['comment_id'],
    );
  }
}
