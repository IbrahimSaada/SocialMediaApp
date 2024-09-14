// ignore_for_file: avoid_print, file_names

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cook/models/storyview_request_model.dart';
import 'package:cook/models/storyview_response_model.dart';

class StoryServiceRequest {
  final String baseUrl =
      "http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/Stories"; // Base API URL

  // Method to record story view (POST)
  Future<StoryViewResponse?> recordStoryView(StoryViewRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/View'), // Full URL for recording story view
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return StoryViewResponse.fromJson(jsonDecode(response.body));
    } else {
      // Handle error
      print("Failed to record story view: ${response.statusCode}");
      return null;
    }
  }

  // Method to get the list of users who viewed a story (GET)
  Future<List<StoryViewer>?> getStoryViewers(int storyId) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/$storyId/viewers'), // Full URL for retrieving story viewers
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      List<StoryViewer> viewers =
          jsonList.map((json) => StoryViewer.fromJson(json)).toList();
      return viewers;
    } else {
      print("Failed to retrieve story viewers: ${response.statusCode}");
      return null;
    }
  }
}
