// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import '***REMOVED***/models/story_model.dart';
import '***REMOVED***/models/story_request_model.dart';
import '***REMOVED***/services/LoginService.dart'; // Import LoginService for token management
import '***REMOVED***/services/SignatureService.dart'; // Import SignatureService

class StoryService {
  // Define the base URLs for GET and POST requests
  final String getUrl =
      '***REMOVED***/api/Stories/user/';
  final String postUrl =
      '***REMOVED***/api/Stories';

  final LoginService _loginService = LoginService();
  final SignatureService _signatureService = SignatureService();

  // Helper method to ensure token is valid or refresh it if expired
  Future<String?> _getValidToken() async {
    String? accessToken = await _loginService.getToken();
    DateTime? expiration = await _loginService.getTokenExpiration();

    // If the token is expired, proactively refresh it
    if (expiration == null || DateTime.now().isAfter(expiration)) {
      print('Access token expired, refreshing...');
      await _loginService.refreshAccessToken(); // Refresh the token
      accessToken = await _loginService.getToken(); // Get the new token
    }

    return accessToken; // Return the valid token
  }

  // Fetch stories using the GET request
  Future<List<Story>> fetchStories(int userId) async {
    final String fullUrl = '$getUrl$userId';
    String? accessToken = await _getValidToken(); // Ensure token is valid

    if (accessToken == null) {
      throw Exception('Unable to retrieve access token.');
    }

    // Generate signature for the request based on userId
    String signature = await _signatureService.generateHMAC('$userId');

    try {
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken', // Include valid access token
          'X-Signature': signature, // Include signature
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((item) => Story.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to load stories. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching stories: $e');
      throw Exception('Error fetching stories');
    }
  }

  // Create a story using the POST request
  Future<void> createStory(StoryRequest storyRequest) async {
    String? accessToken = await _getValidToken(); // Ensure token is valid

    if (accessToken == null) {
      throw Exception('Unable to retrieve access token.');
    }

    // Generate signature for the request based on userId and media URLs in storyRequest
    String dataToSign =
        '${storyRequest.userId}:${storyRequest.media.map((m) => m.mediaUrl).join(",")}';
    String signature = await _signatureService.generateHMAC(dataToSign);

    try {
      final response = await http.post(
        Uri.parse(postUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken', // Include valid access token
          'X-Signature': signature, // Include signature
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
    // Method to delete a story media (DELETE)
  Future<bool> deleteStoryMedia(int storyMediaId, int userId) async {
    String? accessToken = await _getValidToken(); // Ensure token is valid

    if (accessToken == null) {
      print('Unable to retrieve access token.');
      return false; // If no valid token, return early
    }

    // Generate signature for the request
    var dataToSign = '$storyMediaId:$userId';
    String signature = await _signatureService.generateHMAC(dataToSign);

    final url = '$postUrl/Media/$storyMediaId/$userId'; // Construct the API URL

    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken', // Include the valid access token
        'X-Signature': signature, // Include the signature in the headers
      },
    );

    if (response.statusCode == 200) {
      return true; // Successfully deleted
    } else {
      
      print("Failed to delete story media: ${response.statusCode}");
      return false;
    }
  }
}
