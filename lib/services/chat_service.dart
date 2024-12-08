import 'dart:convert';
import 'package:cook/models/contact_model.dart';
import 'package:cook/models/message_model.dart';
import 'package:cook/models/deleteuserchat.dart';
import 'package:cook/services/apiService.dart';

class ChatService {
  final String baseUrl = 'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/Chat'; 
  final ApiService _apiService = ApiService();

  // Fetch user chats with token & signature
  Future<List<Contact>> fetchUserChats(int userId) async {
    // dataToSign = userId
    String dataToSign = "$userId";
    final uri = Uri.parse('$baseUrl/get-chats/$userId');

    final response = await _apiService.makeRequestWithToken(
      uri,
      dataToSign,
      'GET',
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Contact.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load chats: ${response.body}');
    }
  }

  // Delete a chat (soft delete)
  Future<void> deleteChat(DeleteUserChat deleteUserChat) async {
    // dataToSign = "userId:chatId"
    String dataToSign = "${deleteUserChat.userId}:${deleteUserChat.chatId}";
    final uri = Uri.parse('$baseUrl/delete-chat');

    final response = await _apiService.makeRequestWithToken(
      uri,
      dataToSign,
      'POST',
      body: deleteUserChat.toJson(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete chat: ${response.body}');
    }
  }
}
