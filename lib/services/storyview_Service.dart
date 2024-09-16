import 'dart:convert';
import 'package:http/http.dart' as http;
import '***REMOVED***/models/storyview_request_model.dart';
import '***REMOVED***/models/storyview_response_model.dart';
import '***REMOVED***/services/LoginService.dart'; // Import LoginService
import '***REMOVED***/services/SignatureService.dart'; // Import SignatureService

class StoryServiceRequest {
  final String baseUrl =
      "***REMOVED***/api/Stories"; // Base API URL

  final LoginService _loginService = LoginService();
  final SignatureService _signatureService = SignatureService(); // Use SignatureService

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

  // Method to record story view (POST)
  Future<StoryViewResponse?> recordStoryView(StoryViewRequest request) async {
    String? accessToken = await _getValidToken(); // Ensure token is valid

    if (accessToken == null) {
      print('Unable to retrieve access token.');
      return null; // If no valid token, return early
    }

    // Generate signature for the request
    var dataToSign = '${request.storyId}:${request.viewerId}';
    String signature = await _signatureService.generateHMAC(dataToSign);

    final response = await http.post(
      Uri.parse('$baseUrl/View'), // Full URL for recording story view
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken', // Include the valid access token
        'X-Signature': signature, // Include the signature in the headers
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return StoryViewResponse.fromJson(jsonDecode(response.body));
    } else {
      print("Failed to record story view: ${response.statusCode}");
      return null;
    }
  }

  // Method to get the list of users who viewed a story (GET)
  Future<List<StoryViewer>?> getStoryViewers(int storyId) async {
    String? accessToken = await _getValidToken(); // Ensure token is valid

    if (accessToken == null) {
      print('Unable to retrieve access token.');
      return null; // If no valid token, return early
    }

    // Generate signature for the request
    var dataToSign = '$storyId';
    String signature = await _signatureService.generateHMAC(dataToSign);

    final response = await http.get(
      Uri.parse('$baseUrl/$storyId/viewers'), // Full URL for retrieving story viewers
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken', // Include the valid access token
        'X-Signature': signature, // Include the signature in the headers
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
