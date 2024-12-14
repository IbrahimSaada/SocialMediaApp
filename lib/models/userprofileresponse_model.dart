class UserProfile {
  final int userId;
  final String profilePic;
  final String fullName;
  final String qrCode;
  final double rating;
  final String bio;
  final int postNb;
  final int followersNb;
  final int followingNb;

  UserProfile({
    required this.userId,
    required this.profilePic,
    required this.fullName,
    required this.qrCode,
    required this.rating,
    required this.bio,
    required this.postNb,
    required this.followersNb,
    required this.followingNb,
  });

  // Factory method to create an instance of UserProfile from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] ?? 0, // Provide default value for userId
      profilePic: json['profile_pic'] ?? '', // Default to an empty string if null
      fullName: json['fullname'] ?? '', // Default to an empty string if null
      qrCode: json['qr_code'] ?? '', // Default to an empty string if null
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0, // Default to 0.0 if null
      bio: json['bio'] ?? '', // Default to an empty string if null
      postNb: json['post_nb'] ?? 0, // Default to 0 if null
      followersNb: json['followers_nb'] ?? 0, // Default to 0 if null
      followingNb: json['following_nb'] ?? 0, // Default to 0 if null
    );
  }

  // Method to convert an instance of UserProfile to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'profile_pic': profilePic,
      'fullname': fullName,
      'qr_code': qrCode,
      'rating': rating,
      'bio': bio,
      'post_nb': postNb,
      'followers_nb': followersNb,
      'following_nb': followingNb,
    };
  }
}
