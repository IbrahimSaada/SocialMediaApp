// services/post_details_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_details_model.dart';
import 'LoginService.dart';

class PostDetailsService {
  static const String baseUrl = 'https://8a93-185-97-92-72.ngrok-free.app/api/Feed/Post';

  final LoginService _loginService = LoginService();

  Future<PostDetailsModel> fetchPostDetails({
    required int postId,
    required int userId,
  }) async {
    try {
      String? token = await _loginService.getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/$postId?userId=$userId'),
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
        return PostDetailsModel.fromJson(json);
      } else if (response.statusCode == 401) {
        // Token invalid, try refreshing
        await _loginService.refreshAccessToken();
        token = await _loginService.getToken();

        // Retry the request
        final retryResponse = await http.get(
          Uri.parse('$baseUrl/$postId?userId=$userId'),
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
          return PostDetailsModel.fromJson(json);
        } else {
          throw Exception('Failed to fetch post details after refreshing token');
        }
      } else {
        throw Exception('Failed to fetch post details: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error fetching post details: $e');
      rethrow;
    }
  }
}
