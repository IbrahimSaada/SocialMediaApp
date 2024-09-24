// ignore_for_file: non_constant_identifier_names

class FollowRequestModel {
  final int followed_userId; // The ID of the user being followed
  final int followerUserId; // The ID of the user who is following (current user)

  FollowRequestModel({required this.followed_userId, required this.followerUserId});

  // Convert to JSON format
  Map<String, dynamic> toJson() {
    return {
      'followed_user_id': followed_userId,
      'follower_user_id': followerUserId,
    };
  }
}
