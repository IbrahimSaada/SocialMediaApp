// chat_service.dart

import 'dart:convert';
import 'package:myapp/models/message_model.dart';
import 'package:myapp/models/contact_model.dart';
import 'package:myapp/models/deleteuserchat.dart';
import 'package:myapp/models/mute_user_dto.dart';
import 'package:myapp/services/apiService.dart';
import 'package:myapp/services/SessionExpiredException.dart';

class ChatService {
  final String baseUrl =
      'your-backend-server/api/Chat';
  final ApiService _apiService = ApiService();

  /// Fetch user chats with token & signature
  Future<List<Contact>> fetchUserChats(int userId) async {
    // dataToSign = userId
    final String dataToSign = '$userId';
    final Uri uri = Uri.parse('$baseUrl/get-chats/$userId');

    try {
      final response = await _apiService.makeRequestWithToken(
        uri,
        dataToSign,
        'GET',
      );

      if (response.statusCode == 403) {
        final reason = response.body;
        throw Exception('BLOCKED:$reason');
      } else if (response.statusCode == 401) {
        // The token refresh logic in ApiService didn’t fix it => truly expired
        throw Exception('Session expired or refresh token invalid.');
      } else if (response.statusCode != 200) {
        throw Exception(
          'Failed to load chats: '
          '${response.statusCode} => ${response.body}',
        );
      }

      // Parse the JSON
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Contact.fromJson(json)).toList();
    } on SessionExpiredException {
      // Let the UI handle re-login
      rethrow;
    } catch (e) {
      print('Error in fetchUserChats => $e');
      rethrow;
    }
  }

  /// Delete a chat (soft delete)
  Future<void> deleteChat(DeleteUserChat deleteUserChat) async {
    // dataToSign = "userId:chatId"
    final String dataToSign =
        '${deleteUserChat.userId}:${deleteUserChat.chatId}';
    final Uri uri = Uri.parse('$baseUrl/delete-chat');

    try {
      final response = await _apiService.makeRequestWithToken(
        uri,
        dataToSign,
        'POST',
        body: deleteUserChat.toJson(),
      );

      if (response.statusCode == 403) {
        final reason = response.body;
        throw Exception('BLOCKED:$reason');
      } else if (response.statusCode == 401) {
        throw Exception('Session expired or refresh token invalid.');
      } else if (response.statusCode != 200) {
        throw Exception(
          'Failed to delete chat => '
          '${response.statusCode} => ${response.body}',
        );
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      print('Error in deleteChat => $e');
      rethrow;
    }
  }

  /// Mute a user
  Future<void> muteUser(MuteUserDto dto) async {
    // dataToSign example => "MutedByUserId:3|MutedUserId:5"
    final String dataToSign =
        'MutedByUserId:${dto.mutedByUserId}|MutedUserId:${dto.mutedUserId}';
    final Uri uri = Uri.parse('$baseUrl/mute-user');

    try {
      final response = await _apiService.makeRequestWithToken(
        uri,
        dataToSign,
        'POST',
        body: dto.toJson(),
      );

      if (response.statusCode == 403) {
        throw Exception('BLOCKED:${response.body}');
      } else if (response.statusCode == 401) {
        throw Exception('Session expired or refresh token invalid.');
      } else if (response.statusCode != 200) {
        throw Exception(
          'Failed to mute user => '
          '${response.statusCode} => ${response.body}',
        );
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      print('Error in muteUser => $e');
      rethrow;
    }
  }

  /// Unmute a user
  Future<void> unmuteUser(MuteUserDto dto) async {
    // dataToSign => "MutedByUserId:3|MutedUserId:5"
    final String dataToSign =
        'MutedByUserId:${dto.mutedByUserId}|MutedUserId:${dto.mutedUserId}';
    final Uri uri = Uri.parse('$baseUrl/unmute-user');

    try {
      final response = await _apiService.makeRequestWithToken(
        uri,
        dataToSign,
        'POST',
        body: dto.toJson(),
      );

      if (response.statusCode == 403) {
        throw Exception('BLOCKED:${response.body}');
      } else if (response.statusCode == 401) {
        throw Exception('Session expired or refresh token invalid.');
      } else if (response.statusCode != 200) {
        throw Exception(
          'Failed to unmute user => '
          '${response.statusCode} => ${response.body}',
        );
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      print('Error in unmuteUser => $e');
      rethrow;
    }
  }
}
