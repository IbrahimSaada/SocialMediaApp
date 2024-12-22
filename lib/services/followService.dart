
import 'package:http/http.dart' as http;
import 'SessionExpiredException.dart';
import 'apiService.dart';
import '../models/followRequestModel.dart';

class FollowService {
  static const String baseUrl = 'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/UserConnections';
  final ApiService _apiService = ApiService();

  /// Follow a user
  Future<void> followUser(int followerUserId, int followedUserId) async {
    final Uri uri = Uri.parse('$baseUrl/follow');
    final Map<String, dynamic> requestBody = {
      'followed_user_id': followedUserId,
      'follower_user_id': followerUserId,
    };

    // Signature data: "followerUserId:followedUserId"
    final String signatureData = '$followerUserId:$followedUserId';

    try {
      // Make the request using ApiService
      final http.Response response = await _apiService.makeRequestWithToken(
        uri,
        signatureData,
        'POST',
        body: requestBody,
      );

      // Check for status codes
      if (response.statusCode == 403) {
        final reason = response.body;
        throw Exception('BLOCKED:$reason');
      }
      if (response.statusCode != 200) {
        throw Exception('Failed to follow user: ${response.body}');
      }
    } on SessionExpiredException {
      // If token refresh fails in ApiService, rethrow to handle it up the chain
      rethrow;
    } catch (e) {
      throw Exception('Error occurred while following user: $e');
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(int followerUserId, int followedUserId) async {
    final Uri uri = Uri.parse('$baseUrl/unfollow');
    final Map<String, dynamic> requestBody = {
      'followed_user_id': followedUserId,
      'follower_user_id': followerUserId,
    };

    // Signature data: "followerUserId:followedUserId"
    final String signatureData = '$followerUserId:$followedUserId';

    try {
      // Make the request (DELETE)
      final http.Response response = await _apiService.makeRequestWithToken(
        uri,
        signatureData,
        'DELETE',
        body: requestBody,
      );

      // Check for status codes
      if (response.statusCode == 403) {
        final reason = response.body;
        throw Exception('BLOCKED:$reason');
      }
      if (response.statusCode != 200) {
        throw Exception('Failed to unfollow user: ${response.body}');
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      throw Exception('Error occurred while unfollowing user: $e');
    }
  }

  /// Cancel a follower request
  Future<void> cancelFollowerRequest(int followerUserId, int followedUserId) async {
    final Uri uri = Uri.parse('$baseUrl/cancel-follower-request');
    final Map<String, dynamic> requestBody = {
      'followed_user_id': followedUserId,
      'follower_user_id': followerUserId,
    };

    // Signature data: "followerUserId:followedUserId"
    final String signatureData = '$followerUserId:$followedUserId';

    try {
      final http.Response response = await _apiService.makeRequestWithToken(
        uri,
        signatureData,
        'POST',
        body: requestBody,
      );

      if (response.statusCode == 403) {
        final reason = response.body;
        throw Exception('BLOCKED:$reason');
      }
      if (response.statusCode != 200) {
        throw Exception('Failed to cancel follower request: ${response.statusCode}');
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      throw Exception('Error occurred while canceling follower request: $e');
    }
  }

  /// Update follower status (e.g., approve or reject)
  Future<void> updateFollowerStatus(int followedUserId, int followerUserId, String approvalStatus) async {
    final Uri uri = Uri.parse('$baseUrl/update-follower-status');
    final Map<String, dynamic> requestBody = {
      'followed_user_id': followedUserId,
      'follower_user_id': followerUserId,
      'approval_status': approvalStatus,
    };

    // Signature data: "followerUserId:followedUserId:approvalStatus"
    final String signatureData = '$followerUserId:$followedUserId:$approvalStatus';

    try {
      final http.Response response = await _apiService.makeRequestWithToken(
        uri,
        signatureData,
        'PUT',
        body: requestBody,
      );

      if (response.statusCode == 403) {
        final reason = response.body;
        throw Exception('BLOCKED:$reason');
      }
      if (response.statusCode != 200) {
        throw Exception('Failed to update follower status: ${response.body}');
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      print('Error updating follower status: $e');
      throw Exception('Error updating follower status: $e');
    }
  }
}
