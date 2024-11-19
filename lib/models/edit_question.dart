// models/edit_question.dart

class EditQuestion {
  final int questionId;
  final int userId;
  final String newCaption;

  EditQuestion({
    required this.questionId,
    required this.userId,
    required this.newCaption,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'userId': userId,
      'newCaption': newCaption,
    };
  }
}