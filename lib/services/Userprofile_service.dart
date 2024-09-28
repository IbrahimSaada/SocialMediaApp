import 'dart:convert';
import 'package:http/http.dart' as http;
import '***REMOVED***/models/userprofileresponse_model.dart'; // UserProfile model
import '***REMOVED***/models/editprofile_model.dart'; // EditUserProfile model

class UserProfileService {
  // Fetch user profile method
  Future<UserProfile?> fetchUserProfile(int id) async {
    final url = '***REMOVED***/api/UserProfile/$id';

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
  final String url = "***REMOVED***/api/UserProfile/$id/edit";

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
}
