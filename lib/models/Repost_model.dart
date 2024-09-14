// ignore: duplicate_ignore
// ignore: file_names
// ignore_for_file: file_names

import 'package:cook/models/post_model.dart';

class Repost {
  final int shareId;
  final int sharerId;
  final String sharerUsername;
  final String sharerProfileUrl;
  final DateTime sharedAt;
  final String? comment;
  final int postId; // Add this field to hold the ID of the original post
  Post?
      originalPost; // Add this nullable field to hold the original Post object

  Repost({
    required this.shareId,
    required this.sharerId,
    required this.sharerUsername,
    required this.sharerProfileUrl,
    required DateTime sharedAt, // Accepts the UTC time from API
    required this.comment,
    required this.postId, // Initialize postId
    this.originalPost, // Initialize originalPost
  }) : sharedAt = sharedAt.toUtc();

  // Getter to convert `sharedAt` to local time
  DateTime get localSharedAt => sharedAt.toLocal();

  factory Repost.fromJson(Map<String, dynamic> json) {
    // Retrieve the 'sharedAt' value from JSON
    String sharedAtString = json['sharedAt'];

    // If the string does not already indicate UTC (e.g., no 'Z'), append 'Z'
    if (!sharedAtString.endsWith('Z')) {
      sharedAtString = '${sharedAtString}Z';
    }

    // Parse the adjusted string as a UTC DateTime
    DateTime utcSharedAt = DateTime.parse(sharedAtString).toUtc();

    return Repost(
      shareId: json['shareId'],
      sharerId: json['sharerId'],
      sharerUsername: json['sharerUsername'],
      sharerProfileUrl: json['sharerProfileUrl'],
      sharedAt: utcSharedAt, // Pass the parsed UTC time
      comment: json['comment'],
      postId: json['postId'], // Assign the postId from the JSON
      originalPost: null, // originalPost will be assigned later
    );
  }
}
