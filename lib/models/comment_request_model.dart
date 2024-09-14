// models/comment_request_model.dart
class CommentRequest {
  final int postId;
  final int userId;
  final String text;
  final int? parentCommentId;

  CommentRequest({
    required this.postId,
    required this.userId,
    required this.text,
    this.parentCommentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'postid': postId,
      'userid': userId,
      'text': text,
      'parentcommentid': parentCommentId,
    };
  }
}
