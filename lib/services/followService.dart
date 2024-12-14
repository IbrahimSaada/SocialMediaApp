import 'dart:convert';
import 'package:http/http.dart' as http;
import 'LoginService.dart';  
import 'SignatureService.dart';  
import 'package:cook/models/followRequestModel.dart';

class FollowService {
  static const String baseUrl = 'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/UserConnections';

  final LoginService _loginService = LoginService();
  final SignatureService _signatureService = SignatureService();

  Future<void> followUser(int followerUserId, int followedUserId) async {
    final body = jsonEncode({
      'followed_user_id': followedUserId,
      'follower_user_id': followerUserId,
    });

    try {
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

      if (response.statusCode == 403) {
        final reason = response.body;
        throw Exception('BLOCKED:$reason');
      }

      if (response.statusCode == 401) {
        await _loginService.refreshAccessToken();
        token = await _loginService.getToken();

        response = await _makePostRequestWithToken(
          '$baseUrl/follow',
          body,
          signature,
          token,
        );

        if (response.statusCode == 403) {
          final reason = response.body;
          throw Exception('BLOCKED:$reason');
        }

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

  Future<void> unfollowUser(int followerUserId, int followedUserId) async {
    final body = jsonEncode({
      'followed_user_id': followedUserId,
      'follower_user_id': followerUserId,
    });

    try {
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

      if (response.statusCode == 403) {
        final reason = response.body;
        throw Exception('BLOCKED:$reason');
      }

      if (response.statusCode == 401) {
        await _loginService.refreshAccessToken();
        token = await _loginService.getToken();

        response = await _makeDeleteRequestWithToken(
          '$baseUrl/unfollow',
          body,
          signature,
          token,
        );

        if (response.statusCode == 403) {
          final reason = response.body;
          throw Exception('BLOCKED:$reason');
        }

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

  Future<void> cancelFollowerRequest(int followerUserId, int followedUserId) async {
    final body = jsonEncode({
      'followed_user_id': followedUserId,
      'follower_user_id': followerUserId,
    });

    try {
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

      if (response.statusCode == 403) {
        final reason = response.body;
        throw Exception('BLOCKED:$reason');
      }

      if (response.statusCode == 401) {
        await _loginService.refreshAccessToken();
        token = await _loginService.getToken();

        response = await _makePostRequestWithToken(
          '$baseUrl/cancel-follower-request',
          body,
          signature,
          token,
        );

        if (response.statusCode == 403) {
          final reason = response.body;
          throw Exception('BLOCKED:$reason');
        }

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

  Future<void> updateFollowerStatus(int followedUserId, int followerUserId, String approvalStatus) async {
    final body = jsonEncode({
      'followed_user_id': followedUserId,
      'follower_user_id': followerUserId,
      'approval_status': approvalStatus,
    });

    try {
      if (!await _loginService.isLoggedIn()) {
        throw Exception("User not logged in.");
      }

      String? token = await _loginService.getToken();

      String dataToSign = '$followerUserId:$followedUserId:$approvalStatus';
      String signature = await _signatureService.generateHMAC(dataToSign);

      var response = await _makePutRequestWithToken(
        '$baseUrl/update-follower-status',
        body,
        signature,
        token,
      );

      if (response.statusCode == 403) {
        final reason = response.body;
        throw Exception('BLOCKED:$reason');
      }

      if (response.statusCode == 401) {
        await _loginService.refreshAccessToken();
        token = await _loginService.getToken();

        response = await _makePutRequestWithToken(
          '$baseUrl/update-follower-status',
          body,
          signature,
          token,
        );

        if (response.statusCode == 403) {
          final reason = response.body;
          throw Exception('BLOCKED:$reason');
        }

        if (response.statusCode == 401) {
          throw Exception('Session expired or refresh token invalid.');
        }
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to update follower status: ${response.body}');
      }
    } catch (e) {
      print('Error updating follower status: $e');
      throw e;
    }
  }

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

  Future<http.Response> _makePutRequestWithToken(
      String url, String body, String signature, String? token) async {
    return await http.put(
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
