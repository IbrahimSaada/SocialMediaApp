class Follower {
  final int followerId;
  final String fullName;
  final String profilePic;

  Follower({
    required this.followerId,
    required this.fullName,
    required this.profilePic,
  });

  factory Follower.fromJson(Map<String, dynamic> json) {
    return Follower(
      followerId: json['followerId'] ?? 0,
      fullName: json['fullName'] ?? '',
      profilePic: json['profilePic'] ?? '',
    );
  }
}
