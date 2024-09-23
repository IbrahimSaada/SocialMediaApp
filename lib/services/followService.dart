import 'dart:convert';
import 'package:http/http.dart' as http;

class FollowService {
  static const String baseUrl = 'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/Users';

  // Follow a user
  Future<void> followUser(int userId, int followerUserId) async {
    final body = jsonEncode({
      'user_id': userId,
      'follower_user_id': followerUserId,
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/follow'),  // Concatenate for the follow endpoint
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to follow user');
      }
    } catch (e) {
      throw Exception('Error occurred while following user: $e');
    }
  }

  // Unfollow a user
  Future<void> unfollowUser(int userId, int followerUserId) async {
    final body = jsonEncode({
      'user_id': userId,
      'follower_user_id': followerUserId,
    });

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/unfollow'),  // Concatenate for the unfollow endpoint
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to unfollow user');
      }
    } catch (e) {
      throw Exception('Error occurred while unfollowing user: $e');
    }
  }
}
