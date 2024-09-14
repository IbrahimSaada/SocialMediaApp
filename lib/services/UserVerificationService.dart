// ignore_for_file: file_names

import 'package:http/http.dart' as http;
import 'dart:convert';

class UserVerificationService {
  final String baseUrl =
      'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/Registration';

  Future<bool> verifyUser(String email, String verificationCode) async {
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
    } else {
      return false;
    }
  }
}
