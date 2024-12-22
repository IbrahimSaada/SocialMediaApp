import 'package:cook/models/story_model.dart';
import 'package:cook/models/storyview_response_model.dart';

class PaginatedStories {
  final List<Story> data;
  final int pageIndex;
  final int pageSize;
  final int totalCount;

  PaginatedStories({
    required this.data,
    required this.pageIndex,
    required this.pageSize,
    required this.totalCount,
  });

factory PaginatedStories.fromJson(Map<String, dynamic> json) {
  final dataField = json['data'];

  // If 'data' is null or not a list, fallback to empty list
  final List<Story> storyList = dataField == null
      ? []
      : (dataField as List<dynamic>)
          .map((item) => Story.fromJson(item))
          .toList();

  return PaginatedStories(
    data: storyList,
    pageIndex: json['PageIndex'] ?? 1,
    pageSize: json['PageSize'] ?? 3,
    totalCount: json['totalCount'] ?? 0,
  );
}

}

class PaginatedViewers {
  final List<StoryViewer> data;
  final int pageIndex;
  final int pageSize;
  final int totalCount;

  PaginatedViewers({
    required this.data,
    required this.pageIndex,
    required this.pageSize,
    required this.totalCount,
  });

  factory PaginatedViewers.fromJson(Map<String, dynamic> json) {
    return PaginatedViewers(
      data: (json['data'] as List<dynamic>)
          .map((item) => StoryViewer.fromJson(item))
          .toList(),
      pageIndex: json['PageIndex'] ?? 1,
      pageSize: json['PageSize'] ?? 3,
      totalCount: json['TotalCount'] ?? 0,
    );
  }
}
