// widgets/story_section.dart

import 'package:myapp/models/storyview_request_model.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/story_model.dart' as story_model;
import 'package:myapp/services/loginservice.dart';
import 'package:myapp/home/full_screen_story_view.dart';
import 'package:myapp/home/story.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:myapp/services/StoryService.dart' as storyService;
import 'package:myapp/services/storyview_Service.dart' as storyview;
import 'package:myapp/models/storyview_response_model.dart';

class StorySection extends StatefulWidget {
  final int? userId;

  const StorySection({Key? key, this.userId}) : super(key: key);

  @override
  _StorySectionState createState() => _StorySectionState();
}

class _StorySectionState extends State<StorySection> {
  List<story_model.Story> _stories = [];
  final LoginService _loginService = LoginService();
  int? _userId;
  bool _isLoading = false;

  // 2) Track the current page and total stories
  int _currentPage = 1;
  int _totalCount = 0;          // from the backend ("TotalCount")
  bool _isLoadingMore = false;  // to prevent multiple loads at once
  bool _hasMore = true;         // if we've loaded all stories, we set false

  @override
  void initState() {
    super.initState();
    _fetchUserIdAndStories();
  }

  Future<void> _fetchUserIdAndStories() async {
    setState(() => _isLoading = true);
    try {
      final userId = await _loginService.getUserId();
      if (userId != null) {
        _userId = userId;
        // Fetch the first page
        await _fetchStories(isLoadMore: false);
      } else {
        print('User ID not found');
      }
    } catch (e) {
      print('Failed to fetch user ID or stories: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _recordStoryView(int storyId) async {
    if (_userId != null) {
      StoryViewRequest request = StoryViewRequest(storyId: storyId, viewerId: _userId!);
      StoryViewResponse? response = await storyview.StoryServiceRequest().recordStoryView(request);

      if (response != null) {
        print(response.message);
      } else {
        print("Failed to record story view.");
      }
    }
  }

Future<void> _fetchStories({bool isLoadMore = false}) async {
  try {
    if (_userId == null) return;

    // If not loading more, reset page to 1 and clear old data
    if (!isLoadMore) {
      _currentPage = 1;
      _stories.clear();
      _hasMore = true;
    }

    if (!_hasMore) {
      // We already loaded everything
      return;
    }

    setState(() => _isLoadingMore = true);

    // Fetch from the backend with the current page, pageSize = 3
    final paginatedStories = await storyService.StoryService().fetchStories(
      _userId!,
      pageIndex: _currentPage,
      pageSize: 3, // or any size you want
    );

    final newStories = paginatedStories.data;
    final total = paginatedStories.totalCount;

    print('Fetched page $_currentPage with ${newStories.length} stories. '
          'TotalCount = $total');

    // If the server tells us totalCount, store it:
    _totalCount = total;

    // Insert the new stories into our local list
    // =========== OPTIONAL REORDER ==============
    //  1) separate myStories vs others
    final myStories = newStories.where((s) => s.userId == _userId).toList();
    final otherStories = newStories.where((s) => s.userId != _userId).toList();

    // Insert them at the end of your existing list
    // but keep your stories in front
    setState(() {
      // We do NOT want to re-clear _stories, or we lose the old pages
      _stories.removeWhere((old) => newStories.any((n) => n.storyId == old.storyId));
      _stories.insertAll(0, myStories);
      _stories.addAll(otherStories);
    });

    // If we loaded fewer than pageSize or we've reached totalCount, 
    // no more pages to load
    if (newStories.length < 3 || _stories.length >= _totalCount) {
      _hasMore = false;
    } else {
      // We can increment for the next load
      _currentPage++;
    }

    setState(() => _isLoadingMore = false);

  } catch (e) {
    print('Failed to fetch stories: $e');
    setState(() => _isLoadingMore = false);
  }
}



void _viewStoryFullscreen(int initialIndex) {
  final story = _stories[initialIndex];

  // record view
  _recordStoryView(story.storyId);

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FullScreenStoryView(
        stories: _stories,
        initialIndex: initialIndex,

        // 2. define what to do when the child signals a story changed
        onStoriesChanged: () {
          _fetchStories(); // <--- re-fetch from server
        },
      ),
    ),
  );
}

void _addStories(List<story_model.Story> newStories) {
  // If newStories is empty, it means we want to force a fresh server call
  if (newStories.isEmpty) {
    _fetchStories(); 
    return; 
  }

  // Otherwise, manually merge the new stories at the front
  setState(() {
    // 1. Remove any stories already in _stories that match 
    //    the newly added story IDs.
    for (var newStory in newStories) {
      _stories.removeWhere((existing) => existing.storyId == newStory.storyId);
    }

    // 2. Insert the fresh stories at the front.
    _stories.insertAll(0, newStories);
  });
}

@override
Widget build(BuildContext context) {
  return Container(
    height: 220,
    padding: const EdgeInsets.symmetric(vertical: 10.0),
    color: Colors.grey[100],
    // We wrap our column in a NotificationListener to detect when user
    // scrolls near the end of the horizontal list.
    child: NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        // 1) Check if user has scrolled close to the max extent.
        if (scrollNotification.metrics.pixels >=
            scrollNotification.metrics.maxScrollExtent - 50) {
          // 2) If not already loading and we still have more pages, fetch next page
          if (!_isLoadingMore && _hasMore) {
            _fetchStories(isLoadMore: true);
          }
        }
        // Returning false allows the scroll event to continue to propagate
        return false;
      },
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _stories.length + 1, // +1 for the "Add Story" box
              itemBuilder: (context, index) {
                // The "Add Story" box is always first
                if (index == 0) {
                  return StoryBox(onStoriesUpdated: _addStories);
                }

                final story = _stories[index - 1];
                if (story.media.isEmpty) {
                  return const SizedBox.shrink();
                }

                return GestureDetector(
                  onTap: () => _viewStoryFullscreen(index - 1),
                  child: Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25.0),
                          border: Border.all(color: const Color(0xFFF45F67), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 3,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CachedNetworkImage(
                          imageUrl: story.media[0].mediaUrl,
                          imageBuilder: (context, imageProvider) => Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.white,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.0),
                                color: Colors.white,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                      Positioned(
                        bottom: 10.0,
                        left: 10.0,
                        right: 10.0,
                        child: Column(
                          children: [
                            CircleAvatar(
                              backgroundImage:
                                  CachedNetworkImageProvider(story.profilePicUrl),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              story.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

}
