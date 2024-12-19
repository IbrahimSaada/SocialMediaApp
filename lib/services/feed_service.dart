// services/feed_service.dart

import 'dart:convert';
import 'apiService.dart';
import '../models/feed/feed_item.dart';
import '../models/feed/post_item.dart';
import '../models/feed/repost_item.dart';

class FeedService {
  static const String baseUrl = 'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api';
  final ApiService _apiService = ApiService();

  Future<List<FeedItem>> fetchFeed({
    required int userId,
    required int pageNumber,
    required int pageSize,
  }) async {
    try {
      // Construct the URI
      final Uri uri = Uri.parse(
        '$baseUrl/feed?userId=$userId&pageNumber=$pageNumber&pageSize=$pageSize',
      );

      // Prepare the data to sign
      final String signatureData = '$userId:$pageNumber:$pageSize';

      // Use ApiService to make the request
      final response = await _apiService.makeRequestWithToken(
        uri,
        signatureData,
        'GET',
      );

      // Handle the response
      if (response.statusCode == 200) {
        try {
          List<dynamic> feedJson = jsonDecode(response.body);
          List<FeedItem> feedItems = feedJson.map((json) {
            String type = json['type'] ?? '';
            if (type == 'post') {
              return PostItem.fromJson(json);
            } else if (type == 'repost') {
              return RepostItem.fromJson(json);
            } else {
              throw Exception('Unknown feed item type: $type');
            }
          }).toList();
          return feedItems;
        } catch (e) {
          print('Error parsing JSON: $e');
          throw Exception('Failed to parse feed data');
        }
      } else {
        throw Exception('Failed to load feed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching feed: $e');
      rethrow;
    }
  }
}
