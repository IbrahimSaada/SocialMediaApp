// ignore_for_file: file_names

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class PasswordResetService {
  final String baseUrl =
      '***REMOVED***/api/ResetPassword';

  Future<void> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/request'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        // Request successful
      } else if (response.statusCode == 500) {
        throw Exception('Server error (500). Please try again later.');
      } else {
        throw Exception('Failed to request password reset: ${response.body}');
      }
    } on SocketException {
      throw Exception('No network connection. Please check your internet.');
    }
  }

  Future<bool> verifyUser(String email, String verificationCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'email': email,
          'verificationCode': verificationCode,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 500) {
        throw Exception('Server error (500). Please try again later.');
      } else {
        return false;
      }
    } on SocketException {
      throw Exception('No network connection. Please check your internet.');
    }
  }

  Future<void> resetPassword(
      String email, String verificationCode, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'email': email,
          'verificationCode': verificationCode,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        // Password reset successful
      } else if (response.statusCode == 500) {
        throw Exception('Server error (500). Please try again later.');
      } else {
        throw Exception('Failed to reset password: ${response.body}');
      }
    } on SocketException {
      throw Exception('No network connection. Please check your internet.');
    }
  }
}
