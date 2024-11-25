// services/repost_details_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/repost_details_model.dart';
import 'LoginService.dart';

class RepostDetailsService {
  static const String baseUrl = 'https://8a93-185-97-92-72.ngrok-free.app/api/Feed/SharedPost';

  final LoginService _loginService = LoginService();

  Future<RepostDetailsModel> fetchRepostDetails({
    required int sharePostId,
    required int userId,
  }) async {
    try {
      String? token = await _loginService.getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/$sharePostId?userId=$userId'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Log the response for debugging
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> json = jsonDecode(response.body);
        return RepostDetailsModel.fromJson(json);
      } else if (response.statusCode == 401) {
        // Token invalid, try refreshing
        await _loginService.refreshAccessToken();
        token = await _loginService.getToken();

        // Retry the request
        final retryResponse = await http.get(
          Uri.parse('$baseUrl/$sharePostId?userId=$userId'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        // Log the retry response
        print('Retry response status: ${retryResponse.statusCode}');
        print('Retry response body: ${retryResponse.body}');

        if (retryResponse.statusCode == 200) {
          Map<String, dynamic> json = jsonDecode(retryResponse.body);
          return RepostDetailsModel.fromJson(json);
        } else {
          throw Exception('Failed to fetch repost details after refreshing token');
        }
      } else {
        throw Exception('Failed to fetch repost details: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error fetching repost details: $e');
      rethrow;
    }
  }
}
