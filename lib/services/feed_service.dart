// services/feed_service.dart

import 'dart:convert';
import 'SessionExpiredException.dart';
import 'apiService.dart';
import '../models/feed/feed_item.dart';
import '../models/feed/post_item.dart';
import '../models/feed/repost_item.dart';

class FeedService {
  static const String baseUrl = 'https://bace-185-97-92-44.ngrok-free.app/api';
  final ApiService _apiService = ApiService();

Future<List<FeedItem>> fetchFeed({
  required int userId,
  required int pageNumber,
  required int pageSize,
}) async {
  try {
    final Uri uri = Uri.parse(
      '$baseUrl/feed?userId=$userId&pageNumber=$pageNumber&pageSize=$pageSize',
    );

    final String signatureData = '$userId:$pageNumber:$pageSize';

    final response = await _apiService.makeRequestWithToken(
      uri,
      signatureData,
      'GET',
    );

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
  } on SessionExpiredException {
    rethrow;
  } catch (e) {
    print('Error fetching feed: $e');
    rethrow;
  }
}
}
