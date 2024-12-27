// models/paginated_comment_response.dart

import 'package:cook/models/comment_model.dart';

class PaginatedCommentResponse {
  final List<Comment> comments;
  final int currentPage;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  PaginatedCommentResponse({
    required this.comments,
    required this.currentPage,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory PaginatedCommentResponse.fromJson(Map<String, dynamic> json) {
    // `json['comments']` will be a List of comment objects
    final List<dynamic> commentList = json['comments'] ?? [];

    return PaginatedCommentResponse(
      comments:
          commentList.map((c) => Comment.fromJson(c as Map<String, dynamic>)).toList(),
      currentPage: json['currentPage'] ?? 1,
      pageSize: json['pageSize'] ?? 5,
      totalCount: json['totalCount'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}
