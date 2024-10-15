class Post {
  final int postId;
  String caption;
  final int commentCount;
  final DateTime _createdAtUtc; // Store the original UTC time
  final bool isPublic;
  int likeCount;
  final int userId;
  final String fullName;
  final String profilePic;
  final List<PostMedia> media;
  final bool isLiked;
  bool isBookmarked; // Add the bookmark field

  Post({
    required this.postId,
    required this.caption,
    required this.commentCount,
    required DateTime createdAt, // Accepts the UTC time from API
    required this.isPublic,
    required this.likeCount,
    required this.userId,
    required this.fullName,
    required this.profilePic,
    required this.media,
    required this.isLiked,
    this.isBookmarked = false, // Default to false if not provided
  }) : _createdAtUtc = createdAt.toUtc();

  // Getter to convert `createdAt` to local time
  DateTime get localCreatedAt => _createdAtUtc.toLocal();

  factory Post.fromJson(Map<String, dynamic> json) {
    // Retrieve the 'created_at' value from JSON
    String createdAtString = json['created_at'];

    // If the string does not already indicate UTC (e.g., no 'Z'), append 'Z'
    if (!createdAtString.endsWith('Z')) {
      createdAtString = '${createdAtString}Z';
    }

    // Parse the adjusted string as a UTC DateTime
    DateTime utcTime = DateTime.parse(createdAtString).toUtc();

    // Debug print to check UTC time during parsing
    // ignore: avoid_print
    print('Parsed UTC Time: $utcTime');

    return Post(
      postId: json['post_id'],
      caption: json['caption'],
      commentCount: json['comment_count'],
      createdAt: utcTime, // Pass the parsed UTC time
      isPublic: json['is_public'],
      likeCount: json['like_count'],
      userId: json['user_id'],
      fullName: json['fullname'],
      profilePic: json['profile_pic'],
      media: (json['media'] as List)
          .map((mediaJson) => PostMedia.fromJson(mediaJson))
          .toList(),
      isLiked: json['is_liked'],
      isBookmarked: json['is_Bookmarked'] ?? false, // Handle `isBookmarked` from JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'caption': caption,
      'comment_count': commentCount,
      'created_at': _createdAtUtc.toIso8601String(),
      'is_public': isPublic,
      'like_count': likeCount,
      'user_id': userId,
      'fullname': fullName,
      'profile_pic': profilePic,
      'media': media.map((m) => m.toJson()).toList(),
      'is_liked': isLiked,
      'is_bookmarked': isBookmarked, // Include `isBookmarked` in toJson
    };
  }
}

class PostMedia {
  final int mediaId;
  final String mediaUrl;
  final String mediaType;
  final int postId;
  final String? thumbnailurl;

  PostMedia({
    required this.mediaId,
    required this.mediaUrl,
    required this.mediaType,
    required this.postId,
    this.thumbnailurl,
  });

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    return PostMedia(
      mediaId: json['media_id'],
      mediaUrl: json['media_url'],
      mediaType: json['media_type'],
      postId: json['post_id'],
      thumbnailurl: json['thumbnail_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'media_id': mediaId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'post_id': postId,
      'thumbnail_url':thumbnailurl,
    };
  }
}
