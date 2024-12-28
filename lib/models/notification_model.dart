class NotificationModel {
  final int notificationId;
  final int recipientUserId;
  final int? senderUserId;
  final String type;
  final int? relatedEntityId;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final int? commentId; 
  final String? aggregated_answer_ids; // Existing attribute
  final String? aggregated_comment_ids; // New attribute

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
    this.aggregated_answer_ids,
    this.aggregated_comment_ids,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final dateTimeString = json['createdAt'] ?? json['created_at'];
    final dateTime = _parseUtcDateTime(dateTimeString);

    return NotificationModel(
      notificationId: json['notificationId'] ?? json['notification_id'],
      recipientUserId: json['recipientUserId'] ?? json['recipient_user_id'],
      senderUserId: json['senderUserId'] ?? json['sender_user_id'],
      type: json['type'] ?? '',
      relatedEntityId: json['relatedEntityId'] ?? json['related_entity_id'],
      message: json['message'] ?? '',
      createdAt: dateTime,
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      commentId: json['commentId'] ?? json['comment_id'],
      aggregated_answer_ids: json['aggregated_answer_ids'],
      aggregated_comment_ids: json['aggregated_comment_ids'], // Parse new attribute
    );
  }

  // Helper function to parse UTC datetime and convert to local time
  static DateTime _parseUtcDateTime(String? dateTimeString) {
    if (dateTimeString == null) {
      throw ArgumentError('Invalid date time string');
    }
    if (!dateTimeString.endsWith('Z')) {
      dateTimeString += 'Z';
    }
    return DateTime.parse(dateTimeString).toLocal();
  }
}
