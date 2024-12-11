// models/user_like.dart
class UserLike {
  final int userId;
  final String fullname;
  final String profilePic;
  final DateTime likedAt;

  UserLike({
    required this.userId,
    required this.fullname,
    required this.profilePic,
    required this.likedAt,
  });

  factory UserLike.fromJson(Map<String, dynamic> json) {
    return UserLike(
      userId: json['user_id'],
      fullname: json['fullname'],
      profilePic: json['profile_pic'],
      likedAt: DateTime.parse(json['liked_at']).toUtc(),
    );
  }
}
