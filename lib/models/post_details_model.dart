// models/post_details_model.dart

import 'feed/user_info.dart';
import 'feed/post_media.dart';

class PostDetailsModel {
  String type;
  int itemId;
  DateTime createdAt;
  String content;
  UserInfo user;
  PostInfo post;
  bool isLiked;
  bool isBookmarked;

  PostDetailsModel({
    required this.type,
    required this.itemId,
    required this.createdAt,
    required this.content,
    required this.user,
    required this.post,
    required this.isLiked,
    required this.isBookmarked,
  });

  factory PostDetailsModel.fromJson(Map<String, dynamic> json) {
    return PostDetailsModel(
      type: json['type'] ?? '',
      itemId: json['itemId'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      content: json['content'] ?? '',
      user: UserInfo.fromJson(json['user'] ?? {}),
      post: PostInfo.fromJson(json['post'] ?? {}),
      isLiked: json['isLiked'] ?? false,
      isBookmarked: json['isBookmarked'] ?? false,
    );
  }
}

class PostInfo {
  int postId;
  DateTime createdAt;
  UserInfo? author;
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

  factory PostInfo.fromJson(Map<String, dynamic> json) {
    return PostInfo(
      postId: json['postId'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
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
