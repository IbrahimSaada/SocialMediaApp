
// ignore_for_file: file_names

class LikeRequest {
  final int userId;
  final int postId;

  LikeRequest({required this.userId, required this.postId});

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'post_id': postId,
    };
  }
}
