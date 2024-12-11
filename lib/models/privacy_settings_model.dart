class PrivacySettings {
  final bool? isPublic;
  final bool? isFollowersPublic;
  final bool? isFollowingPublic;
  final bool? isNotificationsMuted;

  PrivacySettings({this.isPublic, this.isFollowersPublic, this.isFollowingPublic, this.isNotificationsMuted});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (isPublic != null) data['isPublic'] = isPublic;
    if (isFollowersPublic != null) data['isFollowersPublic'] = isFollowersPublic;
    if (isFollowingPublic != null) data['isFollowingPublic'] = isFollowingPublic;
    if (isNotificationsMuted != null) data['isNotificationsMuted'] = isNotificationsMuted;
    return data;
  }
}
