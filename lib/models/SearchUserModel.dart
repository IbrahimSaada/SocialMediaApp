class SearchUserModel {
  final int userId;
  final String fullName;
  final String username;
  final String profilePic;
  final String bio;
  final String phoneNumber;
  bool isFollowing;   // Indicates if the searched user is following the current user
  bool amFollowing;   // Indicates if the current user is following the searched user

  SearchUserModel({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.profilePic,
    required this.bio,
    required this.phoneNumber,
    required this.isFollowing,
    required this.amFollowing,
  });

factory SearchUserModel.fromJson(Map<String, dynamic> json) {
  return SearchUserModel(
    userId: json['user_id'] as int,
    fullName: json['fullname'] ?? '',
    username: json['username'] ?? '',
    profilePic: json['profile_pic'] ?? '',
    bio: json['bio'] ?? '',
    phoneNumber: json['phone_number'] ?? '', // Provide a default value for null
    isFollowing: json['is_following'] ?? false,
    amFollowing: json['am_following'] ?? false,
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
      'is_following': isFollowing,
      'am_following': amFollowing,
    };
  }
  factory SearchUserModel.fromContentRequestJson(Map<String, dynamic> json) {
  return SearchUserModel(
    userId: json['follower_user_id'] ?? 0, // Specifically handle `follower_user_id`
    fullName: json['fullname'] ?? '',
    username: json['username'],  // Since `username` isn't in this response, you may skip or set a default value
    profilePic: json['profile_pic'] ?? '',
    bio: '',  // Skip or default as needed
    phoneNumber: '',
    isFollowing: false,
    amFollowing: false,
  );
}
}
