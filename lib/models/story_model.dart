class Media {
  final int mediaId;
  final String mediaUrl;
  final String mediaType;
  final DateTime _createdAtUtc;

  Media({
    required this.mediaId,
    required this.mediaUrl,
    required this.mediaType,
    required DateTime createdAt, // Keep createdAt for Media
  }) : _createdAtUtc = createdAt.toUtc() {
    // Debug prints to check time conversion
    // ignore: avoid_print
    print('Original UTC Time: $_createdAtUtc');
    // ignore: avoid_print
    print('Converted Local Time: ${_createdAtUtc.toLocal()}');
  }

  // Getter to convert `createdAt` to local time
  DateTime get localCreatedAt => _createdAtUtc.toLocal();

  factory Media.fromJson(Map<String, dynamic> json) {
    String createdAtString = json['createdatforeachstory'];
    if (!createdAtString.endsWith('Z')) {
      createdAtString = '${createdAtString}Z';
    }
    DateTime utcTime = DateTime.parse(createdAtString).toUtc();

    return Media(
      mediaId: json['media_id'],
      mediaUrl: json['media_url'],
      mediaType: json['media_type'],
      createdAt: utcTime, // Ensure UTC is passed here
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'media_id': mediaId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'createdatforeachstory': _createdAtUtc.toIso8601String(), // Pass the UTC time
    };
  }
}

class Story {
  final int storyId;
  final int userId;
  final String fullName; // Field for user's full name
  final String profilePicUrl; // Field for user's profile picture URL
  final DateTime expiresAt;
  final bool isActive;
  final int viewsCount;
  final bool isViewed;
  final List<Media> media;

  Story({
    required this.storyId,
    required this.userId,
    required this.fullName,
    required this.profilePicUrl,
    required this.expiresAt,
    required this.isActive,
    required this.viewsCount,
    required this.isViewed,
    required this.media,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    var mediaList = json['media'] as List;
    List<Media> mediaItems = mediaList.map((i) => Media.fromJson(i)).toList();

    return Story(
      storyId: json['story_id'],
      userId: json['user_id'],
      fullName: json['fullname'],
      profilePicUrl: json['profile_pic'],
      expiresAt: DateTime.parse(json['expiresat']).toUtc(),
      isActive: json['isactive'],
      viewsCount: json['viewscount'],
      isViewed: json['isviewed'],
      media: mediaItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'story_id': storyId,
      'user_id': userId,
      'fullname': fullName,
      'profile_pic': profilePicUrl,
      'expiresat': expiresAt.toIso8601String(), // Pass the UTC time
      'isactive': isActive,
      'viewscount': viewsCount,
      'isviewed': isViewed,
      'media': media.map((item) => item.toJson()).toList(),
    };
  }
}

extension on Media {
  // ignore: unused_element
  Map<String, dynamic> toJson() {
    return {
      'media_id': mediaId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'createdatforeachstory': _createdAtUtc.toIso8601String(), // Pass the UTC time
    };
  }
}