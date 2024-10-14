import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cook/models/userprofileresponse_model.dart'; // UserProfile model
import 'package:cook/models/editprofile_model.dart'; // EditUserProfile model
import 'package:cook/models/FollowStatusResponse.dart';
import 'package:cook/models/follower_model.dart';
import 'package:cook/models/following_model.dart';
import 'package:cook/models/privacy_settings_model.dart';

class UserProfileService {
  static const String baseUrl = 'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/UserProfile';

  // Fetch user profile method
  Future<UserProfile?> fetchUserProfile(int id) async {
    final url = '$baseUrl/$id';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return UserProfile.fromJson(json);
      } else {
        print('Failed to load user profile. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }

    return null;
  }

  // New method to edit profile using POST request
  Future<bool> editUserProfile({
    required String id,
    required EditUserProfile editUserProfile,
  }) async {
    final String url = "$baseUrl/$id/edit";

    try {
      // Sending POST request with EditUserProfile model converted to JSON
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(editUserProfile.toJson()), // Only include modified fields
      );

      if (response.statusCode == 200) {
        print("Profile updated successfully");
        return true;
      } else {
        print("Failed to update profile. Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error occurred: $e");
      return false;
    }
  }

  // Method to check follow status
  Future<FollowStatusResponse?> checkFollowStatus(int profileId, int currentUserId) async {
    final String url = '$baseUrl/$profileId/follow-status?currentUserId=$currentUserId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return FollowStatusResponse.fromJson(json);
      } else {
        print('Failed to load follow status. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching follow status: $e');
    }

    return null;
  }

  // Method to change profile privacy settings using a model
Future<void> changeProfilePrivacy(int userId, PrivacySettings settings) async {
  // Build query parameters dynamically based on non-null values
  final queryParams = <String, String>{
    'userId': userId.toString(),
    if (settings.isPublic != null) 'isPublic': settings.isPublic.toString(),
    if (settings.isFollowersPublic != null) 'isFollowersPublic': settings.isFollowersPublic.toString(),
    if (settings.isFollowingPublic != null) 'isFollowingPublic': settings.isFollowingPublic.toString(),
  };

  // Construct the full URL with query parameters
final uri = Uri.parse(
  'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/UserProfile/change-privacy'
).replace(queryParameters: queryParams);

  try {
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      print("Privacy settings updated successfully.");
    } else if (response.statusCode == 404) {
      print("Endpoint not found: $uri");
    } else {
      print("Failed to update privacy settings. Status code: ${response.statusCode}");
    }
  } catch (e) {
    print("Error updating privacy settings: $e");
  }
}


  // Method to check if the profile is public or private
  Future<Map<String, bool>> checkProfilePrivacy(int userId) async {
    final url = Uri.parse('$baseUrl/check-privacy/$userId');

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return {
          'isPublic': jsonData['isPublic'] ?? false,
          'isFollowersPublic': jsonData['isFollowersPublic'] ?? false,
          'isFollowingPublic': jsonData['isFollowingPublic'] ?? false,
        };
      } else {
        throw Exception('Failed to check profile privacy. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking profile privacy: $e');
      throw Exception('Failed to check profile privacy');
    }
  }

// After - Correct return type List<Follower>
Future<List<Follower>> fetchFollowers(int userId, int viewerUserId, {String search = "", int pageNumber = 1, int pageSize = 10}) async {
  final url = '$baseUrl/$userId/followers/$viewerUserId?search=$search&pageNumber=$pageNumber&pageSize=$pageSize';

  try {
    final response = await http.get(Uri.parse(url));
    print('Response Body: ${response.body}'); // For debugging

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData.containsKey('followers')) {
        final followersData = jsonData['followers'];
        return (followersData as List).map((data) => Follower.fromJson(data)).toList(); // Return List<Follower>
      }
    }
  } catch (e) {
    print('Error fetching followers: $e');
  }
  return [];
}

  // Fetch following method now returning List<Following>
  Future<List<Following>> fetchFollowing(int userId, int viewerUserId, {String search = "", int pageNumber = 1, int pageSize = 10}) async {
    final url = '$baseUrl/$userId/following/$viewerUserId?search=$search&pageNumber=$pageNumber&pageSize=$pageSize';

    try {
      final response = await http.get(Uri.parse(url));
      print('Response Body: ${response.body}'); // Log response for debugging

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData.containsKey('following')) {
          final followingData = jsonData['following'];
          return (followingData as List).map((data) => Following.fromJson(data)).toList();
        } else {
          print('Key "following" not found in the response');
        }
      } else {
        print('Failed to load following. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching following: $e');
    }
    return [];
  }

  // Method to change user password
Future<Map<String, dynamic>> changePassword(int userId, String oldPassword, String newPassword) async {
  final url = Uri.parse('$baseUrl/$userId/change-password');
  final headers = {'Content-Type': 'application/json'};
  final body = jsonEncode({
    'oldPassword': oldPassword,
    'newPassword': newPassword,
  });

  try {
    final response = await http.post(url, headers: headers, body: body);
    
    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Password changed successfully'};
    } else {
      final errorData = jsonDecode(response.body);
      return {'success': false, 'message': errorData['error'] ?? 'Password change failed'};
    }
  } catch (e) {
    return {'success': false, 'message': 'An error occurred: $e'};
  }
}

}
