// models/user_info.dart

class UserInfo {
  int userId;
  String username;
  String fullName;
  String profilePictureUrl;

  UserInfo({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.profilePictureUrl,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      profilePictureUrl: json['profilePictureUrl'] ?? '',
    );
  }
}
