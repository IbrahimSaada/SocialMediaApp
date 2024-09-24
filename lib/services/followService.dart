// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'package:http/http.dart' as http;

class FollowService {
  static const String baseUrl = '***REMOVED***/api/Users';

  // Follow a user
  Future<void> followUser(int followerUserId, int followed_userId) async {
    final body = jsonEncode({
      'followed_user_id': followed_userId,
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
  Future<void> unfollowUser(int followerUserId, int followed_userId) async {
    final body = jsonEncode({
      'followed_user_id': followed_userId,
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
  // Cancel a follower request
  Future<void> cancelFollowerRequest(int followerUserId, int followedUserId) async {
    final body = jsonEncode({
      'followed_user_id': followedUserId,
      'follower_user_id': followerUserId,
    });

    try {
      // Make sure the URL and HTTP method are correct
      final response = await http.post(
        Uri.parse('$baseUrl/cancel-follower-request'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel follower request: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error occurred while canceling follower request: $e');
    }
  }
}
