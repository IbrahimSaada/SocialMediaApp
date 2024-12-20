// models/feed/post_info.dart

import '***REMOVED***/models/feed/post_media.dart';
import 'user_info.dart';

class PostInfo {
  int postId;
  DateTime createdAt;
  UserInfo? author; // Made nullable to handle null author
  String content;
  List<PostMedia> media;
  int likeCount;
  int commentCount;

  PostInfo({
    required this.postId,
    required this.createdAt,
    this.author,
    required this.content,
    required this.media,
    required this.likeCount,
    required this.commentCount,
  });

  static DateTime _parseUtcThenLocal(String dateStr) {
    if (!dateStr.endsWith('Z')) {
      dateStr = dateStr + 'Z';
    }
    return DateTime.parse(dateStr).toLocal();
  }

  factory PostInfo.fromJson(Map<String, dynamic> json) {
    return PostInfo(
      postId: json['postId'] ?? 0,
      createdAt: json['createdAt'] != null
          ? _parseUtcThenLocal(json['createdAt'])
          : DateTime.now().toLocal(),
      author: json['author'] != null ? UserInfo.fromJson(json['author']) : null,
      content: json['content'] ?? '',
      media: (json['media'] as List<dynamic>?)
              ?.map((mediaJson) => PostMedia.fromJson(mediaJson))
              .toList() ??
          [],
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
    );
  }
}
