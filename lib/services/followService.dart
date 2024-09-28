import 'dart:convert';
import 'package:http/http.dart' as http;
import 'LoginService.dart';  // To access JWT and refresh token
import 'SignatureService.dart';  // For signature generation

class FollowService {
  static const String baseUrl = '***REMOVED***/api/UserConnections';

  final LoginService _loginService = LoginService();
  final SignatureService _signatureService = SignatureService();

  // Follow a user
  Future<void> followUser(int followerUserId, int followedUserId) async {
    final body = jsonEncode({
      'followed_user_id': followedUserId,
      'follower_user_id': followerUserId,
    });

    try {
      // Ensure token is valid before making request
      if (!await _loginService.isLoggedIn()) {
        throw Exception("User not logged in.");
      }

      String? token = await _loginService.getToken();

      String dataToSign = '$followerUserId:$followedUserId';
      String signature = await _signatureService.generateHMAC(dataToSign);

      var response = await _makePostRequestWithToken(
        '$baseUrl/follow',
        body,
        signature,
        token,
      );

      if (response.statusCode == 401) {
        // Attempt to refresh token and retry request
        print('JWT token expired. Attempting to refresh token...');
        await _loginService.refreshAccessToken();
        token = await _loginService.getToken();
        print('Token refreshed successfully.');

        // Retry request with the new token
        response = await _makePostRequestWithToken(
          '$baseUrl/follow',
          body,
          signature,
          token,
        );

        if (response.statusCode == 401) {
          throw Exception('Session expired or refresh token invalid.');
        }
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to follow user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error occurred while following user: $e');
    }
  }

  // Unfollow a user
  Future<void> unfollowUser(int followerUserId, int followedUserId) async {
    final body = jsonEncode({
      'followed_user_id': followedUserId,
      'follower_user_id': followerUserId,
    });

    try {
      // Ensure token is valid before making request
      if (!await _loginService.isLoggedIn()) {
        throw Exception("User not logged in.");
      }

      String? token = await _loginService.getToken();

      String dataToSign = '$followerUserId:$followedUserId';
      String signature = await _signatureService.generateHMAC(dataToSign);

      var response = await _makeDeleteRequestWithToken(
        '$baseUrl/unfollow',
        body,
        signature,
        token,
      );

      if (response.statusCode == 401) {
        // Attempt to refresh token and retry request
        print('JWT token expired. Attempting to refresh token...');
        await _loginService.refreshAccessToken();
        token = await _loginService.getToken();
        print('Token refreshed successfully.');

        // Retry request with the new token
        response = await _makeDeleteRequestWithToken(
          '$baseUrl/unfollow',
          body,
          signature,
          token,
        );

        if (response.statusCode == 401) {
          throw Exception('Session expired or refresh token invalid.');
        }
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to unfollow user: ${response.body}');
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
      // Ensure token is valid before making request
      if (!await _loginService.isLoggedIn()) {
        throw Exception("User not logged in.");
      }

      String? token = await _loginService.getToken();

      String dataToSign = '$followerUserId:$followedUserId';
      String signature = await _signatureService.generateHMAC(dataToSign);

      var response = await _makePostRequestWithToken(
        '$baseUrl/cancel-follower-request',
        body,
        signature,
        token,
      );

      if (response.statusCode == 401) {
        // Attempt to refresh token and retry request
        print('JWT token expired. Attempting to refresh token...');
        await _loginService.refreshAccessToken();
        token = await _loginService.getToken();
        print('Token refreshed successfully.');

        // Retry request with the new token
        response = await _makePostRequestWithToken(
          '$baseUrl/cancel-follower-request',
          body,
          signature,
          token,
        );

        if (response.statusCode == 401) {
          throw Exception('Session expired or refresh token invalid.');
        }
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel follower request: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error occurred while canceling follower request: $e');
    }
  }

  // Helper method to make POST requests
  Future<http.Response> _makePostRequestWithToken(
      String url, String body, String signature, String? token) async {
    return await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'X-Signature': signature,
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
  }

  // Helper method to make DELETE requests
  Future<http.Response> _makeDeleteRequestWithToken(
      String url, String body, String signature, String? token) async {
    return await http.delete(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'X-Signature': signature,
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
  }
}
