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
  }) : _createdAtUtc = createdAt.toUtc();

  // Getter to convert `createdAt` to local time
  DateTime get localCreatedAt => _createdAtUtc.toLocal();

  factory Comment.fromJson(Map<String, dynamic> json) {
    String createdAtString = json['created_at'];
    if (!createdAtString.endsWith('Z')) {
      createdAtString = '${createdAtString}Z';
    }
    DateTime utcTime = DateTime.parse(createdAtString).toUtc();
    return Comment(
      commentId: json['commentid'],
      postId: json['postid'],
      userId: json['userid'],
      fullName: json['fullname'],
      userProfilePic: json['userprofilepic'],
      text: json['text'],
      createdAt: utcTime, // Ensure UTC is passed
      replies: (json['replies'] as List<dynamic>)
          .map((replyJson) => Comment.fromJson(replyJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentid': commentId,
      'postid': postId,
      'userid': userId,
      'fullname': fullName,
      'userprofilepic': userProfilePic,
      'text': text,
      'createdAt': _createdAtUtc.toIso8601String(), // Pass the UTC time
      'replies': replies.map((reply) => reply.toJson()).toList(),
    };
  }
}