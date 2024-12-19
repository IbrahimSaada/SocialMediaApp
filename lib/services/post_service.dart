// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';
import '../models/LikeRequest_model.dart';
import '../models/user_like.dart';
import 'LoginService.dart';
import 'SessionExpiredException.dart';
import 'SignatureService.dart';
import '../models/bookmarkrequest_model.dart';
import 'apiService.dart';

class PostService {
  static const String apiUrl = 'https://3687-185-97-92-30.ngrok-free.app/api/Posts';
  static final LoginService _loginService = LoginService(); 
  static final SignatureService _signatureService = SignatureService();

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
    try {
      String? token = await _loginService.getToken();
      String dataToSign = '${bookmarkRequest.userId}:${bookmarkRequest.postId}';
      String signature = await _signatureService.generateHMAC(dataToSign);

      final response = await http.post(
        Uri.parse('$apiUrl/Bookmark'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'X-Signature': signature,
        },
        body: jsonEncode(bookmarkRequest.toJson()),
      );

      if (response.statusCode == 403) {
        final reason = response.body;
        throw Exception('BLOCKED:$reason');
      }

      if (response.statusCode == 401) {
        await _loginService.refreshAccessToken();
        token = await _loginService.getToken();

        final retryResponse = await http.post(
          Uri.parse('$apiUrl/Bookmark'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
            'X-Signature': signature,
          },
          body: jsonEncode(bookmarkRequest.toJson()),
        );

        if (retryResponse.statusCode == 403) {
          final reason = retryResponse.body;
          throw Exception('BLOCKED:$reason');
        }

        if (retryResponse.statusCode != 200) {
          throw Exception('Failed to bookmark post after token refresh.');
        }
      } else if (response.statusCode != 200) {
        throw Exception('Failed to bookmark post.');
      }
    } catch (e) {
      print("Error in bookmarkPost: $e");
      rethrow;
    }
  }

  // Unbookmark post
  static Future<void> unbookmarkPost(BookmarkRequest bookmarkRequest) async {
    try {
      String? token = await _loginService.getToken();
      String dataToSign = '${bookmarkRequest.userId}:${bookmarkRequest.postId}';
      String signature = await _signatureService.generateHMAC(dataToSign);

      final response = await http.post(
        Uri.parse('$apiUrl/Unbookmark'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'X-Signature': signature,
        },
        body: jsonEncode(bookmarkRequest.toJson()),
      );

      if (response.statusCode == 403) {
        final reason = response.body;
        throw Exception('BLOCKED:$reason');
      }

      if (response.statusCode == 401) {
        await _loginService.refreshAccessToken();
        token = await _loginService.getToken();

        final retryResponse = await http.post(
          Uri.parse('$apiUrl/Unbookmark'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
            'X-Signature': signature,
          },
          body: jsonEncode(bookmarkRequest.toJson()),
        );

        if (retryResponse.statusCode == 403) {
          final reason = retryResponse.body;
          throw Exception('BLOCKED:$reason');
        }

        if (retryResponse.statusCode != 200) {
          throw Exception('Failed to unbookmark post after token refresh.');
        }
      } else if (response.statusCode != 200) {
        throw Exception('Failed to unbookmark post.');
      }
    } catch (e) {
      print("Error in unbookmarkPost: $e");
      rethrow;
    }
  }

  // Fetch post likes
  static Future<List<UserLike>> fetchPostLikes(int postId) async {
    try {
      if (!await _loginService.isLoggedIn()) {
        throw Exception("User not logged in.");
      }

      String? token = await _loginService.getToken();
      String dataToSign = '$postId';
      String signature = await _signatureService.generateHMAC(dataToSign);

      final response = await http.get(
        Uri.parse('$apiUrl/$postId/Likes'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'X-Signature': signature,
        },
      );

      if (response.statusCode == 403) {
        final reason = response.body;
        throw Exception('BLOCKED:$reason');
      }

      if (response.statusCode == 401) {
        print('JWT token is invalid or expired. Attempting to refresh token.');
        await _loginService.refreshAccessToken();
        token = await _loginService.getToken();
        print('Token refreshed successfully.');

        final retryResponse = await http.get(
          Uri.parse('$apiUrl/$postId/Likes'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
            'X-Signature': signature,
          },
        );

        if (retryResponse.statusCode == 403) {
          final reason = retryResponse.body;
          throw Exception('BLOCKED:$reason');
        }

        if (retryResponse.statusCode == 401) {
          throw Exception('Session expired or refresh token invalid.');
        } else if (retryResponse.statusCode == 200) {
          List<dynamic> data = json.decode(retryResponse.body);
          return data.map((json) => UserLike.fromJson(json)).toList();
        } else {
          throw Exception('Failed to load post likes after token refresh.');
        }
      }

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => UserLike.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load post likes.');
      }
    } catch (e) {
      print("Error in fetchPostLikes: $e");
      rethrow;
    }
  }
}
