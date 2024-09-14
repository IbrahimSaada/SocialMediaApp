// ignore_for_file: avoid_print, duplicate_ignore, file_names

import 'dart:convert';
import 'package:http/http.dart' as http;
import '***REMOVED***/models/story_model.dart';
import '***REMOVED***/models/story_request_model.dart';

class StoryService {
  // Define the base URLs for GET and POST requests
  final String getUrl =
      '***REMOVED***/api/Stories/user/';
  final String postUrl =
      '***REMOVED***/api/Stories';

  // Fetch stories using the GET request
  Future<List<Story>> fetchStories(int userId) async {
    final String fullUrl = '$getUrl$userId';
    try {
      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((item) => Story.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load stories');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching stories: $e');
      throw Exception('Error fetching stories');
    }
  }

  // Create a story using the POST request
  Future<void> createStory(StoryRequest storyRequest) async {
    try {
      final response = await http.post(
        Uri.parse(postUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(storyRequest.toJson()),
      );

      if (response.statusCode == 201) {
        print('Story created successfully');
      } else {
        print('Failed to create story. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to create story');
      }
    } catch (e) {
      print('Error creating story: $e');
      throw Exception('Error creating story');
    }
  }
}
