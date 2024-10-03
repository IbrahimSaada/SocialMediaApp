class FollowStatusResponse {
  final bool isFollowing;
  final bool amFollowing;

  FollowStatusResponse({
    required this.isFollowing,
    required this.amFollowing,
  });

  // Factory method to create an instance from JSON
  factory FollowStatusResponse.fromJson(Map<String, dynamic> json) {
    return FollowStatusResponse(
      isFollowing: json['isFollowing'],
      amFollowing: json['amFollowing'],
    );
  }

  // Method to convert an instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'isFollowing': isFollowing,
      'amFollowing': amFollowing,
    };
  }
}
