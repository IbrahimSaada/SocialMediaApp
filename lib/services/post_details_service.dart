// services/post_details_service.dart

import 'dart:convert';
import 'package:cook/models/post_details_model.dart'; // Your custom model
import 'package:cook/services/apiService.dart';
import 'package:cook/services/SessionExpiredException.dart';

class PostDetailsService {
  // Base URL for fetching a single post by ID
  // e.g. GET https://<...>/api/Feed/Post/{postId}?userId={userId}
  static const String baseUrl =
      'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/Feed/Post';

  final ApiService _apiService = ApiService();

  /// Fetch details for a specific post
  /// - Backend expects signatureData = "{postId}:{userId}"
  Future<PostDetailsModel> fetchPostDetails({
    required int postId,
    required int userId,
  }) async {
    // Build the Uri: e.g. /Post/10?userId=5
    final Uri uri = Uri.parse('$baseUrl/$postId?userId=$userId');

    // Data to sign
    final String signatureData = '$postId:$userId';

    try {
      final response = await _apiService.makeRequestWithToken(
        uri,
        signatureData,
        'GET',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = jsonDecode(response.body);
        return PostDetailsModel.fromJson(jsonMap);
      } else if (response.statusCode == 401) {
        // The APIService typically refreshes token automatically,
        // so 401 here likely means session is truly expired
        throw Exception('Session expired or token invalid.');
      } else {
        print('Failed to fetch post details: ${response.statusCode}');
        print('Body: ${response.body}');
        throw Exception(
          'Failed to fetch post details: ${response.statusCode} ${response.body}',
        );
      }
    } on SessionExpiredException {
      // Bubble up session-expiration for the UI to handle
      rethrow;
    } catch (e) {
      print('Error fetching post details: $e');
      rethrow;
    }
  }
}
