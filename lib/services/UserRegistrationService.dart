import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class UserRegistrationService {
  final String baseUrl =
      'https://3687-185-97-92-30.ngrok-free.app/api/Registration';

  Future<void> registerUser(UserModel user) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 201) {
        // Registration successful
      } else if (response.statusCode == 500) {
        throw Exception('Server error (500). Please try again later.');
      } else {
        throw Exception('Failed to register user: ${response.body}');
      }
    } on SocketException {
      throw Exception('No network connection. Please check your internet.');
    }
  }

  Future<bool> emailExists(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/email-exists/$email'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        return response.body == 'true';
      } else if (response.statusCode == 500) {
        throw Exception('Server error (500). Please try again later.');
      } else {
        throw Exception('Failed to check email: ${response.body}');
      }
    } on SocketException {
      throw Exception('No network connection. Please check your internet.');
    }
  }
}
