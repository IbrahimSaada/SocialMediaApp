import 'dart:convert';
import 'package:cook/models/userprofileresponse_model.dart'; // UserProfile model
import 'package:cook/models/editprofile_model.dart'; // EditUserProfile model
import 'package:cook/models/FollowStatusResponse.dart';
import 'package:cook/models/follower_model.dart';
import 'package:cook/models/following_model.dart';
import 'package:cook/models/privacy_settings_model.dart';
import 'apiService.dart';
import 'SessionExpiredException.dart';

class UserProfileService {
  static const String baseUrl = 'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/UserProfile';
  final ApiService _apiService = ApiService();
  // Fetch user profile method
    Future<UserProfile?> fetchUserProfile(int userId) async {
    final Uri uri = Uri.parse('$baseUrl/$userId');
    String signatureData = '$userId';

    try {
      var response = await _apiService.makeRequestWithToken(
        uri,
        signatureData,
        'GET',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return UserProfile.fromJson(json);
      } else {
        print('Failed to load user profile. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
  if (e is SessionExpiredException) {
    // Re-throw to be caught in the UI code
    throw e;
  } else {
    print('Error fetching user profile: $e');
    // Optionally handle other exceptions or rethrow
    throw e;
  }
}
  }

  // New method to edit profile using POST request
  Future<bool> editUserProfile({
    required String id,
    required EditUserProfile editUserProfile,
  }) async {
    final String url = "$baseUrl/$id/edit";

    // Dynamically build the dataToSign string based on non-null fields
    String signatureData = id; // Start with user ID

    if (editUserProfile.fullName != null && editUserProfile.fullName!.isNotEmpty) {
      signatureData += ":${editUserProfile.fullName}";
    }

    if (editUserProfile.profilePic != null && editUserProfile.profilePic!.isNotEmpty) {
      signatureData += ":${editUserProfile.profilePic}";
    }

    if (editUserProfile.bio != null && editUserProfile.bio!.isNotEmpty) {
      signatureData += ":${editUserProfile.bio}";
    }

    try {
      // Use ApiService to send the signed POST request with token and signature
      final response = await _apiService.makeRequestWithToken(
        Uri.parse(url),
        signatureData, // Signature data dynamically constructed
        'POST',
        body: editUserProfile.toJson(), // Convert the EditUserProfile model to JSON
      );

      if (response.statusCode == 200) {
        print("Profile updated successfully");
        return true;
      } else {
        print("Failed to update profile. Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
        return false;
      }
    } on SessionExpiredException {
      print("Session expired while trying to update profile.");
      throw SessionExpiredException(); // Trigger session expired UI in your app
    } catch (e) {
      print("Error occurred during profile update: $e");
      return false;
    }
  }

  // Method to check follow status
Future<FollowStatusResponse?> checkFollowStatus(int profileId, int currentUserId) async {
  final Uri url = Uri.parse('$baseUrl/$profileId/follow-status?currentUserId=$currentUserId');
  final String signatureData = '$profileId:$currentUserId'; // Data to sign includes profileId and currentUserId

  try {
    print("Attempting to fetch follow status for profileId: $profileId and currentUserId: $currentUserId");
    
    // Use ApiService to make the signed request
    final response = await _apiService.makeRequestWithToken(
      url,
      signatureData,
      'GET',
    );

    print("Response status code: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      print("Follow status fetched successfully.");
      return FollowStatusResponse.fromJson(json);
    } else {
      print('Failed to load follow status. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      return null;
    }
  } on SessionExpiredException {
    print('SessionExpired detected in checkFollowStatus');
    rethrow; // Re-throw to be caught in the UI layer
  } catch (e) {
    print('Error fetching follow status: $e');
    throw Exception('Failed to check follow status');
  }
}

// Method to change profile privacy settings using a model
Future<void> changeProfilePrivacy(int userId, PrivacySettings settings) async {
  // Helper function to match C# bool.ToString() output
  String boolToString(bool? value) {
    if (value == null) return 'null';
    return value ? 'True' : 'False'; // Capitalize to match C# output
  }

  // Build query parameters dynamically based on non-null values
  final queryParams = <String, String>{
    'userId': userId.toString(),
    if (settings.isPublic != null) 'isPublic': settings.isPublic.toString(),
    if (settings.isFollowersPublic != null) 'isFollowersPublic': settings.isFollowersPublic.toString(),
    if (settings.isFollowingPublic != null) 'isFollowingPublic': settings.isFollowingPublic.toString(),
  };

  // Construct the full URL with query parameters
  final Uri uri = Uri.parse(
    'https://e5ac-185-97-92-21.ngrok-free.app/api/UserProfile/change-privacy'
  ).replace(queryParameters: queryParams);

  // Data to sign (userId + privacy settings)
  final String signatureData = '$userId:${boolToString(settings.isPublic)}:${boolToString(settings.isFollowersPublic)}:${boolToString(settings.isFollowingPublic)}';

  print('Signature Data: $signatureData'); // For debugging

  try {
    // Use ApiService to send the signed request
    final response = await _apiService.makeRequestWithToken(
      uri,
      signatureData,
      'PUT',
    );

    // Handle the response
    if (response.statusCode == 200 || response.statusCode == 204) {
      print("Privacy settings updated successfully.");
    } else if (response.statusCode == 404) {
      print("Endpoint not found: $uri");
    } else {
      print("Failed to update privacy settings. Status code: ${response.statusCode}");
      print('Response body: ${response.body}');
    }
  } on SessionExpiredException {
    print("Session expired while trying to update privacy settings.");
    throw SessionExpiredException();  // This should be caught in the UI layer to trigger session expired behavior
  } catch (e) {
    print("Error updating privacy settings: $e");
    throw Exception("Failed to update privacy settings.");
  }
}


  // Method to check if the profile is public or private
Future<Map<String, bool>> checkProfilePrivacy(int userId) async {
  final Uri url = Uri.parse('$baseUrl/check-privacy/$userId');
  final String signatureData = '$userId'; // Data to sign is the userId

  try {
    // Use ApiService to make the signed request
    final response = await _apiService.makeRequestWithToken(
      url,
      signatureData,
      'GET',
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return {
        'isPublic': jsonData['isPublic'] ?? false,
        'isFollowersPublic': jsonData['isFollowersPublic'] ?? false,
        'isFollowingPublic': jsonData['isFollowingPublic'] ?? false,
      };
    } else {
      print('Failed to check profile privacy. Status code: ${response.statusCode}');
      throw Exception('Failed to check profile privacy');
    }
  } on SessionExpiredException {
    print('SessionExpired detected in checkProfilePrivacy');
    rethrow; // Rethrow to be caught in the UI layer
  } catch (e) {
    print('Error checking profile privacy: $e');
    throw Exception('Failed to check profile privacy');
  }
}

// After - Correct return type List<Follower>
Future<List<Follower>> fetchFollowers(
    int userId,
    int viewerUserId, {
    String search = "",
    int pageNumber = 1,
    int pageSize = 10,
}) async {
  // Build the full URL with query parameters
  final Uri url = Uri.parse(
    '$baseUrl/$userId/followers/$viewerUserId?search=$search&pageNumber=$pageNumber&pageSize=$pageSize',
  );

  // Data to sign (userId, viewerUserId, search, pageNumber, and pageSize)
  final String signatureData =
      '$userId:$viewerUserId:$search:$pageNumber:$pageSize';

  try {
    // Use ApiService to make the signed request
    final response = await _apiService.makeRequestWithToken(
      url,
      signatureData,
      'GET',
    );

    print('Response Body: ${response.body}'); // For debugging

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData.containsKey('followers')) {
        final followersData = jsonData['followers'];
        return (followersData as List)
            .map((data) => Follower.fromJson(data))
            .toList(); // Return List<Follower>
      }
    } else {
      print('Failed to fetch followers. Status code: ${response.statusCode}');
      throw Exception('Failed to fetch followers');
    }
  } on SessionExpiredException {
    print('SessionExpired detected while fetching followers');
    rethrow; // Rethrow the exception to trigger session expired in UI layer
  } catch (e) {
    print('Error fetching followers: $e');
    throw Exception('Failed to fetch followers');
  }

  return [];
}


  // Fetch following method now returning List<Following>
Future<List<Following>> fetchFollowing(int userId, int viewerUserId, {String search = "", int pageNumber = 1, int pageSize = 10}) async {
  final url = Uri.parse('$baseUrl/$userId/following/$viewerUserId?search=$search&pageNumber=$pageNumber&pageSize=$pageSize');
  
  // Data to sign: userId, viewerUserId, search, pageNumber, pageSize
  final String signatureData = '$userId:$viewerUserId:$search:$pageNumber:$pageSize';
  
  try {
    // Use ApiService to make the signed request
    final response = await _apiService.makeRequestWithToken(
      url,
      signatureData,
      'GET',
    );

    // Handle the response
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
      print('Response body: ${response.body}');
    }
  } on SessionExpiredException {
    print('SessionExpired detected in fetchFollowing');
    rethrow; // Re-throw to be caught in the UI layer for session expired handling
  } catch (e) {
    print('Error fetching following: $e');
  }
  return [];
}


// Method to change user password with signature and session expiration handling
Future<Map<String, dynamic>> changePassword(int userId, String oldPassword, String newPassword) async {
  final url = Uri.parse('$baseUrl/$userId/change-password');

  // Data to sign: userId, oldPassword, newPassword
  final String signatureData = '$userId:$oldPassword:$newPassword';

  try {
    // Use ApiService to send the signed request
    final response = await _apiService.makeRequestWithToken(
      url,
      signatureData,  // Include the signature data
      'POST',
      body: {
        'OldPassword': oldPassword,
        'NewPassword': newPassword,
      },
    );

    // Handle the response
    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Password changed successfully'};
    } else {
      final errorData = jsonDecode(response.body);
      return {'success': false, 'message': errorData['error'] ?? 'Password change failed'};
    }
  } on SessionExpiredException {
    print('SessionExpired detected during password change');
    rethrow; // Rethrow to be caught in the UI layer
  } catch (e) {
    return {'success': false, 'message': 'An error occurred: $e'};
  }
}



  // Method to delete a post by postId for the current user
Future<bool> deletePost(int postId, int userId) async {
  // Construct the URL with query parameters
  final Uri uri = Uri.parse('$baseUrl/delete-post/$postId?userId=$userId');

  // Data to sign (postId + userId)
  final String signatureData = '$postId:$userId';

  print('Signature Data: $signatureData'); // For debugging

  try {
    // Use ApiService to make the signed DELETE request
    final response = await _apiService.makeRequestWithToken(
      uri,
      signatureData,
      'DELETE',
    );

    // Handle the response
    if (response.statusCode == 200) {
      print("Post deleted successfully.");
      return true;
    } else {
      print("Failed to delete post. Status code: ${response.statusCode}");
      print('Response body: ${response.body}');
      return false;
    }
  } on SessionExpiredException {
    print("Session expired while trying to delete the post.");
    throw SessionExpiredException(); // This should be caught in the UI layer
  } catch (e) {
    print("Error deleting post: $e");
    throw Exception("Failed to delete post.");
  }
}


Future<bool> editPostCaption(int postId, String newCaption, int userId) async {
  final Uri url = Uri.parse('$baseUrl/edit-post/$postId?userId=$userId');

  final String signatureData = '$postId:$userId'; // Data to sign

  try {
    // Use ApiService to make the signed request
    final response = await _apiService.makeRequestWithToken(
      url,
      signatureData,
      'PUT',
      body: {'newCaption': newCaption}, // Pass body as Map
    );

    // Logging for debugging purposes
    print('Request URL: $url');
    print('Request Body: ${jsonEncode({'newCaption': newCaption})}');
    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      print("Post caption updated successfully.");
      return true;
    } else {
      print("Failed to update caption. Status code: ${response.statusCode}");
      print("Error response body: ${response.body}");
      return false;
    }
  } on SessionExpiredException {
    print('SessionExpired detected in editPostCaption');
    rethrow; // Rethrow the exception to be caught in the UI layer
  } catch (e) {
    print('Error in editPostCaption method: $e');
    return false;
  }
}


  // Method to delete a shared post by sharedPostId for the current user
Future<bool> deleteSharedPost(int sharedPostId, int userId) async {
  final Uri uri = Uri.parse('$baseUrl/delete-shared-post/$sharedPostId?userId=$userId');
  final String signatureData = '$sharedPostId:$userId';

  print('Signature Data: $signatureData'); // For debugging

  try {
    final response = await _apiService.makeRequestWithToken(
      uri,
      signatureData,
      'DELETE',
    );

    if (response.statusCode == 200) {
      print("Shared post deleted successfully.");
      return true;
    } else {
      print("Failed to delete shared post. Status code: ${response.statusCode}");
      print('Response body: ${response.body}');
      return false;
    }
  } on SessionExpiredException {
    print('SessionExpired detected in deleteSharedPost');
    rethrow; // Rethrow the exception to be caught in the UI layer
  } catch (e) {
    print("Error deleting shared post: $e");
    throw e; // Rethrow other exceptions to be handled in the UI layer
  }
}


  // Method to edit a shared post's comment by sharedPostId for the current user
Future<bool> editSharedPostComment(int sharedPostId, String newComment, int userId) async {
  final Uri url = Uri.parse('$baseUrl/edit-shared-post/$sharedPostId?userId=$userId');

  // Data to sign (sharedPostId + userId + newComment)
  final String signatureData = '$sharedPostId:$userId:$newComment';

  try {
    // Use ApiService to make the signed request
    final response = await _apiService.makeRequestWithToken(
      url,
      signatureData,
      'PUT',
      body: {'newCaption': newComment}, // Ensure this matches EditCaptionRequest
    );

    // Logging for debugging purposes
    print('Request URL: $url');
    print('Request Body: ${jsonEncode({'newCaption': newComment})}');
    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      print("Shared post comment updated successfully.");
      return true;
    } else {
      print("Failed to update shared post comment. Status code: ${response.statusCode}");
      print("Error response body: ${response.body}");
      return false;
    }
  } on SessionExpiredException {
    print('SessionExpired detected in editSharedPostComment');
    rethrow; // Rethrow the exception to be caught in the UI layer
  } catch (e) {
    print('Error in editSharedPostComment method: $e');
    return false;
  }
}


}
