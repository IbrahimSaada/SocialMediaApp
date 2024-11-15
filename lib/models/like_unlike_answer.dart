// models/like_unlike_answer.dart

class LikeUnlikeAnswer {
  final int questionId;
  final int userId;

  LikeUnlikeAnswer({
    required this.questionId,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'userId': userId,
    };
  }
}
