class FollowerStatusModel {
  final int followedUserId; // The ID of the user being followed
  final int followerUserId; // The ID of the user who is following
  final String? approvalStatus; // Approval status: approved, pending, declined

  FollowerStatusModel({
    required this.followedUserId,
    required this.followerUserId,
    this.approvalStatus // Default status
  });

  // Convert to JSON format
  Map<String, dynamic> toJson() {
    return {
      'followed_user_id': followedUserId,
      'follower_user_id': followerUserId,
      'approval_status': approvalStatus,
    };
  }
}
