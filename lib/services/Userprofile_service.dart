import 'dart:convert';
import 'package:http/http.dart' as http;
import '***REMOVED***/models/userprofileresponse_model.dart'; // UserProfile model
import '***REMOVED***/models/editprofile_model.dart'; // EditUserProfile model
import '***REMOVED***/models/FollowStatusResponse.dart';

class UserProfileService {
  static const String baseUrl = '***REMOVED***/api/UserProfile';

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

  // Method to change profile privacy
  Future<void> changeProfilePrivacy(int userId, bool isPublic) async {
    final url = Uri.parse('$baseUrl/change-privacy?userId=$userId&isPublic=$isPublic');

    try {
      final response = await http.put(url, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("Profile privacy updated successfully.");
      } else if (response.statusCode == 404) {
        print("Endpoint not found: $url");
      } else {
        print("Failed to update profile privacy. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error updating profile privacy: $e");
    }
  }

  // Method to check if the profile is public or private
  Future<bool> checkProfilePrivacy(int userId) async {
    final url = Uri.parse('$baseUrl/check-privacy/$userId');

    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['isPublic'];  // Return the boolean value
    } else {
      throw Exception('Failed to check profile privacy. Status code: ${response.statusCode}');
    }
  }
}
