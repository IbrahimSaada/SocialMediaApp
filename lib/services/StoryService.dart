// story_service.dart

import 'dart:convert';
import '***REMOVED***/models/story_model.dart';
import '***REMOVED***/models/story_request_model.dart';
import '***REMOVED***/services/apiService.dart';
import '***REMOVED***/services/SessionExpiredException.dart';
import '***REMOVED***/models/paginated_stories.dart'; // import the new model

class StoryService {
  final String baseUrl =
      '***REMOVED***/api/Stories';

  final ApiService _apiService = ApiService();

  /// Fetch stories with pagination
  /// Example usage: fetchStories(123, pageIndex: 1, pageSize: 20)
  Future<PaginatedStories> fetchStories(
    int userId, {
    int pageIndex = 1,
    int pageSize = 3,
  }) async {
    // e.g. GET /api/Stories/user/{userId}?pageIndex=1&pageSize=20
    final String fullUrl = '$baseUrl/user/$userId?pageIndex=$pageIndex&pageSize=$pageSize';

    // This is the data to sign
    final String signatureData = '$userId:$pageIndex:$pageSize';


    try {
      final response = await _apiService.makeRequestWithToken(
        Uri.parse(fullUrl),
        signatureData,
        'GET',
      );

      if (response.statusCode == 200) {
        // Expecting: { "Data": [...], "PageIndex": x, "PageSize": y, "TotalCount": z }
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return PaginatedStories.fromJson(jsonData);
      } else {
        print('Failed to load stories. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load stories.');
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      print('Error fetching stories: $e');
      rethrow;
    }
  }

  /// Create a story (POST)
  Future<void> createStory(StoryRequest storyRequest) async {
    final String signatureData =
        '${storyRequest.userId}:${storyRequest.media.map((m) => m.mediaUrl).join(",")}';

    try {
      final response = await _apiService.makeRequestWithToken(
        Uri.parse(baseUrl),
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
    final String signatureData = '$storyMediaId:$userId';
    final String url = '$baseUrl/Media/$storyMediaId/$userId';

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
