import 'dart:convert';
import 'package:http/http.dart' as http;

class FollowService {
  static const String baseUrl = 'https://da8f-185-97-92-77.ngrok-free.app/api/Users';

  // Follow a user
  Future<void> followUser(int followerUserId, int userId) async {
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
  Future<void> unfollowUser(int followerUserId, int userId) async {
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
