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
      userId: json['user_id'],
      profilePic: json['profile_pic'],
      fullName: json['fullname'],
      qrCode: json['qr_code'],
      rating: (json['rating'] as num).toDouble(),
      bio: json['bio'],
      postNb: json['post_nb'],
      followersNb: json['followers_nb'],
      followingNb: json['following_nb'],
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
