class PrivacySettings {
  final bool? isPublic;
  final bool? isFollowersPublic;
  final bool? isFollowingPublic;

  PrivacySettings({this.isPublic, this.isFollowersPublic, this.isFollowingPublic});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (isPublic != null) data['isPublic'] = isPublic;
    if (isFollowersPublic != null) data['isFollowersPublic'] = isFollowersPublic;
    if (isFollowingPublic != null) data['isFollowingPublic'] = isFollowingPublic;
    return data;
  }
}
