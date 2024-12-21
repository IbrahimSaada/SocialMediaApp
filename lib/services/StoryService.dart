// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:cook/models/story_model.dart';
import 'package:cook/models/story_request_model.dart';
import 'package:cook/services/apiService.dart';
import 'package:cook/services/SessionExpiredException.dart';

class StoryService {
  // Define the base URLs for GET and POST requests
  final String getUrl =
      'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/Stories/user/';
  final String postUrl =
      'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/Stories';

  final ApiService _apiService = ApiService();

  /// Fetch stories (GET)
  Future<List<Story>> fetchStories(int userId) async {
    final String fullUrl = '$getUrl$userId';

    // This is the data that needs to be signed
    final String signatureData = '$userId';

    try {
      // Make GET request using ApiService
      final response = await _apiService.makeRequestWithToken(
        Uri.parse(fullUrl),
        signatureData,
        'GET',
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((item) => Story.fromJson(item)).toList();
      } else {
        print('Failed to load stories. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load stories.');
      }
    } on SessionExpiredException {
      // Let the caller handle session expiration
      rethrow;
    } catch (e) {
      print('Error fetching stories: $e');
      rethrow;
    }
  }

  /// Create a story (POST)
  Future<void> createStory(StoryRequest storyRequest) async {
    // Data to sign: userId plus a comma-separated list of media URLs
    final String signatureData =
        '${storyRequest.userId}:${storyRequest.media.map((m) => m.mediaUrl).join(",")}';

    try {
      // Make POST request using ApiService
      final response = await _apiService.makeRequestWithToken(
        Uri.parse(postUrl),
        signatureData,
        'POST',
        body: storyRequest.toJson(),
      );

      if (response.statusCode == 201) {
        print('Story created successfully');
      } else {
        print('Failed to create story. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to create story.');
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      print('Error creating story: $e');
      rethrow;
    }
  }

  /// Delete a story media (DELETE)
  Future<bool> deleteStoryMedia(int storyMediaId, int userId) async {
    // Data to sign: storyMediaId:userId
    final String signatureData = '$storyMediaId:$userId';
    final String url = '$postUrl/Media/$storyMediaId/$userId';

    try {
      final response = await _apiService.makeRequestWithToken(
        Uri.parse(url),
        signatureData,
        'DELETE',
      );

      if (response.statusCode == 200) {
        print('Story media deleted successfully.');
        return true;
      } else {
        print('Failed to delete story media. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      print('Error deleting story media: $e');
      return false;
    }
  }
}
