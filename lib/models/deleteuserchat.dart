// models/delete_user_chat.dart

class DeleteUserChat {
  final int chatId;
  final int userId;

  DeleteUserChat({required this.chatId, required this.userId});

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'userId': userId,
    };
  }
}