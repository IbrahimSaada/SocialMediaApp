// story_service_request.dart

import 'dart:convert';
import '***REMOVED***/models/storyview_request_model.dart';
import '***REMOVED***/models/storyview_response_model.dart';
import '***REMOVED***/services/apiService.dart';
import '***REMOVED***/services/SessionExpiredException.dart';
import '***REMOVED***/models/paginated_stories.dart'; // import the new model

class StoryServiceRequest {
  final String baseUrl =
      '***REMOVED***/api/Stories';

  final ApiService _apiService = ApiService();

  /// Record story view (POST)
  Future<StoryViewResponse?> recordStoryView(StoryViewRequest request) async {
    final String signatureData = '${request.storyId}:${request.viewerId}';

    try {
      final response = await _apiService.makeRequestWithToken(
        Uri.parse('$baseUrl/View'),
        signatureData,
        'POST',
        body: request.toJson(),
      );

      if (response.statusCode == 200) {
        return StoryViewResponse.fromJson(json.decode(response.body));
      } else {
        print('Failed to record story view. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      print('Error recording story view: $e');
      return null;
    }
  }

  /// Get the list of users who viewed a story (GET) with pagination
  Future<PaginatedViewers?> getStoryViewers(
    int storyId, {
    int pageIndex = 1,
    int pageSize = 20,
  }) async {
    // e.g. GET /api/Stories/{storyId}/viewers?pageIndex=1&pageSize=20
    final String fullUrl = '$baseUrl/$storyId/viewers?pageIndex=$pageIndex&pageSize=$pageSize';
    final String signatureData = '$storyId';

    try {
      final response = await _apiService.makeRequestWithToken(
        Uri.parse(fullUrl),
        signatureData,
        'GET',
      );

      if (response.statusCode == 200) {
        // Expecting: { "Data": [...], "PageIndex": x, "PageSize": y, "TotalCount": z }
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return PaginatedViewers.fromJson(jsonData);
      } else {
        print('Failed to retrieve story viewers. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      print('Error retrieving story viewers: $e');
      return null;
    }
  }
}
