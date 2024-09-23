class SearchUserModel {
  final int userId;
  final String fullName;
  final String username;
  final String profilePic;
  final String bio;
  final String phoneNumber;

  SearchUserModel({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.profilePic,
    required this.bio,
    required this.phoneNumber,
  });

  factory SearchUserModel.fromJson(Map<String, dynamic> json) {
    return SearchUserModel(
      userId: json['user_id'] as int,
      fullName: json['fullname'] as String,
      username: json['username'] as String,
      profilePic: json['profile_pic'] as String,
      bio: json['bio'] as String,
      phoneNumber: json['phone_number'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'fullname': fullName,
      'username': username,
      'profile_pic': profilePic,
      'bio': bio,
      'phone_number': phoneNumber,
    };
  }
}
