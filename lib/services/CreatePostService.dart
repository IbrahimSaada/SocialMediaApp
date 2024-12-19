import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cook/models/post_request.dart';
import 'package:cook/services/apiService.dart';
import 'package:cook/services/SessionExpiredException.dart';

class PostService {
  final String _createPostUrl = 'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/CreatePost';
  final ApiService _apiService = ApiService();

  PostService();

  Future<void> createPost(PostRequest postRequest) async {
    // Prepare data to sign
    String dataToSign = '${postRequest.userId}:${postRequest.caption}:${postRequest.isPublic}';

    try {
      // Use ApiService to make the request
      final response = await _apiService.makeRequestWithToken(
        Uri.parse(_createPostUrl),
        dataToSign,
        'POST',
        body: postRequest.toJson(),
      );

      // Handle the response
      if (response.statusCode == 201) {
        print('Post created successfully.');
      } else if (response.statusCode == 401) {
        // Token was invalid and could not be refreshed in ApiService
        throw Exception('Failed to create post due to 401 Unauthorized.');
      } else {
        print('Failed to create post: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to create post.');
      }
    } on SessionExpiredException {
      // Propagate the session expired exception for the caller to handle
      rethrow;
    } catch (e) {
      print('Error in createPost: $e');
      rethrow;
    }
  }
}
