class StoryViewer {
  final int viewerId;
  final String fullname;
  final String profilePic;
  final DateTime _viewedAtUtc; // Store the UTC time internally

  StoryViewer({
    required this.viewerId,
    required this.fullname,
    required this.profilePic,
    required DateTime viewedAt, // Take the original viewedAt time
  }) : _viewedAtUtc = viewedAt.toUtc();
  // Getter to convert `viewedAt` to local time
  DateTime get localViewedAt => _viewedAtUtc.toLocal();

  // Factory constructor to create an instance from JSON
  factory StoryViewer.fromJson(Map<String, dynamic> json) {
    String viewedAtString = json['viewed_at'];
    if (!viewedAtString.endsWith('Z')) {
      viewedAtString = '${viewedAtString}Z';
    }
    DateTime utcTime = DateTime.parse(viewedAtString).toUtc();

    return StoryViewer(
      viewerId: json['viewer_id'],
      fullname: json['fullname'],
      profilePic: json['profile_pic'],
      viewedAt: utcTime, // Ensure UTC is passed here
    );
  }

  // Method to convert the instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'viewer_id': viewerId,
      'fullname': fullname,
      'profile_pic': profilePic,
      'viewed_at': _viewedAtUtc.toIso8601String(), // Save the UTC time
    };
  }
}
