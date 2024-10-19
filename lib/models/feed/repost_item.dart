// models/feed/repost_item.dart

import 'feed_item.dart';
import 'user_info.dart';
import 'post_info.dart';

class RepostItem extends FeedItem {
  PostInfo post;
  bool isLiked;
  bool isBookmarked;

  RepostItem({
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

  factory RepostItem.fromJson(Map<String, dynamic> json) {
    return RepostItem(
      type: json['type'] ?? '',
      itemId: json['itemId'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      content: json['content'] ?? '',
      user: UserInfo.fromJson(json['user'] ?? {}),
      post: PostInfo.fromJson(json['post'] ?? {}),
      isLiked: json['isLiked'] ?? false,
      isBookmarked: json['isBookmarked'] ?? false,

    );
  }
}
