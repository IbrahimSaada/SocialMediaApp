// ignore_for_file: avoid_print

import 'dart:convert';
import '../models/LikeRequest_model.dart';
import '../models/user_like.dart';
import 'SessionExpiredException.dart';
import '../models/bookmarkrequest_model.dart';
import 'apiService.dart';

class PostService {
  static const String apiUrl = 'your-backend-server/api/Posts';

  // Like a post
static Future<void> likePost(LikeRequest likeRequest) async {
  final Uri url = Uri.parse('$apiUrl/Like');
  final String signatureData = '${likeRequest.userId}:${likeRequest.postId}';

  try {
    final response = await ApiService().makeRequestWithToken(
      url,
      signatureData,
      'POST',
      body: likeRequest.toJson(),
    );

    if (response.statusCode == 403) {
      final reason = response.body;
      throw Exception('BLOCKED:$reason');
    }

    if (response.statusCode == 401) {
      // If we reach this point, token refresh logic didn't resolve the issue.
      throw Exception('Session expired or refresh token invalid.');
    } else if (response.statusCode != 200) {
      throw Exception('Failed to like post.');
    }
  } on SessionExpiredException {
    // This exception is thrown by ApiService if refreshing the token fails.
    print("SessionExpired detected in likePost.");
    rethrow;
  } catch (e) {
    print("Error in likePost: $e");
    rethrow;
  }
}

  // Unlike a post
static Future<void> unlikePost(LikeRequest likeRequest) async {
  final Uri url = Uri.parse('$apiUrl/Unlike');
  final String signatureData = '${likeRequest.userId}:${likeRequest.postId}';

  try {
    final response = await ApiService().makeRequestWithToken(
      url,
      signatureData,
      'POST',
      body: likeRequest.toJson(),
    );

    if (response.statusCode == 403) {
      final reason = response.body;
      throw Exception('BLOCKED:$reason');
    }

    if (response.statusCode == 401) {
      // If we get here, the token refresh logic in ApiService didn't fix the issue.
      throw Exception('Session expired or refresh token invalid.');
    } else if (response.statusCode != 200) {
      throw Exception('Failed to unlike post.');
    }
  } on SessionExpiredException {
    print("SessionExpired detected in unlikePost.");
    rethrow;
  } catch (e) {
    print("Error in unlikePost: $e");
    rethrow;
  }
}

// Bookmark post
static Future<void> bookmarkPost(BookmarkRequest bookmarkRequest) async {
  final Uri url = Uri.parse('$apiUrl/Bookmark');
  final String signatureData = '${bookmarkRequest.userId}:${bookmarkRequest.postId}';

  try {
    final response = await ApiService().makeRequestWithToken(
      url,
      signatureData,
      'POST',
      body: bookmarkRequest.toJson(),
    );

    if (response.statusCode == 403) {
      final reason = response.body;
      throw Exception('BLOCKED:$reason');
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to bookmark post.');
    }
  } on SessionExpiredException {
    rethrow;
  } catch (e) {
    print("Error in bookmarkPost: $e");
    rethrow;
  }
}

// Unbookmark post
static Future<void> unbookmarkPost(BookmarkRequest bookmarkRequest) async {
  final Uri url = Uri.parse('$apiUrl/Unbookmark');
  final String signatureData = '${bookmarkRequest.userId}:${bookmarkRequest.postId}';

  try {
    final response = await ApiService().makeRequestWithToken(
      url,
      signatureData,
      'POST',
      body: bookmarkRequest.toJson(),
    );

    if (response.statusCode == 403) {
      final reason = response.body;
      throw Exception('BLOCKED:$reason');
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to unbookmark post.');
    }
  } on SessionExpiredException {
    rethrow;
  } catch (e) {
    print("Error in unbookmarkPost: $e");
    rethrow;
  }
}

// Fetch post likes
static Future<List<UserLike>> fetchPostLikes(int postId) async {
  final Uri url = Uri.parse('$apiUrl/$postId/Likes');
  final String signatureData = '$postId';

  try {
    final response = await ApiService().makeRequestWithToken(
      url,
      signatureData,
      'GET',
    );

    if (response.statusCode == 403) {
      final reason = response.body;
      throw Exception('BLOCKED:$reason');
    }

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => UserLike.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load post likes.');
    }
  } on SessionExpiredException {
    rethrow;
  } catch (e) {
    print("Error in fetchPostLikes: $e");
    rethrow;
  }
}
}
