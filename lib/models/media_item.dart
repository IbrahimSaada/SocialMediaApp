// models/media_item.dart

class MediaItem {
  final String mediaUrl;
  final String mediaType; // 'photo' or 'video'

  MediaItem({
    required this.mediaUrl,
    required this.mediaType,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      mediaUrl: json['mediaUrl'],
      mediaType: json['mediaType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
    };
  }
}
