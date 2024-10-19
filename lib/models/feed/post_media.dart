// models/post_media.dart

class PostMedia {
  String mediaUrl;
  String mediaType;

  PostMedia({
    required this.mediaUrl,
    required this.mediaType,
  });

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    return PostMedia(
      mediaUrl: json['media_url'] ?? '',
      mediaType: json['media_type'] ?? '',
    );
  }
}
