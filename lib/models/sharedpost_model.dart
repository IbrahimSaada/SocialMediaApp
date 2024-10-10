class SharedPostDetails {
  final int shareId;
  final int sharerId;
  final String sharerUsername;
  final String? sharerProfileUrl;
  final int postId;
  final String postContent;
  final DateTime postCreatedAt;
  final List<PostMedia> media;
  final DateTime sharedAt;
  final String? comment;
  final String? originalPostUserUrl;
  final String originalPostuserfullname;
  final int likecount;
  final int commentcount;
  final bool isLiked;
  final bool isBookmarked;

  SharedPostDetails({
    required this.shareId,
    required this.sharerId,
    required this.sharerUsername,
    this.sharerProfileUrl,
    required this.postId,
    required this.postContent,
    required this.postCreatedAt,
    required this.media,
    required this.sharedAt,
    this.comment,
    this.originalPostUserUrl,
    required this.originalPostuserfullname,
    required this.likecount,
    required this.commentcount,
    required this.isLiked,
    required this.isBookmarked,
  });

  // Factory method to create an instance from a JSON object
  factory SharedPostDetails.fromJson(Map<String, dynamic> json) {
    var mediaList = json['media'] as List;
    List<PostMedia> media = mediaList.map((mediaJson) => PostMedia.fromJson(mediaJson)).toList();

    return SharedPostDetails(
      shareId: json['shareId'],
      sharerId: json['sharerId'],
      sharerUsername: json['sharerUsername'],
      sharerProfileUrl: json['sharerProfileUrl'],
      postId: json['postId'],
      postContent: json['postContent'],
      postCreatedAt: DateTime.parse(json['postCreatedAt']),
      media: media,
      sharedAt: DateTime.parse(json['sharedAt']),
      comment: json['comment'],
      originalPostUserUrl: json['originalPostUserUrl'],
      originalPostuserfullname: json['originalPostFullName'],
      likecount: json['like_count'],
      commentcount: json['comment_count'],
      isLiked: json['is_liked'],
      isBookmarked: json['is_Bookmarked'],
    );
  }
}

class PostMedia {
  final String mediaUrl;
  final String mediaType;
  final String? thumbnailUrl;

  PostMedia({
    required this.mediaUrl,
    required this.mediaType,
    this.thumbnailUrl,
  });

  // Factory method to create an instance from a JSON object
  factory PostMedia.fromJson(Map<String, dynamic> json) {
    return PostMedia(
      mediaUrl: json['mediaUrl'],
      mediaType: json['mediaType'],
      thumbnailUrl: json['thumbnailUrl'],
    );
  }
}