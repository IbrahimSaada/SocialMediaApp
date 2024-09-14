class StoryRequest {
  final int userId;
  final List<MediaRequest> media;

  StoryRequest({required this.userId, required this.media});

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'media': media.map((mediaItem) => mediaItem.toJson()).toList(),
    };
  }
}

class MediaRequest {
  final String mediaUrl;
  final String mediaType;

  MediaRequest({required this.mediaUrl, required this.mediaType});

  Map<String, dynamic> toJson() {
    return {
      'media_url': mediaUrl,
      'media_type': mediaType,
    };
  }
}
