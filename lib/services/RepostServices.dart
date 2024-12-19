// ignore_for_file: file_names, avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'LoginService.dart';
import 'SignatureService.dart';

class RepostService {
  static const String baseUrl =
      'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api';

  final LoginService _loginService = LoginService();
  final SignatureService _signatureService = SignatureService();

  Future<void> createRepost(int userId, int postId, String? comment) async {
    try {
      if (!await _loginService.isLoggedIn()) {
        throw Exception("User not logged in.");
      }
      String? token = await _loginService.getToken();
      if (token == null) {
        throw Exception("No valid token found.");
      }

      String dataToSign = '$userId:$postId:${comment ?? ""}';
      String signature = await _signatureService.generateHMAC(dataToSign);

      final response = await http.post(
        Uri.parse('$baseUrl/Shares'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Signature': signature,
        },
        body: json.encode({
          'userId': userId,
          'postId': postId,
          'comment': comment ?? '',
        }),
      );

      if (response.statusCode == 403) {
        String reason = response.body;
        throw Exception('BLOCKED:$reason');
      }

      if (response.statusCode == 200) {
        print('Repost created successfully');
      } else if (response.statusCode == 401) {
        await _loginService.refreshAccessToken();
        token = await _loginService.getToken();

        signature = await _signatureService.generateHMAC(dataToSign);
        final retryResponse = await http.post(
          Uri.parse('$baseUrl/Shares'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'X-Signature': signature,
          },
          body: json.encode({
            'userId': userId,
            'postId': postId,
            'comment': comment ?? '',
          }),
        );

        if (retryResponse.statusCode == 403) {
          String reason = retryResponse.body;
          throw Exception('BLOCKED:$reason');
        }

        if (retryResponse.statusCode == 200) {
          print('Repost created successfully after token refresh');
        } else {
          throw Exception('Failed to create repost after token refresh');
        }
      } else {
        throw Exception('Failed to create repost: ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('Token expired')) {
        throw Exception('Session expired');
      }
      rethrow;
    }
  }
}
