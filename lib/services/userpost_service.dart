import 'dart:convert';
import 'blocked_user_exception.dart';
import 'bannedexception.dart';  // Ensure this import is correct
import '../models/post_model.dart';
import '../models/sharedpost_model.dart';
import 'SessionExpiredException.dart';
import 'apiService.dart';

class PrivacyException implements Exception {
  final String message;
  PrivacyException(this.message);

  @override
  String toString() => 'PrivacyException: $message';
}

class UserpostService {
  static const String baseUrl = 'https://bace-185-97-92-44.ngrok-free.app/api';
  final ApiService _apiService = ApiService();

  Future<List<Post>> fetchUserPosts(int currentUserId, int viewerUserId, int pageNumber, int pageSize) async {
    final Uri url = Uri.parse('$baseUrl/UserProfile/userposts?userId=$currentUserId&viewerUserId=$viewerUserId&pageNumber=$pageNumber&pageSize=$pageSize');
    final String signatureData = '$currentUserId:$viewerUserId:$pageNumber:$pageSize';

    print("[DEBUG] fetchUserPosts called with currentUserId=$currentUserId, viewerUserId=$viewerUserId, page=$pageNumber, size=$pageSize");

    final response = await _apiService.makeRequestWithToken(url, signatureData, 'GET');

    print("[DEBUG] fetchUserPosts response status: ${response.statusCode}");
    print("[DEBUG] fetchUserPosts response body: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => Post.fromJson(json)).toList();
    } else if (response.statusCode == 204) {
      print("[DEBUG] No posts found (204)");
      return [];
    } else if (response.statusCode == 403) {
      print("[DEBUG] 403 encountered in fetchUserPosts");
      final rawBody = response.body;

      try {
        final Map<String, dynamic> jsonData = jsonDecode(rawBody);
        print("[DEBUG] Parsed 403 JSON: $jsonData");

        // Check if user is banned
        if (jsonData['message'] == "This user is banned.") {
          print("[DEBUG] Banned user scenario in fetchUserPosts");
          throw BannedException("This user is banned.", "N/A");
        }

        final isBlockedBy = jsonData['blockedBy'] as bool? ?? false;
        final isUserBlocked = jsonData['blockedUser'] as bool? ?? false;

        if (isBlockedBy || isUserBlocked) {
          // Blocked scenario from JSON
          print("[DEBUG] Throwing BlockedUserException from fetchUserPosts");
          throw BlockedUserException(
            reason: jsonData['message'],
            isBlockedBy: isBlockedBy,
            isUserBlocked: isUserBlocked,
          );
        } else {
          // Privacy scenario from JSON
          print("[DEBUG] Throwing PrivacyException from fetchUserPosts (JSON parsed, no block flags)");
          throw PrivacyException(jsonData['message'] ?? 'This account is private.');
        }
      } catch (e) {
        // Non-JSON response
        print("[DEBUG] Non-JSON 403 response in fetchUserPosts. Checking message keywords.");
        final lowerBody = rawBody.toLowerCase();

        if (lowerBody.contains("banned")) {
          // Handle banned scenario in non-JSON response (if ever occurs)
          print("[DEBUG] Banned user scenario in non-JSON fetchUserPosts");
          throw BannedException("This user is banned.", "N/A");
        } else if (lowerBody.contains("blocked") || lowerBody.contains("you have blocked this user") || lowerBody.contains("blocked by this user")) {
          print("[DEBUG] Non-JSON response indicates a blocked scenario.");
          bool isBlockedBy = false;
          bool isUserBlocked = false;

          if (lowerBody.contains("you have blocked this user")) {
            isUserBlocked = true;
          } else if (lowerBody.contains("user blocked you") || lowerBody.contains("you are blocked by this user")) {
            isBlockedBy = true;
          } else {
            isUserBlocked = true;
          }

          throw BlockedUserException(
            reason: rawBody,
            isBlockedBy: isBlockedBy,
            isUserBlocked: isUserBlocked,
          );
        } else {
          print("[DEBUG] Non-JSON response indicates a privacy scenario.");
          throw PrivacyException("This account is private.");
        }
      }
    } else if (response.statusCode == 404) {
      print("[DEBUG] 404: No posts found");
      throw Exception('No posts found for this user.');
    } else {
      print("[DEBUG] Unexpected status code: ${response.statusCode} in fetchUserPosts");
      throw Exception('Failed to load user posts');
    }
  }

  Future<List<Post>> fetchBookmarkedPosts(int userId, int pageNumber, int pageSize) async {
    final Uri url = Uri.parse('$baseUrl/UserProfile/bookmarked?userId=$userId&pageNumber=$pageNumber&pageSize=$pageSize');
    final String signatureData = '$userId:$pageNumber:$pageSize';

    try {
      print("Calling bookmarked posts API: $url");
      final response = await _apiService.makeRequestWithToken(url, signatureData, 'GET');

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
      rethrow;
    } catch (e) {
      print('Error fetching bookmarked posts: $e');
      throw Exception('Failed to load bookmarked posts');
    }
  }

  Future<List<SharedPostDetails>> fetchSharedPosts(int currentUserId, int viewerUserId, int pageNumber, int pageSize) async {
    final Uri url = Uri.parse('$baseUrl/UserProfile/sharedposts/$currentUserId?viewerUserId=$viewerUserId&pageNumber=$pageNumber&pageSize=$pageSize');
    final String signatureData = '$currentUserId:$viewerUserId:$pageNumber:$pageSize';

    print("[DEBUG] fetchSharedPosts called with currentUserId=$currentUserId, viewerUserId=$viewerUserId, page=$pageNumber, size=$pageSize");

    final response = await _apiService.makeRequestWithToken(url, signatureData, 'GET');

    print("[DEBUG] fetchSharedPosts response status: ${response.statusCode}");
    print("[DEBUG] fetchSharedPosts response body: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => SharedPostDetails.fromJson(json)).toList();
    } else if (response.statusCode == 204) {
      print("[DEBUG] No shared posts found (204)");
      return [];
    } else if (response.statusCode == 403) {
      print("[DEBUG] 403 encountered in fetchSharedPosts");
      final rawBody = response.body;
      try {
        final Map<String, dynamic> jsonData = jsonDecode(rawBody);
        print("[DEBUG] Parsed 403 JSON in sharedPosts: $jsonData");

        // Check if user is banned
        if (jsonData['message'] == "This user is banned.") {
          print("[DEBUG] Banned user scenario in fetchSharedPosts");
          throw BannedException("This user is banned.", "N/A");
        }

        final isBlockedBy = jsonData['blockedBy'] as bool? ?? false;
        final isUserBlocked = jsonData['blockedUser'] as bool? ?? false;

        if (isBlockedBy || isUserBlocked) {
          // Blocked scenario
          print("[DEBUG] Throwing BlockedUserException from fetchSharedPosts");
          throw BlockedUserException(
            reason: jsonData['message'],
            isBlockedBy: isBlockedBy,
            isUserBlocked: isUserBlocked,
          );
        } else {
          // Privacy scenario
          print("[DEBUG] Throwing PrivacyException from fetchSharedPosts (JSON parsed, no block flags)");
          throw PrivacyException(jsonData['message'] ?? 'This account is private.');
        }
      } catch (e) {
        // Non-JSON response
        print("[DEBUG] Non-JSON 403 response in fetchSharedPosts. Checking message keywords.");
        final lowerBody = rawBody.toLowerCase();

        if (lowerBody.contains("banned")) {
          print("[DEBUG] Banned user scenario in non-JSON fetchSharedPosts");
          throw BannedException("This user is banned.", "N/A");
        } else if (lowerBody.contains("blocked") || lowerBody.contains("you have blocked this user") || lowerBody.contains("blocked by this user")) {
          print("[DEBUG] Non-JSON response indicates a blocked scenario.");
          bool isBlockedBy = false;
          bool isUserBlocked = false;

          if (lowerBody.contains("you have blocked this user")) {
            isUserBlocked = true;
          } else if (lowerBody.contains("user blocked you") || lowerBody.contains("you are blocked by this user")) {
            isBlockedBy = true;
          } else {
            isUserBlocked = true; // default if uncertain
          }

          throw BlockedUserException(
            reason: rawBody,
            isBlockedBy: isBlockedBy,
            isUserBlocked: isUserBlocked,
          );
        } else {
          print("[DEBUG] Non-JSON response indicates a privacy scenario in sharedPosts.");
          throw PrivacyException("This account is private.");
        }
      }
    } else if (response.statusCode == 404) {
      print("[DEBUG] 404: No shared posts found");
      throw Exception('No shared posts found for this user.');
    } else if (response.statusCode == 401) {
      print("[DEBUG] SessionExpiredException: 401 in fetchSharedPosts");
      throw SessionExpiredException('Session expired. Please log in again.');
    } else {
      print("[DEBUG] Unexpected status code in fetchSharedPosts: ${response.statusCode}");
      throw Exception('Failed to load shared posts');
    }
  }
}
