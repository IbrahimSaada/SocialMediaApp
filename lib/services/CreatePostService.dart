// ignore_for_file: file_names, avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import '***REMOVED***/models/post_request.dart';
import '***REMOVED***/services/LoginService.dart';
import 'SignatureService.dart';

class PostService {
  final String _createPostUrl = '***REMOVED***/api/CreatePost';
  final SignatureService _signatureService = SignatureService();
  final LoginService _loginService = LoginService();

  PostService();

  Future<void> createPost(PostRequest postRequest) async {
    // Ensure the token is valid before making the request
    String? token = await _loginService.getToken();
    
    // If token is expired, refresh it
    DateTime? tokenExpiration = await _loginService.getTokenExpiration();
    if (tokenExpiration == null || DateTime.now().isAfter(tokenExpiration)) {
      print('Token expired, refreshing...');
      await _loginService.refreshAccessToken(); // Refresh token
      token = await _loginService.getToken();    // Get the new token after refresh
    }

    // If token is still null after refreshing, handle the error
    if (token == null) {
      throw Exception('Failed to retrieve token');
    }

    // Prepare data to sign
    String dataToSign = '${postRequest.userId}:${postRequest.caption}:${postRequest.isPublic}';
    String signature = await _signatureService.generateHMAC(dataToSign);

    print('Using token in createPost: $token');  // Debugging: Ensure the token is being used

    // Make the HTTP POST request with the token in the headers
    final response = await http.post(
      Uri.parse(_createPostUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',  // Use the fetched or refreshed token
        'X-Signature': signature,
      },
      body: jsonEncode(postRequest.toJson()),
    );

    // Handle the response
    if (response.statusCode == 201) {
      print('Post created successfully.');
    } else if (response.statusCode == 401) {
      // Handle 401 Unauthorized error - maybe token refresh failed
      print('Failed to create post: 401 Unauthorized. Retrying...');
      throw Exception('Failed to create post due to 401 Unauthorized.');
    } else {
      print('Failed to create post: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to create post.');
    }
  }
}
