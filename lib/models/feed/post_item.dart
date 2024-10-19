// models/feed/post_item.dart

import 'feed_item.dart';
import 'user_info.dart';
import 'post_info.dart';

class PostItem extends FeedItem {
  PostInfo post;
  bool isLiked;
  bool isBookmarked;

  PostItem({
    required String type,
    required int itemId,
    required DateTime createdAt,
    required String content,
    required UserInfo user,
    required this.post,
    required this.isLiked,
    required this.isBookmarked,
  }) : super(
          type: type,
          itemId: itemId,
          createdAt: createdAt,
          content: content,
          user: user,
        );

  factory PostItem.fromJson(Map<String, dynamic> json) {
    // Debug: Print UTC time
    print("UTC time for PostItem (itemId: ${json['itemId']}): ${json['createdAt']}");

    return PostItem(
      type: json['type'] ?? '',
      itemId: json['itemId'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']).toUtc().toLocal() : DateTime.now().toLocal(),
      content: json['content'] ?? '',
      user: UserInfo.fromJson(json['user'] ?? {}),
      post: PostInfo.fromJson(json['post'] ?? {}),
      isLiked: json['isLiked'] ?? false,
      isBookmarked: json['isBookmarked'] ?? false,
    );
  }
}
