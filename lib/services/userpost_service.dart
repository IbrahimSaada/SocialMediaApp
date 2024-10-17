import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';
import '../models/sharedpost_model.dart';
import 'SessionExpiredException.dart';
import 'apiService.dart';

class UserpostService {
  static const String baseUrl = '***REMOVED***/api';
  final ApiService _apiService = ApiService();
  // Fetch User Posts
  Future<List<Post>> fetchUserPosts(int currentUserId, int viewerUserId, int pageNumber, int pageSize) async {
    final Uri url = Uri.parse('$baseUrl/UserProfile/userposts?userId=$currentUserId&viewerUserId=$viewerUserId&pageNumber=$pageNumber&pageSize=$pageSize');
    final String signatureData = '$currentUserId:$viewerUserId:$pageNumber:$pageSize'; // Data to sign

    try {
      print("Calling user posts API: $url"); // Debug statement

      // Use ApiService to make the signed request
      final response = await _apiService.makeRequestWithToken(
        url,
        signatureData,
        'GET',
      );

      // Debugging information
      print("User posts API response status: ${response.statusCode}");
      print("User posts API response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Post.fromJson(json)).toList();
      } else if (response.statusCode == 204) {
        // No content; return an empty list
        return [];
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. You are not allowed to view these posts.');
      } else if (response.statusCode == 404) {
        throw Exception('No posts found for this user.');
      } else {
        throw Exception('Failed to load user posts');
      }
    } on SessionExpiredException {
      print('SessionExpired detected in fetchUserPosts');
      rethrow; // Re-throw to be caught in the UI layer
    } catch (e) {
      print('Error fetching user posts: $e');
      throw Exception('Failed to load user posts');
    }
  }


  // Fetch Bookmarked Posts
  Future<List<Post>> fetchBookmarkedPosts(int userId, int pageNumber, int pageSize) async {
    final Uri url = Uri.parse('$baseUrl/UserProfile/bookmarked?userId=$userId&pageNumber=$pageNumber&pageSize=$pageSize');
    final String signatureData = '$userId:$pageNumber:$pageSize'; // Data to sign

    try {
      print("Calling bookmarked posts API: $url"); // Debug statement

      // Use ApiService to make the signed request
      final response = await _apiService.makeRequestWithToken(
        url,
        signatureData,
        'GET',
      );

      // Debugging information
      print("Bookmarked posts API response status: ${response.statusCode}");
      print("Bookmarked posts API response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load bookmarked posts');
      }
    } on SessionExpiredException {
      print('SessionExpired detected in fetchBookmarkedPosts');
      rethrow; // Re-throw to be caught in the UI layer
    } catch (e) {
      print('Error fetching bookmarked posts: $e');
      throw Exception('Failed to load bookmarked posts');
    }
  }
  // Fetch Shared Posts
  Future<List<SharedPostDetails>> fetchSharedPosts(int currentUserId, int viewerUserId, int pageNumber, int pageSize) async {
    final Uri url = Uri.parse('$baseUrl/UserProfile/sharedposts/$currentUserId?viewerUserId=$viewerUserId&pageNumber=$pageNumber&pageSize=$pageSize');
    final String signatureData = '$currentUserId:$viewerUserId:$pageNumber:$pageSize'; // Data to sign

    try {
      print("Calling shared posts API: $url"); // Debug statement

      // Use ApiService to make the signed request
      final response = await _apiService.makeRequestWithToken(
        url,
        signatureData,
        'GET',
      );

      // Debugging information
      print("Shared posts API response status: ${response.statusCode}");
      print("Shared posts API response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => SharedPostDetails.fromJson(json)).toList();
      } else if (response.statusCode == 204) {
        // No content; return an empty list
        return [];
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. You are not allowed to view these shared posts.');
      } else if (response.statusCode == 404) {
        throw Exception('No shared posts found for this user.');
      } else if (response.statusCode == 401) {
        throw SessionExpiredException('Session expired. Please log in again.');
      } else {
        throw Exception('Failed to load shared posts');
      }
    } on SessionExpiredException {
      print('SessionExpired detected in fetchSharedPosts');
      rethrow; // Re-throw to be caught in the UI layer
    } catch (e) {
      print('Error fetching shared posts: $e');
      throw Exception('Failed to load shared posts');
    }
  }

}