import 'dart:convert';
import '***REMOVED***/models/storyview_request_model.dart';
import '***REMOVED***/models/storyview_response_model.dart';
import '***REMOVED***/services/apiService.dart';
import '***REMOVED***/services/SessionExpiredException.dart';

class StoryServiceRequest {
  final String baseUrl =
      '***REMOVED***/api/Stories';

  final ApiService _apiService = ApiService();

  /// Record story view (POST)
  Future<StoryViewResponse?> recordStoryView(StoryViewRequest request) async {
    // Data to sign: storyId:viewerId
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

  /// Get the list of users who viewed a story (GET)
  Future<List<StoryViewer>?> getStoryViewers(int storyId) async {
    // Data to sign: storyId
    final String signatureData = '$storyId';

    try {
      final response = await _apiService.makeRequestWithToken(
        Uri.parse('$baseUrl/$storyId/viewers'),
        signatureData,
        'GET',
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(response.body);
        List<StoryViewer> viewers =
            jsonList.map((data) => StoryViewer.fromJson(data)).toList();
        return viewers;
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
