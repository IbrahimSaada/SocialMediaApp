// ignore_for_file: file_names, avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cook/models/repost_model.dart';
import 'LoginService.dart';  // For JWT token management
import 'SignatureService.dart';  // For HMAC signature generation

class RepostService {
  static const String baseUrl =
      'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api'; // Replace with your API base URL

  final LoginService _loginService = LoginService();  // Instantiate LoginService
  final SignatureService _signatureService = SignatureService();  // Instantiate SignatureService

  // Method to fetch reposts with JWT token and HMAC signature, with auto token refresh
  Future<List<Repost>> fetchReposts() async {
    try {
      // Ensure the user is logged in and get the JWT token
      if (!await _loginService.isLoggedIn()) {
        throw Exception("User not logged in.");
      }

      String? token = await _loginService.getToken();
      if (token == null) {
        throw Exception("No valid token found.");
      }

      // Generate HMAC signature (for this example, 'all' could be the signing data)
      String dataToSign = 'all';
      String signature = await _signatureService.generateHMAC(dataToSign);

      // Send GET request with JWT token and HMAC signature
      final response = await http.get(
        Uri.parse('$baseUrl/Shares'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Signature': signature,
        },
      );

      if (response.statusCode == 200) {
        // Parse the JSON response
        List<dynamic> repostsJson = json.decode(response.body);

        // Convert the JSON list to a list of Repost objects
        List<Repost> reposts =
            repostsJson.map((json) => Repost.fromJson(json)).toList();

        return reposts;
      } else if (response.statusCode == 401) {
        print('Token expired. Attempting to refresh...');

        // Try to refresh the token
        await _loginService.refreshAccessToken();
        token = await _loginService.getToken();  // Get the new token

        // Retry the request with the refreshed token
        signature = await _signatureService.generateHMAC(dataToSign);
        final retryResponse = await http.get(
          Uri.parse('$baseUrl/Shares'),
          headers: {
            'Authorization': 'Bearer $token',
            'X-Signature': signature,
          },
        );

        if (retryResponse.statusCode == 200) {
          // Parse the JSON response after token refresh
          List<dynamic> repostsJson = json.decode(retryResponse.body);
          List<Repost> reposts =
              repostsJson.map((json) => Repost.fromJson(json)).toList();

          return reposts;
        } else {
          throw Exception('Failed to load reposts after token refresh');
        }
      } else {
        throw Exception('Failed to load reposts: ${response.body}');
      }
    } catch (e) {
      print('Failed to load reposts: $e');
      throw Exception('Failed to load reposts');
    }
  }

  // Method to create a repost (POST request) with JWT and HMAC signature, with auto token refresh
Future<void> createRepost(int userId, int postId, String? comment) async {
  try {
    // Ensure the user is logged in and get the JWT token
    if (!await _loginService.isLoggedIn()) {
      throw Exception("User not logged in.");
    }

    String? token = await _loginService.getToken();
    if (token == null) {
      throw Exception("No valid token found.");
    }

    // Prepare the data for HMAC signature
    String dataToSign = '$userId:$postId:${comment ?? ""}';
    String signature = await _signatureService.generateHMAC(dataToSign);

    // Send the POST request
    final response = await http.post(
      Uri.parse('$baseUrl/Shares'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',  // Include JWT token
        'X-Signature': signature,          // Include HMAC signature
      },
      body: json.encode({
        'userId': userId,
        'postId': postId,
        'comment': comment ?? '', // Optional comment
      }),
    );

    if (response.statusCode == 200) {
      print('Repost created successfully');
    } else if (response.statusCode == 401) {
      print('Token expired. Attempting to refresh...');

      // Try to refresh the token
      await _loginService.refreshAccessToken();
      token = await _loginService.getToken();  // Get the new token

      // Retry the request with the refreshed token and recompute the signature
      signature = await _signatureService.generateHMAC(dataToSign);
      final retryResponse = await http.post(
        Uri.parse('$baseUrl/Shares'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',  // Refreshed JWT token
          'X-Signature': signature,          // Recomputed HMAC signature
        },
        body: json.encode({
          'userId': userId,
          'postId': postId,
          'comment': comment ?? '', // Optional comment
        }),
      );

      if (retryResponse.statusCode == 200) {
        print('Repost created successfully after token refresh');
      } else {
        throw Exception('Failed to create repost after token refresh');
      }
    } else {
      throw Exception('Failed to create repost: ${response.body}');
    }
  } catch (e) {
    if (e.toString().contains('Token expired')) {
      throw Exception('Session expired');
    }
    print('Failed to create repost: $e');
    throw Exception('Failed to create repost');
  }
}
}
