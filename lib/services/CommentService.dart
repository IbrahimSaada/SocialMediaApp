// services/CommentService.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/comment_request_model.dart';
import '../models/comment_model.dart';
import 'LoginService.dart';
import 'SessionExpiredException.dart';
import 'SignatureService.dart';
import 'apiService.dart';

class CommentService {
  static const String apiUrl = '***REMOVED***/api/Posts';
  static final LoginService _loginService = LoginService();
  static final SignatureService _signatureService = SignatureService();

static Future<void> postComment(CommentRequest commentRequest) async {
  final Uri url = Uri.parse('$apiUrl/${commentRequest.postId}/Commenting');
  final String signatureData = '${commentRequest.userId}:${commentRequest.postId}:${commentRequest.text}';

  try {
    final response = await ApiService().makeRequestWithToken(
      url,
      signatureData,
      'POST',
      body: commentRequest.toJson(),
    );

    if (response.statusCode == 403) {
      final reason = response.body;
      throw Exception('BLOCKED:$reason');
    }

    if (response.statusCode != 201) {
      final responseBody = jsonDecode(response.body);
      final errorDetails = responseBody['error'] ?? responseBody['message'] ?? 'Unknown error';
      throw Exception('Failed to post comment: $errorDetails');
    }
  } on SessionExpiredException {
    // If session expired, rethrow for the caller to handle
    rethrow;
  } catch (e) {
    // Any other error is rethrown
    rethrow;
  }
}

// fetchComments
static Future<List<Comment>> fetchComments(int postId) async {
  final Uri url = Uri.parse('$apiUrl/$postId/Comments');
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
      List<dynamic> data = jsonDecode(response.body);
      return data.map((commentJson) => Comment.fromJson(commentJson)).toList();
    } else {
      throw Exception('Failed to load comments: ${response.statusCode}');
    }
  } on SessionExpiredException {
    rethrow;
  } catch (e) {
    rethrow;
  }
}

// editComment
static Future<void> editComment(CommentRequest commentRequest, int commentId) async {
  final Uri url = Uri.parse('$apiUrl/${commentRequest.postId}/Comments/$commentId');
  final String signatureData = '${commentRequest.userId}:${commentRequest.postId}:${commentRequest.text}';

  try {
    final response = await ApiService().makeRequestWithToken(
      url,
      signatureData,
      'PUT',
      body: commentRequest.toJson(),
    );

    if (response.statusCode == 403) {
      final reason = response.body;
      throw Exception('BLOCKED:$reason');
    }

    if (response.statusCode != 200) {
      final responseBody = jsonDecode(response.body);
      final errorDetails = responseBody['error'] ?? responseBody['message'] ?? 'Unknown error';
      throw Exception('Failed to edit comment: $errorDetails');
    }
  } on SessionExpiredException {
    rethrow;
  } catch (e) {
    rethrow;
  }
}

// deleteComment
static Future<void> deleteComment(int postId, int commentId, int userId) async {
  final Uri url = Uri.parse('$apiUrl/$postId/Comments/$commentId?userId=$userId');
  final String signatureData = '$userId:$postId:$commentId';

  try {
    final response = await ApiService().makeRequestWithToken(
      url,
      signatureData,
      'DELETE',
    );

    if (response.statusCode == 403) {
      final reason = response.body;
      throw Exception('BLOCKED:$reason');
    }

    if (response.statusCode != 200) {
      final responseBody = jsonDecode(response.body);
      final errorDetails = responseBody['error'] ?? responseBody['message'] ?? 'Unknown error';
      throw Exception('Failed to delete comment: $errorDetails');
    }
  } on SessionExpiredException {
    rethrow;
  } catch (e) {
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
          await _loginService.refreshAccessToken();
          token = await _loginService.getToken();

        final retryResponse = await http.get(
          Uri.parse(url),
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
          List<dynamic> data = jsonDecode(retryResponse.body);
          return data.map((commentJson) => Comment.fromJson(commentJson)).toList();
        } else {
          throw Exception('Failed to load comment threads after token refresh.');
        }
      }

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((commentJson) => Comment.fromJson(commentJson)).toList();
      } else {
        throw Exception('Failed to load comment threads.');
      }
    } catch (e) {
      rethrow;
    }
  }
}
