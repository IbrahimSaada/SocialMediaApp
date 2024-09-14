class PostRequest {
  final int userId;
  final String caption;
  final bool isPublic;
  final List<Media> media;

  PostRequest({
    required this.userId,
    required this.caption,
    required this.isPublic,
    required this.media,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'caption': caption,
      'is_public': isPublic,
      'media': media.map((m) => m.toJson()).toList(),
    };
  }
}

class Media {
  final String mediaUrl;
  final String mediaType; // "photo" or "video"

  Media({
    required this.mediaUrl,
    required this.mediaType,
  });

  Map<String, dynamic> toJson() {
    return {
      'media_url': mediaUrl,
      'media_type': mediaType,
    };
  }
}
