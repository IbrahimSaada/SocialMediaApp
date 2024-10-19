// models/feed_item.dart

import 'user_info.dart';
import 'post_item.dart';
import 'repost_item.dart';

abstract class FeedItem {
  String type;
  int itemId;
  DateTime createdAt;
  String content;
  UserInfo user;

  FeedItem({
    required this.type,
    required this.itemId,
    required this.createdAt,
    required this.content,
    required this.user,
  });


  factory FeedItem.fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'post') {
      return PostItem.fromJson(json);
    } else if (json['type'] == 'repost') {
      return RepostItem.fromJson(json);
    } else {
      throw Exception('Unknown feed item type: ${json['type']}');
    }
  }
}
