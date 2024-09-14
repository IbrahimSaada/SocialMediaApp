import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cook/models/LikeRequest_model.dart';

class LikeService {
  static const String baseUrl =
      'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/Posts';

  // Method to like a post
  static Future<void> likePost(LikeRequest likeRequest) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Like'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(likeRequest.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to like post');
    }
  }

  // Method to unlike a post
  static Future<void> unlikePost(LikeRequest likeRequest) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Unlike'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(likeRequest.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to unlike post');
    }
  }
}
