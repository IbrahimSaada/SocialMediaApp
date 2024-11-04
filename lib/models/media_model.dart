// models/media_model.dart

class MediaItem {
  final String mediaUrl;
  final String mediaType;

  MediaItem({
    required this.mediaUrl,
    required this.mediaType,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      mediaUrl: json['mediaUrl'] ?? '',
      mediaType: json['mediaType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
    };
  }

  // Add the copyWith method
  MediaItem copyWith({
    String? mediaUrl,
    String? mediaType,
  }) {
    return MediaItem(
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
    );
  }

  @override
  String toString() {
    return 'MediaItem(mediaUrl: $mediaUrl, mediaType: $mediaType)';
  }
}
