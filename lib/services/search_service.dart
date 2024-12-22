import 'dart:convert';
import 'package:http/http.dart' as http;

// Models
import 'package:cook/models/SearchUserModel.dart';

// Services & Exceptions
import 'SessionExpiredException.dart';
import 'apiService.dart';
import 'LoginService.dart';
import 'SignatureService.dart';
import 'blocked_user_exception.dart';
import 'bannedexception.dart';

class SearchService {
  // Base endpoints
  static const String baseUrl =
      'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/UserConnections/search';
  static const String followerRequestsUrl =
      'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/UserConnections/follower-requests';
  static const String pendingRequestsUrl =
      'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/UserConnections/pending-follow-requests';

  // Shared services
  final ApiService _apiService = ApiService();
  final LoginService _loginService = LoginService();
  final SignatureService _signatureService = SignatureService();

  /// Search for users with pagination
  /// [query], [currentUserId], [pageNumber], [pageSize]
  Future<List<SearchUserModel>> searchUsers(
    String query,
    int currentUserId,
    int pageNumber,
    int pageSize,
  ) async {
    // Ensure user is logged in
    if (!await _loginService.isLoggedIn()) {
      throw Exception("User not logged in.");
    }
    // Ensure secret key is present
    await _signatureService.ensureSecretKey();

    // Build the full URI
    final Uri uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        'fullname': query,
        'currentUserId': currentUserId.toString(),
        'pageNumber': pageNumber.toString(),
        'pageSize': pageSize.toString(),
      },
    );

    // Prepare the data to sign
    final String signatureData = '$query:$currentUserId:$pageNumber:$pageSize';

    try {
      // Make the request using ApiService
      http.Response response = await _apiService.makeRequestWithToken(
        uri,
        signatureData,
        'GET',
      );

      // Check for blocked or banned if needed (403, 423, etc.)
      if (response.statusCode == 403) {
        final reason = response.body.isNotEmpty
            ? response.body
            : 'Blocked or forbidden.';
        // We can parse or interpret the response body for block/banned clues
        if (reason.toLowerCase().contains('banned')) {
          // Example: "User is banned"
          throw BannedException("You are banned", "N/A");
        } else {
          // Assume blocked
          throw BlockedUserException(
            reason: reason,
            isBlockedBy: reason.toLowerCase().contains('blocked by'),
            isUserBlocked: reason.toLowerCase().contains('blocked user'),
          );
        }
      }

      // If we see 401, ApiService will have tried refreshing the token
      if (response.statusCode == 200) {
        // Parse success
        final Map<String, dynamic> data = json.decode(response.body);
        if (!data.containsKey('users')) {
          // If the JSON shape differs, adapt as needed
          throw Exception('Missing "users" key in search response');
        }

        List<dynamic> usersJson = data['users'];
        List<SearchUserModel> users = usersJson
            .map((jsonItem) => SearchUserModel.fromJson(jsonItem))
            .toList();
        return users;
      } else {
        // Other error codes
        throw Exception(
          'Failed to load search results: ${response.statusCode} - ${response.body}',
        );
      }
    } on SessionExpiredException {
      // Pass up to UI
      rethrow;
    } on BlockedUserException {
      rethrow;
    } on BannedException {
      rethrow;
    } catch (e) {
      // Any other error
      throw Exception('Error during user search: $e');
    }
  }

  /// Fetch follower requests
  Future<List<SearchUserModel>> getFollowerRequests(int currentUserId) async {
    if (!await _loginService.isLoggedIn()) {
      throw Exception("User not logged in.");
    }
    await _signatureService.ensureSecretKey();

    final Uri uri = Uri.parse(followerRequestsUrl).replace(
      queryParameters: {
        'currentUserId': currentUserId.toString(),
      },
    );

    final String signatureData = '$currentUserId';

    try {
      http.Response response = await _apiService.makeRequestWithToken(
        uri,
        signatureData,
        'GET',
      );

      if (response.statusCode == 403) {
        final reason = response.body.isNotEmpty
            ? response.body
            : 'Blocked or forbidden.';
        if (reason.toLowerCase().contains('banned')) {
          throw BannedException("You are banned", "N/A");
        } else {
          throw BlockedUserException(
            reason: reason,
            isBlockedBy: reason.toLowerCase().contains('blocked by'),
            isUserBlocked: reason.toLowerCase().contains('blocked user'),
          );
        }
      }

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<SearchUserModel> followerRequests = data
            .map((item) => SearchUserModel.fromJson(item))
            .toList();
        return followerRequests;
      } else {
        throw Exception(
            'Failed to load follower requests: ${response.body}');
      }
    } on SessionExpiredException {
      rethrow;
    } on BlockedUserException {
      rethrow;
    } on BannedException {
      rethrow;
    } catch (e) {
      throw Exception('Error occurred while fetching follower requests: $e');
    }
  }

  /// Fetch pending follow requests
  Future<List<SearchUserModel>> getPendingFollowRequests(int currentUserId) async {
    if (!await _loginService.isLoggedIn()) {
      throw Exception("User not logged in.");
    }
    await _signatureService.ensureSecretKey();

    final Uri uri = Uri.parse(pendingRequestsUrl).replace(
      queryParameters: {
        'currentUserId': currentUserId.toString(),
      },
    );

    final String signatureData = '$currentUserId';

    try {
      http.Response response = await _apiService.makeRequestWithToken(
        uri,
        signatureData,
        'GET',
      );

      if (response.statusCode == 403) {
        final reason = response.body.isNotEmpty
            ? response.body
            : 'Blocked or forbidden.';
        if (reason.toLowerCase().contains('banned')) {
          throw BannedException("You are banned", "N/A");
        } else {
          throw BlockedUserException(
            reason: reason,
            isBlockedBy: reason.toLowerCase().contains('blocked by'),
            isUserBlocked: reason.toLowerCase().contains('blocked user'),
          );
        }
      }

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<SearchUserModel> pendingRequests = data
            .map((item) => SearchUserModel.fromContentRequestJson(item))
            .toList();
        return pendingRequests;
      } else {
        throw Exception(
            'Failed to load pending follow requests: ${response.body}');
      }
    } on SessionExpiredException {
      rethrow;
    } on BlockedUserException {
      rethrow;
    } on BannedException {
      rethrow;
    } catch (e) {
      throw Exception(
          'Error occurred while fetching pending follow requests: $e');
    }
  }
}
