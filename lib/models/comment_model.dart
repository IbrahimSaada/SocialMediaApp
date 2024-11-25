// models/comment_model.dart

class Comment {
  final int commentId;
  final int postId;
  final int userId;
  final String fullName;
  final String userProfilePic;
  final String text;
  final DateTime _createdAtUtc;
  final List<Comment> replies;
  bool isRepliesVisible;
  final Comment? parentComment;

  Comment({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.fullName,
    required this.userProfilePic,
    required this.text,
    required DateTime createdAt,
    this.replies = const [],
    this.isRepliesVisible = false,
    this.parentComment,
  }) : _createdAtUtc = createdAt.toUtc();

  // Getter to convert `createdAt` to local time
  DateTime get localCreatedAt => _createdAtUtc.toLocal();

  factory Comment.fromJson(Map<String, dynamic> json) {
    String createdAtString = json['createdAt'] ?? json['created_at'] ?? '';
    if (createdAtString.isEmpty) {
      createdAtString = DateTime.now().toUtc().toIso8601String();
    }
    if (!createdAtString.endsWith('Z')) {
      createdAtString = '${createdAtString}Z';
    }
    DateTime utcTime = DateTime.parse(createdAtString).toUtc();

    return Comment(
      commentId: json['commentId'] ?? json['commentid'] ?? 0,
      postId: json['postId'] ?? json['postid'] ?? 0,
      userId: json['userId'] ?? json['userid'] ?? 0,
      fullName: json['fullName'] ?? json['fullname'] ?? '',
      userProfilePic: json['userProfilePic'] ?? json['userprofilepic'] ?? '',
      text: json['text'] ?? '',
      createdAt: utcTime,
      replies: (json['replies'] as List<dynamic>?)
              ?.map((replyJson) => Comment.fromJson(replyJson))
              .toList() ??
          [],
      parentComment: json['parentComment'] != null
          ? Comment.fromJson(json['parentComment'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'postId': postId,
      'userId': userId,
      'fullName': fullName,
      'userProfilePic': userProfilePic,
      'text': text,
      'createdAt': _createdAtUtc.toIso8601String(),
      'replies': replies.map((reply) => reply.toJson()).toList(),
      'parentComment': parentComment?.toJson(),
    };
  }
}
