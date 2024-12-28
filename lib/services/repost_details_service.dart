// services/repost_details_service.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import '***REMOVED***/models/repost_details_model.dart'; // Your custom model
import '***REMOVED***/services/apiService.dart';
import '***REMOVED***/services/SessionExpiredException.dart';

class RepostDetailsService {
  // e.g. GET /api/Feed/Posts/{postId}/SharedPosts/{userId}
  //      GET /api/Feed/Posts/{postId}/SharedPosts/{userId}/latest
  static const String baseUrl =
      'https://bace-185-97-92-44.ngrok-free.app/api/Feed';

  final ApiService _apiService = ApiService();

  /// ------------------------------------------------------
  /// Fetch the *latest* repost for a given post & user
  /// e.g. GET /api/Feed/Posts/{postId}/SharedPosts/{userId}/latest
  /// - If your backend expects signature = "{postId}:{userId}"
  ///   then we do that here
  /// ------------------------------------------------------
  Future<RepostDetailsModel> fetchLatestRepost({
    required int postId,
    required int userId,
  }) async {
    final Uri uri = Uri.parse(
      '$baseUrl/Posts/$postId/SharedPosts/$userId/latest',
    );
    final String signatureData = '$postId:$userId';

    try {
      final response = await _apiService.makeRequestWithToken(
        uri,
        signatureData,
        'GET',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = jsonDecode(response.body);
        return RepostDetailsModel.fromJson(jsonMap);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired or token invalid.');
      } else {
        print(
          'Failed to fetch latest repost: ${response.statusCode} ${response.body}',
        );
        throw Exception(
          'Failed to fetch latest repost: ${response.statusCode} ${response.body}',
        );
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      print('Error fetching latest repost: $e');
      rethrow;
    }
  }

  /// ------------------------------------------------------
  /// Fetch all reposts for a given post & user
  /// e.g. GET /api/Feed/Posts/{postId}/SharedPosts/{userId}
  /// or with pagination: ?pageNumber=1&pageSize=10
  /// If your backend expects signature = "{postId}:{userId}:{pageNumber}:{pageSize}",
  /// then we do that here
  /// ------------------------------------------------------
  Future<List<RepostDetailsModel>> fetchRepostsForPost({
    required int postId,
    required int userId,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    // Build the URL with pagination
    final Uri uri = Uri.parse(
      '$baseUrl/Posts/$postId/SharedPosts/$userId'
      '?pageNumber=$pageNumber&pageSize=$pageSize',
    );
    // Data to sign = "postId:userId:pageNumber:pageSize"
    final String signatureData = '$postId:$userId:$pageNumber:$pageSize';

    try {
      final response = await _apiService.makeRequestWithToken(
        uri,
        signatureData,
        'GET',
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList
            .map((obj) => RepostDetailsModel.fromJson(obj))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Session expired or token invalid.');
      } else {
        print(
          'Failed to fetch reposts: ${response.statusCode} ${response.body}',
        );
        throw Exception(
          'Failed to fetch reposts: ${response.statusCode} ${response.body}',
        );
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      print('Error fetching reposts: $e');
      rethrow;
    }
  }
}
