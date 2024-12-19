import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class UserVerificationService {
  final String baseUrl =
      'https://3687-185-97-92-30.ngrok-free.app/api/Registration';

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
}
