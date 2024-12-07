// services/chat_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cook/models/contact_model.dart';
import 'package:cook/models/message_model.dart';
import 'package:cook/models/deleteuserchat.dart';

class ChatService {
  final String chatBaseUrl = 'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/Chat';
  final String messageBaseUrl = 'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/Message';

  // Fetch user chats
  Future<List<Contact>> fetchUserChats(int userId) async {
    final url = Uri.parse('$chatBaseUrl/get-chats/$userId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        // Data now includes lastMessage, lastMessageTime, unreadCount
        return data.map((json) => Contact.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load chats');
      }
    } catch (e) {
      print('Error in fetchUserChats: $e');
      throw Exception('Error fetching chats: $e');
    }
  }

  // Delete a chat (soft delete)
  Future<void> deleteChat(DeleteUserChat deleteUserChat) async {
    final url = Uri.parse('$chatBaseUrl/delete-chat');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(deleteUserChat.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete chat. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in deleteChat: $e');
      throw Exception('Error deleting chat: $e');
    }
  }

  // Fetch messages for a specific chat with pagination
  Future<List<Message>> fetchMessages(int chatId, int pageNumber, int pageSize) async {
    final url = Uri.parse(
        '$messageBaseUrl/get-messages/$chatId?pageNumber=$pageNumber&pageSize=$pageSize');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load messages. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchMessages: $e');
      throw Exception('Error fetching messages: $e');
    }
  }
}
