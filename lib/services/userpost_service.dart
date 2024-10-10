import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';
import '../models/sharedpost_model.dart';

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
  //api/UserProfile/sharedposts/3
  // Fetch Shared Posts
  Future<List<SharedPostDetails>> fetchSharedPosts(int currentUserId, int viewerUserId, int pageNumber, int pageSize) async {
    final url = Uri.parse('$baseUrl/UserProfile/sharedposts/$currentUserId?viewerUserId=$viewerUserId&pageNumber=$pageNumber&pageSize=$pageSize');

    print("Calling shared posts API: $url"); // Debug statement
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
    });

    //print("Shared posts API response status: ${response.statusCode}"); // Debug statement
    //print("Shared posts API response body: ${response.body}"); // Debug statement

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => SharedPostDetails.fromJson(json)).toList();
    } else if (response.statusCode == 403) {
      throw Exception('Access denied. You are not allowed to view these shared posts.');
    } else if (response.statusCode == 404) {
      throw Exception('No shared posts found for this user.');
    } else {
      throw Exception('Failed to load shared posts');
    }
  }
}
