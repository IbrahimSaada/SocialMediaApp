// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';
import '../models/LikeRequest_model.dart';
import 'LoginService.dart';
import 'SignatureService.dart';
import '../models/bookmarkrequest_model.dart';

class PostService {
  static const String apiUrl = 'https://81a7-185-97-92-20.ngrok-free.app/api/Posts';
  static final LoginService _loginService = LoginService();  // Static service
  static final SignatureService _signatureService = SignatureService();  // Static service

  // Fetch posts (requires JWT and signature)
  static Future<List<Post>> fetchPosts({required int userId}) async {
    try {
      // Ensure the user is logged in and get the JWT token
      if (!await _loginService.isLoggedIn()) {
        throw Exception("User not logged in.");
      }

      String? token = await _loginService.getToken();

      // Generate HMAC signature for the request
      String dataToSign = '$userId';  // Data to sign
      String signature = await _signatureService.generateHMAC(dataToSign);

      final response = await http.get(
        Uri.parse('$apiUrl?userId=$userId'),  // Query parameter
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',  // JWT token
          'X-Signature': signature,          // HMAC signature
        },
      );

      if (response.statusCode == 401) {
        print('JWT token is invalid or expired. Attempting to refresh token.');
        // Unauthorized, try refreshing the token
        try {
          await _loginService.refreshAccessToken();
          token = await _loginService.getToken();
          print('Token refreshed successfully.');

          // Retry the request after token refresh
          final retryResponse = await http.get(
            Uri.parse('$apiUrl?userId=$userId'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
              'X-Signature': signature,
            },
          );

          if (retryResponse.statusCode == 401) {
            // Token refresh failed, return an error
            throw Exception('Session expired or refresh token invalid.');
          } else if (retryResponse.statusCode == 200) {
            List<dynamic> data = json.decode(retryResponse.body);
            return data.map((json) => Post.fromJson(json)).toList();
          } else {
            throw Exception('Failed to load posts after token refresh.');
          }
        } catch (e) {
          print('Caught exception during token refresh: $e');
          throw Exception('Failed to refresh token: Invalid or expired refresh token.');
        }
      }

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load posts.');
      }
    } catch (e) {
      print("Error in fetchPosts: $e");
      rethrow;
    }
  }

  // Like a post (requires JWT and signature)
  static Future<void> likePost(LikeRequest likeRequest) async {
    try {
      // Ensure the user is logged in and get the JWT token
      if (!await _loginService.isLoggedIn()) {
        throw Exception("User not logged in.");
      }

      String? token = await _loginService.getToken();

      // Generate HMAC signature for the request
      String dataToSign = '${likeRequest.userId}:${likeRequest.postId}';
      String signature = await _signatureService.generateHMAC(dataToSign);

      final response = await http.post(
        Uri.parse('$apiUrl/Like'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',  // JWT token
          'X-Signature': signature,          // HMAC signature
        },
        body: jsonEncode(likeRequest.toJson()),
      );

      if (response.statusCode == 401) {
        print('JWT token is invalid or expired. Attempting to refresh token.');
        // Unauthorized, try refreshing the token
        try {
          await _loginService.refreshAccessToken();
          token = await _loginService.getToken();
          print('Token refreshed successfully.');

          // Retry the request after token refresh
          final retryResponse = await http.post(
            Uri.parse('$apiUrl/Like'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
              'X-Signature': signature,
            },
            body: jsonEncode(likeRequest.toJson()),
          );

          if (retryResponse.statusCode == 401) {
            // Token refresh failed, return an error
            throw Exception('Session expired or refresh token invalid.');
          } else if (retryResponse.statusCode != 200) {
            throw Exception('Failed to like post after token refresh.');
          }
        } catch (e) {
          print('Caught exception during token refresh: $e');
          throw Exception('Failed to refresh token: Invalid or expired refresh token.');
        }
      } else if (response.statusCode != 200) {
        throw Exception('Failed to like post.');
      }
    } catch (e) {
      print("Error in likePost: $e");
      rethrow;
    }
  }

  // Unlike a post (requires JWT and signature)
  static Future<void> unlikePost(LikeRequest likeRequest) async {
    try {
      // Ensure the user is logged in and get the JWT token
      if (!await _loginService.isLoggedIn()) {
        throw Exception("User not logged in.");
      }

      String? token = await _loginService.getToken();

      // Generate HMAC signature for the request
      String dataToSign = '${likeRequest.userId}:${likeRequest.postId}';
      String signature = await _signatureService.generateHMAC(dataToSign);

      final response = await http.post(
        Uri.parse('$apiUrl/Unlike'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',  // JWT token
          'X-Signature': signature,          // HMAC signature
        },
        body: jsonEncode(likeRequest.toJson()),
      );

      if (response.statusCode == 401) {
        print('JWT token is invalid or expired. Attempting to refresh token.');
        // Unauthorized, try refreshing the token
        try {
          await _loginService.refreshAccessToken();
          token = await _loginService.getToken();
          print('Token refreshed successfully.');

          // Retry the request after token refresh
          final retryResponse = await http.post(
            Uri.parse('$apiUrl/Unlike'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
              'X-Signature': signature,
            },
            body: jsonEncode(likeRequest.toJson()),
          );

          if (retryResponse.statusCode == 401) {
            // Token refresh failed, return an error
            throw Exception('Session expired or refresh token invalid.');
          } else if (retryResponse.statusCode != 200) {
            throw Exception('Failed to unlike post after token refresh.');
          }
        } catch (e) {
          print('Caught exception during token refresh: $e');
          throw Exception('Failed to refresh token: Invalid or expired refresh token.');
        }
      } else if (response.statusCode != 200) {
        throw Exception('Failed to unlike post.');
      }
    } catch (e) {
      print("Error in unlikePost: $e");
      rethrow;
    }
  }

  static Future<void> bookmarkPost(BookmarkRequest bookmarkRequest) async {
    try {
      String? token = await _loginService.getToken();
      String dataToSign = '${bookmarkRequest.userId}:${bookmarkRequest.postId}';
      String signature = await _signatureService.generateHMAC(dataToSign);

      final response = await http.post(
        Uri.parse('$apiUrl/Bookmark'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'X-Signature': signature,
        },
        body: jsonEncode(bookmarkRequest.toJson()),
      );

      if (response.statusCode == 401) {
        // Token is invalid or expired, attempt to refresh it
        await _loginService.refreshAccessToken();
        token = await _loginService.getToken();
        
        // Retry the request after refreshing the token
        final retryResponse = await http.post(
          Uri.parse('$apiUrl/Bookmark'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
            'X-Signature': signature,
          },
          body: jsonEncode(bookmarkRequest.toJson()),
        );

        if (retryResponse.statusCode != 200) {
          throw Exception('Failed to bookmark post after token refresh.');
        }
      } else if (response.statusCode != 200) {
        throw Exception('Failed to bookmark post.');
      }
    } catch (e) {
      print("Error in bookmarkPost: $e");
      rethrow; // Re-throw to handle it in the UI layer
    }
  }

  static Future<void> unbookmarkPost(BookmarkRequest bookmarkRequest) async {
    try {
      String? token = await _loginService.getToken();
      String dataToSign = '${bookmarkRequest.userId}:${bookmarkRequest.postId}';
      String signature = await _signatureService.generateHMAC(dataToSign);

      final response = await http.post(
        Uri.parse('$apiUrl/Unbookmark'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'X-Signature': signature,
        },
        body: jsonEncode(bookmarkRequest.toJson()),
      );

      if (response.statusCode == 401) {
        // Token is invalid or expired, attempt to refresh it
        await _loginService.refreshAccessToken();
        token = await _loginService.getToken();
        
        // Retry the request after refreshing the token
        final retryResponse = await http.post(
          Uri.parse('$apiUrl/Unbookmark'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
            'X-Signature': signature,
          },
          body: jsonEncode(bookmarkRequest.toJson()),
        );

        if (retryResponse.statusCode != 200) {
          throw Exception('Failed to unbookmark post after token refresh.');
        }
      } else if (response.statusCode != 200) {
        throw Exception('Failed to unbookmark post.');
      }
    } catch (e) {
      print("Error in unbookmarkPost: $e");
      rethrow; // Re-throw to handle it in the UI layer
    }
  }
}
