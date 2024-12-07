// services/repost_details_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/repost_details_model.dart';
import 'LoginService.dart';

class RepostDetailsService {
  static const String baseUrl =
      '***REMOVED***/api/Feed';

  final LoginService _loginService = LoginService();

  // Fetch the latest repost of a post
  Future<RepostDetailsModel> fetchLatestRepost({
    required int postId,
    required int userId,
  }) async {
    try {
      String? token = await _loginService.getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/Posts/$postId/SharedPosts/$userId/latest'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> json = jsonDecode(response.body);
        return RepostDetailsModel.fromJson(json);
      } else if (response.statusCode == 401) {
        // Token invalid, try refreshing
        await _loginService.refreshAccessToken();
        token = await _loginService.getToken();

        // Retry the request
        final retryResponse = await http.get(
          Uri.parse('$baseUrl/Posts/$postId/SharedPosts/$userId/latest'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (retryResponse.statusCode == 200) {
          Map<String, dynamic> json = jsonDecode(retryResponse.body);
          return RepostDetailsModel.fromJson(json);
        } else {
          throw Exception(
              'Failed to fetch latest repost after refreshing token');
        }
      } else {
        throw Exception(
            'Failed to fetch latest repost: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error fetching latest repost: $e');
      rethrow;
    }
  }

  // Fetch all reposts of a post
  Future<List<RepostDetailsModel>> fetchRepostsForPost({
    required int postId,
    required int userId,
  }) async {
    try {
      String? token = await _loginService.getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/Posts/$postId/SharedPosts/$userId'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(response.body);
        List<RepostDetailsModel> reposts =
            jsonList.map((json) => RepostDetailsModel.fromJson(json)).toList();
        return reposts;
      } else if (response.statusCode == 401) {
        // Token invalid, try refreshing
        await _loginService.refreshAccessToken();
        token = await _loginService.getToken();

        // Retry the request
        final retryResponse = await http.get(
          Uri.parse('$baseUrl/Posts/$postId/SharedPosts/$userId'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (retryResponse.statusCode == 200) {
          List<dynamic> jsonList = jsonDecode(retryResponse.body);
          List<RepostDetailsModel> reposts = jsonList
              .map((json) => RepostDetailsModel.fromJson(json))
              .toList();
          return reposts;
        } else {
          throw Exception('Failed to fetch reposts after refreshing token');
        }
      } else {
        throw Exception(
            'Failed to fetch reposts: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error fetching reposts: $e');
      rethrow;
    }
  }
}
