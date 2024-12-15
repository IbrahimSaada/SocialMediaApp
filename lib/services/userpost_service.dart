import 'dart:convert';
import 'blocked_user_exception.dart';
import '../models/post_model.dart';
import '../models/sharedpost_model.dart';
import 'SessionExpiredException.dart';
import 'apiService.dart';

class PrivacyException implements Exception {
  final String message;
  PrivacyException(this.message);

  @override
  String toString() => 'PrivacyException: $message';
}

class UserpostService {
  static const String baseUrl = 'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api';
  final ApiService _apiService = ApiService();

  Future<List<Post>> fetchUserPosts(int currentUserId, int viewerUserId, int pageNumber, int pageSize) async {
    final Uri url = Uri.parse('$baseUrl/UserProfile/userposts?userId=$currentUserId&viewerUserId=$viewerUserId&pageNumber=$pageNumber&pageSize=$pageSize');
    final String signatureData = '$currentUserId:$viewerUserId:$pageNumber:$pageSize';

    try {
      print("Calling user posts API: $url");
      final response = await _apiService.makeRequestWithToken(url, signatureData, 'GET');

      print("User posts API response status: ${response.statusCode}");
      print("User posts API response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Post.fromJson(json)).toList();
      } else if (response.statusCode == 204) {
        return [];
      } else if (response.statusCode == 403) {
        // Try to parse as JSON first
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          final isBlockedBy = jsonData['blockedBy'] as bool? ?? false;
          final isUserBlocked = jsonData['blockedUser'] as bool? ?? false;
          if (isBlockedBy || isUserBlocked) {
            throw BlockedUserException(
              reason: jsonData['message'],
              isBlockedBy: isBlockedBy,
              isUserBlocked: isUserBlocked,
            );
          } else {
            throw PrivacyException(jsonData['message'] ?? 'This account is private.');
          }
        } catch (e) {
          // If parsing fails, use raw text as message
          throw PrivacyException(response.body);
        }
      } else if (response.statusCode == 404) {
        throw Exception('No posts found for this user.');
      } else {
        throw Exception('Failed to load user posts');
      }
    } on SessionExpiredException {
      print('SessionExpired detected in fetchUserPosts');
      rethrow;
    }
  }

  Future<List<Post>> fetchBookmarkedPosts(int userId, int pageNumber, int pageSize) async {
    final Uri url = Uri.parse('$baseUrl/UserProfile/bookmarked?userId=$userId&pageNumber=$pageNumber&pageSize=$pageSize');
    final String signatureData = '$userId:$pageNumber:$pageSize';

    try {
      print("Calling bookmarked posts API: $url");
      final response = await _apiService.makeRequestWithToken(url, signatureData, 'GET');

      print("Bookmarked posts API response status: ${response.statusCode}");
      print("Bookmarked posts API response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load bookmarked posts');
      }
    } on SessionExpiredException {
      print('SessionExpired detected in fetchBookmarkedPosts');
      rethrow;
    } catch (e) {
      print('Error fetching bookmarked posts: $e');
      throw Exception('Failed to load bookmarked posts');
    }
  }

  Future<List<SharedPostDetails>> fetchSharedPosts(int currentUserId, int viewerUserId, int pageNumber, int pageSize) async {
    final Uri url = Uri.parse('$baseUrl/UserProfile/sharedposts/$currentUserId?viewerUserId=$viewerUserId&pageNumber=$pageNumber&pageSize=$pageSize');
    final String signatureData = '$currentUserId:$viewerUserId:$pageNumber:$pageSize';

    try {
      print("Calling shared posts API: $url");
      final response = await _apiService.makeRequestWithToken(url, signatureData, 'GET');

      print("Shared posts API response status: ${response.statusCode}");
      print("Shared posts API response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => SharedPostDetails.fromJson(json)).toList();
      } else if (response.statusCode == 204) {
        return [];
      } else if (response.statusCode == 403) {
        // Try to parse as JSON first
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          final isBlockedBy = jsonData['blockedBy'] as bool? ?? false;
          final isUserBlocked = jsonData['blockedUser'] as bool? ?? false;
          if (isBlockedBy || isUserBlocked) {
            throw BlockedUserException(
              reason: jsonData['message'],
              isBlockedBy: isBlockedBy,
              isUserBlocked: isUserBlocked,
            );
          } else {
            throw PrivacyException(jsonData['message'] ?? 'This account is private.');
          }
        } catch (e) {
          // If parsing fails, use raw text as message
          throw PrivacyException(response.body);
        }
      } else if (response.statusCode == 404) {
        throw Exception('No shared posts found for this user.');
      } else if (response.statusCode == 401) {
        throw SessionExpiredException('Session expired. Please log in again.');
      } else {
        throw Exception('Failed to load shared posts');
      }
    } on SessionExpiredException {
      print('SessionExpired detected in fetchSharedPosts');
      rethrow;
    }
  }
}
