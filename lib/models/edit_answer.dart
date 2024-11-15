// models/edit_answer.dart

class EditAnswer {
  final int answerId;
  final int userId;
  final String newText;

  EditAnswer({
    required this.answerId,
    required this.userId,
    required this.newText,
  });

  Map<String, dynamic> toJson() {
    return {
      'answerId': answerId,
      'userId': userId,
      'newText': newText,
    };
  }
}
