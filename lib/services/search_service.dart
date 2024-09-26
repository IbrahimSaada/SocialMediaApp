import 'dart:convert';
import 'package:http/http.dart' as http;
import '***REMOVED***/models/SearchUserModel.dart';
import 'LoginService.dart';  // To access JWT and refresh token
import 'SignatureService.dart';  // For signature generation

class SearchService {
  static const String baseUrl = '***REMOVED***/api/Users/search';
  static const String followerRequestsUrl = '***REMOVED***/api/Users/follower-requests';

  final LoginService _loginService = LoginService();
  final SignatureService _signatureService = SignatureService();

  // Method to fetch search results with pagination and currentUserId from the backend
  Future<List<SearchUserModel>> searchUsers(String query, int currentUserId, int pageNumber, int pageSize) async {
    final Uri uri = Uri.parse(baseUrl).replace(queryParameters: {
      'fullname': query,
      'currentUserId': currentUserId.toString(),
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
    });

    try {
      // Ensure the user is logged in and get the JWT token
      if (!await _loginService.isLoggedIn()) {
        throw Exception("User not logged in.");
      }

      String? token = await _loginService.getToken();

      // Generate data to sign for the request
      String dataToSign = '$query:$currentUserId:$pageNumber:$pageSize';
      String signature = await _signatureService.generateHMAC(dataToSign);

      // Make the API request
      var response = await _makeRequestWithToken(uri, signature, token);

      // If the response status is 401 (Unauthorized), attempt to refresh the token and retry
      if (response.statusCode == 401) {
        print('JWT token expired. Attempting to refresh token...');
        await _loginService.refreshAccessToken();  // Refresh the token
        token = await _loginService.getToken();     // Get the new token
        print('Token refreshed successfully.');

        // Retry the request with the new token
        response = await _makeRequestWithToken(uri, signature, token);

        if (response.statusCode == 401) {
          // Token refresh failed, return an error
          throw Exception('Session expired or refresh token invalid.');
        }
      }

      // Handle success or error responses
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);

        // Parse the users and return the list of SearchUserModel
        List<SearchUserModel> users = (data['users'] as List<dynamic>)
            .map((userJson) => SearchUserModel.fromJson(userJson as Map<String, dynamic>))
            .toList();

        return users;
      } else {
        throw Exception('Failed to load search results: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error occurred during search: $e');
    }
  }

  // Method to fetch follower requests from the backend
  Future<List<SearchUserModel>> getFollowerRequests(int currentUserId) async {
    final Uri uri = Uri.parse(followerRequestsUrl).replace(queryParameters: {
      'currentUserId': currentUserId.toString(),
    });

    try {
      // Ensure the user is logged in and get the JWT token
      if (!await _loginService.isLoggedIn()) {
        throw Exception("User not logged in.");
      }

      String? token = await _loginService.getToken();

      // Generate data to sign for the request
      String dataToSign = '$currentUserId';
      String signature = await _signatureService.generateHMAC(dataToSign);

      // Make the API request
      var response = await _makeRequestWithToken(uri, signature, token);

      // If the response status is 401 (Unauthorized), attempt to refresh the token and retry
      if (response.statusCode == 401) {
        print('JWT token expired. Attempting to refresh token...');
        await _loginService.refreshAccessToken();  // Refresh the token
        token = await _loginService.getToken();     // Get the new token
        print('Token refreshed successfully.');

        // Retry the request with the new token
        response = await _makeRequestWithToken(uri, signature, token);

        if (response.statusCode == 401) {
          // Token refresh failed, return an error
          throw Exception('Session expired or refresh token invalid.');
        }
      }

      // Handle success or error responses
      if (response.statusCode == 200) {
        print('Response Body: ${response.body}');

        // Since the API returns a list directly, we can cast the body as a List
        List<dynamic> data = json.decode(response.body);

        // Convert each item in the list to a SearchUserModel
        List<SearchUserModel> followerRequests = data
            .map((userJson) => SearchUserModel.fromJson(userJson as Map<String, dynamic>))
            .toList();

        print('Parsed Follower Requests: $followerRequests');
        return followerRequests;
      } else {
        throw Exception('Failed to load follower requests: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error occurred while fetching follower requests: $e');
    }
  }

  // Helper method to make requests with the current token
  Future<http.Response> _makeRequestWithToken(Uri uri, String signature, String? token) async {
    return await http.get(uri, headers: {
      'Content-Type': 'application/json; charset=UTF-8',
      'X-Signature': signature,  // Include signature in headers
      'Authorization': 'Bearer $token',  // Include JWT token
    });
  }
}
