// services/chat_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cook/models/contact_model.dart';
import 'package:cook/models/message_model.dart';

class ChatService {
  final String chatBaseUrl = 'https://be2d-185-89-86-31.ngrok-free.app/api/Chat';
  final String messageBaseUrl = 'https://be2d-185-89-86-31.ngrok-free.app/api/Message';

  // Fetch user chats
  Future<List<Contact>> fetchUserChats(int userId) async {
    final url = Uri.parse('$chatBaseUrl/get-chats/$userId'); // Corrected path

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Contact.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load chats');
      }
    } catch (e) {
      print('Error in fetchUserChats: $e');
      throw Exception('Error fetching chats: $e');
    }
  }

  // Fetch messages for a specific chat
  Future<List<Message>> fetchMessages(int chatId) async {
    final url = Uri.parse('$messageBaseUrl/get-messages/$chatId'); // Corrected path

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
