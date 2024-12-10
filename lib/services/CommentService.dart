// services/CommentService.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/comment_request_model.dart';
import '../models/comment_model.dart';
import 'LoginService.dart';
import 'SignatureService.dart';

class CommentService {
  static const String apiUrl = '***REMOVED***/api/Posts';
  static final LoginService _loginService = LoginService();
  static final SignatureService _signatureService = SignatureService();

  // Existing methods...

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
          'Authorization': 'Bearer $token',
          'X-Signature': signature,
        },
        body: jsonEncode(commentRequest.toJson()),
      );

      if (response.statusCode == 401) {
        print('JWT token is invalid or expired. Attempting to refresh token.');
        try {
          await _loginService.refreshAccessToken();
          token = await _loginService.getToken();
          print('Token refreshed successfully.');

          final retryResponse = await http.post(
            Uri.parse('$apiUrl/${commentRequest.postId}/Commenting'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
              'X-Signature': signature,
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
        final errorDetails = responseBody['error'] ?? responseBody['message'] ?? 'Unknown error';
        throw Exception('Failed to post comment: $errorDetails');
      }
    } catch (e) {
      print('Error in postComment: $e');
      rethrow;
    }
  }

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
          'Authorization': 'Bearer $token',
          'X-Signature': signature,
        },
      );

      if (response.statusCode == 401) {
        print('JWT token is invalid or expired. Attempting to refresh token.');
        try {
          await _loginService.refreshAccessToken();
          token = await _loginService.getToken();
          print('Token refreshed successfully.');

          final retryResponse = await http.get(
            Uri.parse('$apiUrl/$postId/Comments'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
              'X-Signature': signature,
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
          'Authorization': 'Bearer $token',
          'X-Signature': signature,
        },
        body: jsonEncode(commentRequest.toJson()),
      );

      if (response.statusCode == 401) {
        print('JWT token is invalid or expired. Attempting to refresh token.');
        try {
          await _loginService.refreshAccessToken();
          token = await _loginService.getToken();
          print('Token refreshed successfully.');

          final retryResponse = await http.put(
            Uri.parse('$apiUrl/${commentRequest.postId}/Comments/$commentId'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
              'X-Signature': signature,
            },
            body: jsonEncode(commentRequest.toJson()),
          );

          if (retryResponse.statusCode == 401) {
            throw Exception('Session expired or refresh token invalid.');
          } else if (retryResponse.statusCode != 200) {
            final responseBody = jsonDecode(retryResponse.body);
            final errorDetails = responseBody['error'] ?? responseBody['message'] ?? 'Unknown error';
            throw Exception('Failed to edit comment: $errorDetails');
          }
        } catch (e) {
          print('Caught exception during token refresh: $e');
          throw Exception('Failed to refresh token: Invalid or expired refresh token.');
        }
      } else if (response.statusCode != 200) {
        final responseBody = jsonDecode(response.body);
        final errorDetails = responseBody['error'] ?? responseBody['message'] ?? 'Unknown error';
        throw Exception('Failed to edit comment: $errorDetails');
      }
    } catch (e) {
      print('Error in editComment: $e');
      rethrow;
    }
  }

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
          'Authorization': 'Bearer $token',
          'X-Signature': signature,
        },
      );

      if (response.statusCode == 401) {
        print('JWT token is invalid or expired. Attempting to refresh token.');
        try {
          await _loginService.refreshAccessToken();
          token = await _loginService.getToken();
          print('Token refreshed successfully.');

          final retryResponse = await http.delete(
            Uri.parse('$apiUrl/$postId/Comments/$commentId?userId=$userId'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
              'X-Signature': signature,
            },
          );

          if (retryResponse.statusCode == 401) {
            throw Exception('Session expired or refresh token invalid.');
          } else if (retryResponse.statusCode != 200) {
            final responseBody = jsonDecode(retryResponse.body);
            final errorDetails = responseBody['error'] ?? responseBody['message'] ?? 'Unknown error';
            throw Exception('Failed to delete comment: $errorDetails');
          }
        } catch (e) {
          print('Caught exception during token refresh: $e');
          throw Exception('Failed to refresh token: Invalid or expired refresh token.');
        }
      } else if (response.statusCode != 200) {
        final responseBody = jsonDecode(response.body);
        final errorDetails = responseBody['error'] ?? responseBody['message'] ?? 'Unknown error';
        throw Exception('Failed to delete comment: $errorDetails');
      }
    } catch (e) {
      print('Error in deleteComment: $e');
      rethrow;
    }
  }

  static Future<List<Comment>> fetchCommentThreads(int postId, List<int> commentIds) async {
    try {
      if (!await _loginService.isLoggedIn()) {
        throw Exception("User not logged in.");
      }

      String? token = await _loginService.getToken();
      String idsParam = commentIds.join(',');
      String dataToSign = idsParam;
      String signature = await _signatureService.generateHMAC(dataToSign);

      final url = '$apiUrl/$postId/Comments/Threads?ids=$idsParam';

      final response = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'X-Signature': signature,
        },
      );

      if (response.statusCode == 401) {
        print('JWT token is invalid or expired. Attempting to refresh token.');
        try {
          await _loginService.refreshAccessToken();
          token = await _loginService.getToken();
          print('Token refreshed successfully.');

          final retryResponse = await http.get(
            Uri.parse(url),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
              'X-Signature': signature,
            },
          );

          if (retryResponse.statusCode == 401) {
            throw Exception('Session expired or refresh token invalid.');
          } else if (retryResponse.statusCode == 200) {
            List<dynamic> data = jsonDecode(retryResponse.body);
            return data.map((commentJson) => Comment.fromJson(commentJson)).toList();
          } else {
            throw Exception('Failed to load comment threads after token refresh.');
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
        throw Exception('Failed to load comment threads.');
      }
    } catch (e) {
      print('Error in fetchCommentThreads: $e');
      rethrow;
    }
  }
}
