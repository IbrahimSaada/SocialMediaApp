class BookmarkRequest {
  final int userId;
  final int postId;

  BookmarkRequest({required this.userId, required this.postId});

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'post_id': postId,
    };
  }
}