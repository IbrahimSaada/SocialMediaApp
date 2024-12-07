
// ignore_for_file: file_names, avoid_print, duplicate_ignore

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/comment_request_model.dart';
import '../models/comment_model.dart';
import 'LoginService.dart';
import 'SignatureService.dart';

class CommentService {
  static const String apiUrl = '***REMOVED***/api/Posts';
  static final LoginService _loginService = LoginService();  // Static service for token management
  static final SignatureService _signatureService = SignatureService();  // Static service for HMAC signatures

  // Post a comment (requires JWT and signature)
  static Future<void> postComment(CommentRequest commentRequest) async {
    try {
      if (!await _loginService.isLoggedIn()) {
        throw Exception("User not logged in.");
      }

      String? token = await _loginService.getToken();
      String dataToSign = '${commentRequest.userId}:${commentRequest.postId}:${commentRequest.text}';
      String signature = await _signatureService.generateHMAC(dataToSign);

      final response = await http.post(
        Uri.parse('$apiUrl/${commentRequest.postId}/Commenting'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',  // JWT token
          'X-Signature': signature,          // HMAC signature
        },
        body: jsonEncode(commentRequest.toJson()),
      );

      if (response.statusCode == 401) {
        // Token expired or invalid, try to refresh it
        // ignore: avoid_print
        print('JWT token is invalid or expired. Attempting to refresh token.');
        try {
          await _loginService.refreshAccessToken();
          token = await _loginService.getToken();
          // ignore: avoid_print
          print('Token refreshed successfully.');

          // Retry the request with the refreshed token
          final retryResponse = await http.post(
            Uri.parse('$apiUrl/${commentRequest.postId}/Commenting'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',  // JWT token
              'X-Signature': signature,          // HMAC signature
            },
            body: jsonEncode(commentRequest.toJson()),
          );

          if (retryResponse.statusCode == 401) {
            throw Exception('Session expired or refresh token invalid.');
          } else if (retryResponse.statusCode != 201) {
            throw Exception('Failed to post comment after token refresh.');
          }
        } catch (e) {
          print('Caught exception during token refresh: $e');
          throw Exception('Failed to refresh token: Invalid or expired refresh token.');
        }
      } else if (response.statusCode != 201) {
        final responseBody = jsonDecode(response.body);
        final errorDetails =
            responseBody['error'] ?? responseBody['message'] ?? 'Unknown error';
        throw Exception('Failed to post comment: $errorDetails');
      }
    } catch (e) {
      print('Error in postComment: $e');
      rethrow;
    }
  }

  // Fetch comments (requires JWT and signature)
  static Future<List<Comment>> fetchComments(int postId) async {
    try {
      if (!await _loginService.isLoggedIn()) {
        throw Exception("User not logged in.");
      }

      String? token = await _loginService.getToken();
      String dataToSign = '$postId';
      String signature = await _signatureService.generateHMAC(dataToSign);

      final response = await http.get(
        Uri.parse('$apiUrl/$postId/Comments'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',  // JWT token
          'X-Signature': signature,          // HMAC signature
        },
      );

      if (response.statusCode == 401) {
        print('JWT token is invalid or expired. Attempting to refresh token.');
        try {
          await _loginService.refreshAccessToken();
          token = await _loginService.getToken();
          print('Token refreshed successfully.');

          // Retry the request with the refreshed token
          final retryResponse = await http.get(
            Uri.parse('$apiUrl/$postId/Comments'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',  // JWT token
              'X-Signature': signature,          // HMAC signature
            },
          );

          if (retryResponse.statusCode == 401) {
            throw Exception('Session expired or refresh token invalid.');
          } else if (retryResponse.statusCode == 200) {
            List<dynamic> data = jsonDecode(retryResponse.body);
            return data.map((commentJson) => Comment.fromJson(commentJson)).toList();
          } else {
            throw Exception('Failed to load comments after token refresh.');
          }
        } catch (e) {
          print('Caught exception during token refresh: $e');
          throw Exception('Failed to refresh token: Invalid or expired refresh token.');
        }
      }

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((commentJson) => Comment.fromJson(commentJson)).toList();
      } else {
        throw Exception('Failed to load comments.');
      }
    } catch (e) {
      print('Error in fetchComments: $e');
      rethrow;
    }
  }

  // Edit a comment (requires JWT and signature)
  static Future<void> editComment(CommentRequest commentRequest, int commentId) async {
    try {
      if (!await _loginService.isLoggedIn()) {
        throw Exception("User not logged in.");
      }

      String? token = await _loginService.getToken();
      String dataToSign = '${commentRequest.userId}:${commentRequest.postId}:${commentRequest.text}';
      String signature = await _signatureService.generateHMAC(dataToSign);

      final response = await http.put(
        Uri.parse('$apiUrl/${commentRequest.postId}/Comments/$commentId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',  // JWT token
          'X-Signature': signature,          // HMAC signature
        },
        body: jsonEncode(commentRequest.toJson()),
      );

      if (response.statusCode == 401) {
        print('JWT token is invalid or expired. Attempting to refresh token.');
        try {
          await _loginService.refreshAccessToken();
          token = await _loginService.getToken();
          print('Token refreshed successfully.');

          // Retry the request with the refreshed token
          final retryResponse = await http.put(
            Uri.parse('$apiUrl/${commentRequest.postId}/Comments/$commentId'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',  // JWT token
              'X-Signature': signature,          // HMAC signature
            },
            body: jsonEncode(commentRequest.toJson()),
          );

          if (retryResponse.statusCode == 401) {
            throw Exception('Session expired or refresh token invalid.');
          } else if (retryResponse.statusCode != 200) {
            throw Exception('Failed to edit comment after token refresh.');
          }
        } catch (e) {
          print('Caught exception during token refresh: $e');
          throw Exception('Failed to refresh token: Invalid or expired refresh token.');
        }
      } else if (response.statusCode != 200) {
        final responseBody = jsonDecode(response.body);
        final errorDetails =
            responseBody['error'] ?? responseBody['message'] ?? 'Unknown error';
        throw Exception('Failed to edit comment: $errorDetails');
      }
    } catch (e) {
      print('Error in editComment: $e');
      rethrow;
    }
  }

  // Delete a comment (requires JWT and signature)
  static Future<void> deleteComment(int postId, int commentId, int userId) async {
    try {
      if (!await _loginService.isLoggedIn()) {
        throw Exception("User not logged in.");
      }

      String? token = await _loginService.getToken();
      String dataToSign = '$userId:$postId:$commentId';
      String signature = await _signatureService.generateHMAC(dataToSign);

      final response = await http.delete(
        Uri.parse('$apiUrl/$postId/Comments/$commentId?userId=$userId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',  // JWT token
          'X-Signature': signature,          // HMAC signature
        },
      );

      if (response.statusCode == 401) {
        print('JWT token is invalid or expired. Attempting to refresh token.');
        try {
          await _loginService.refreshAccessToken();
          token = await _loginService.getToken();
          print('Token refreshed successfully.');

          // Retry the request with the refreshed token
          final retryResponse = await http.delete(
            Uri.parse('$apiUrl/$postId/Comments/$commentId?userId=$userId'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',  // JWT token
              'X-Signature': signature,          // HMAC signature
            },
          );

          if (retryResponse.statusCode == 401) {
            throw Exception('Session expired or refresh token invalid.');
          } else if (retryResponse.statusCode != 200) {
            throw Exception('Failed to delete comment after token refresh.');
          }
        } catch (e) {
          print('Caught exception during token refresh: $e');
          throw Exception('Failed to refresh token: Invalid or expired refresh token.');
        }
      } else if (response.statusCode != 200) {
        final responseBody = jsonDecode(response.body);
        final errorDetails =
            responseBody['error'] ?? responseBody['message'] ?? 'Unknown error';
        throw Exception('Failed to delete comment: $errorDetails');
      }
    } catch (e) {
      print('Error in deleteComment: $e');
      rethrow;
    }
  }
 // Fetch a specific comment thread (requires JWT)
  static Future<Comment> fetchCommentThread(int postId, int commentId) async {
    try {
      if (!await _loginService.isLoggedIn()) {
        throw Exception("User not logged in.");
      }

      String? token = await _loginService.getToken();

      final response = await http.get(
        Uri.parse('$apiUrl/$postId/Comments/$commentId/Thread'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token', // JWT token
        },
      );

      if (response.statusCode == 401) {
        print('JWT token is invalid or expired. Attempting to refresh token.');
        try {
          await _loginService.refreshAccessToken();
          token = await _loginService.getToken();
          print('Token refreshed successfully.');

          // Retry the request with the refreshed token
          final retryResponse = await http.get(
            Uri.parse('$apiUrl/$postId/Comments/$commentId/Thread'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token', // JWT token
            },
          );

          if (retryResponse.statusCode == 401) {
            throw Exception('Session expired or refresh token invalid.');
          } else if (retryResponse.statusCode == 200) {
            Map<String, dynamic> data = jsonDecode(retryResponse.body);
            return Comment.fromJson(data);
          } else {
            throw Exception('Failed to load comment thread after token refresh.');
          }
        } catch (e) {
          print('Caught exception during token refresh: $e');
          throw Exception('Failed to refresh token: Invalid or expired refresh token.');
        }
      }

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        return Comment.fromJson(data);
      } else {
        throw Exception('Failed to load comment thread.');
      }
    } catch (e) {
      print('Error in fetchCommentThread: $e');
      rethrow;
    }
  }
}
