class Following {
  final int followedUserId;
  final String fullName;
  final String profilePic;

  Following({
    required this.followedUserId,
    required this.fullName,
    required this.profilePic,
  });

  factory Following.fromJson(Map<String, dynamic> json) {
    return Following(
      followedUserId: json['followedUserId'] ?? 0,
      fullName: json['fullName'] ?? '',
      profilePic: json['profilePic'] ?? '',
    );
  }
}
