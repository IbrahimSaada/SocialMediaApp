// story_view_request.dart
class StoryViewRequest {
  final int storyId;
  final int viewerId;

  StoryViewRequest({required this.storyId, required this.viewerId});

  Map<String, dynamic> toJson() {
    return {
      'story_id': storyId,
      'viewer_id': viewerId,
    };
  }
}

// story_view_response.dart
class StoryViewResponse {
  final String message;

  StoryViewResponse({required this.message});

  factory StoryViewResponse.fromJson(Map<String, dynamic> json) {
    return StoryViewResponse(
      message: json['message'],
    );
  }
}
