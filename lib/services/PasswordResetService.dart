// ignore_for_file: file_names

import 'package:http/http.dart' as http;
import 'dart:convert';

class PasswordResetService {
  final String baseUrl =
      '***REMOVED***/api/ResetPassword';

  Future<void> requestPasswordReset(String emailOrPhoneNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/request'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'emailOrPhoneNumber': emailOrPhoneNumber,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to request password reset: ${response.body}');
    }
  }

  Future<bool> verifyUser(
      String emailOrPhoneNumber, String verificationCode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'emailOrPhoneNumber': emailOrPhoneNumber,
        'verificationCode': verificationCode,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> resetPassword(String emailOrPhoneNumber, String verificationCode,
      String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'emailOrPhoneNumber': emailOrPhoneNumber,
        'verificationCode': verificationCode,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reset password: ${response.body}');
    }
  }
}
