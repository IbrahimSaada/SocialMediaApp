// services/feed_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/feed/feed_item.dart';
import '../models/feed/post_item.dart';
import '../models/feed/repost_item.dart';

class FeedService {
  static const String baseUrl = 'https://af4a-185-97-92-30.ngrok-free.app/api';

  Future<List<FeedItem>> fetchFeed({
    required int userId,
    required int pageNumber,
    required int pageSize,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/feed?userId=$userId&pageNumber=$pageNumber&pageSize=$pageSize',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        try {
          List<dynamic> feedJson = jsonDecode(response.body);
          List<FeedItem> feedItems = feedJson.map((json) {
            String type = json['type'] ?? '';
            if (type == 'post') {
              print('Response body: ${response.body}');
              return PostItem.fromJson(json);
            } else if (type == 'repost') {
              print('Response body: ${response.body}');
              return RepostItem.fromJson(json);
            } else {
              throw Exception('Unknown feed item type: $type');
            }
          }).toList();
          return feedItems;
        } catch (e) {
          print('Error parsing JSON: $e');
          print('Response body: ${response.body}');
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
