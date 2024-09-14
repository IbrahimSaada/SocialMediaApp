// ignore_for_file: file_names, avoid_print

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'LoginService.dart';

class SecureService {
  final LoginService _loginService = LoginService();
  final String secureUrl =
      '***REMOVED***/api/Secure/data';

  Future<String> getSecureData() async {
    var token = await _loginService.getToken();

    if (token == null) {
      throw Exception('No JWT token found, user needs to login.');
    }

    final response = await http.get(
      Uri.parse(secureUrl),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['message'] ?? 'No message in response';
    } else {
      print(
          'Failed to load secure data: ${response.statusCode} ${response.body}');
      return Future.error(
          'Failed to load secure data: ${response.statusCode} ${response.body}');
    }
  }
}
