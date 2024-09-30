import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';

class UserpostService {
  static const String baseUrl = 'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api';

  // Fetch User Posts
  Future<List<Post>> fetchUserPosts(int userId, int pageNumber, int pageSize) async {
    final url = Uri.parse('$baseUrl/UserProfile?userId=$userId&pageNumber=$pageNumber&pageSize=$pageSize');

    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load user posts');
    }
  }

  // Fetch Bookmarked Posts
  Future<List<Post>> fetchBookmarkedPosts(int userId, int pageNumber, int pageSize) async {
    final url = Uri.parse('$baseUrl/UserProfile/bookmarked?userId=$userId&pageNumber=$pageNumber&pageSize=$pageSize');

    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load bookmarked posts');
    }
  }
}
