// widgets/story_section.dart

import '***REMOVED***/models/storyview_request_model.dart';
import 'package:flutter/material.dart';
import '***REMOVED***/models/story_model.dart' as story_model;
import '***REMOVED***/services/loginservice.dart';
import '***REMOVED***/home/full_screen_story_view.dart';
import '***REMOVED***/home/story.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '***REMOVED***/services/StoryService.dart' as storyService;
import '***REMOVED***/services/storyview_Service.dart' as storyview;


class StorySection extends StatefulWidget {
  final int? userId;

  const StorySection({Key? key, this.userId}) : super(key: key);

  @override
  _StorySectionState createState() => _StorySectionState();
}

class _StorySectionState extends State<StorySection> {
  List<story_model.Story> _stories = [];
  final LoginService _loginService = LoginService();
  int? _userId; // Define _userId
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchStories();
    _fetchUserIdAndStories();
  }
   Future<void> _fetchUserIdAndStories() async {
  setState(() {
    _isLoading = true;
  });
  
  try {
    final userId = await LoginService().getUserId();
    if (userId != null) {
      _userId = userId;
      await _fetchStories();
    } else {
      print('User ID not found');
    }
  } catch (e) {
    print('Failed to fetch user ID or stories: $e');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  Future<void> _recordStoryView(int storyId) async {
    if (_userId != null) {
      StoryViewRequest request = StoryViewRequest(storyId: storyId, viewerId: _userId!);
      StoryViewResponse? response = await storyview.StoryServiceRequest().recordStoryView(request);

      if (response != null) {
        print(response.message); // Handle the response message, if needed
      } else {
        print("Failed to record story view.");
      }
    }
  }

  Future<void> _fetchStories() async {
    try {
      if (_userId != null) {
List<story_model.Story> allStories =
    await storyService.StoryService().fetchStories(_userId!);


        // Print the fetched stories for debugging
        // ignore: avoid_print
        print('Fetched ${allStories.length} stories.');
        for (var story in allStories) {
          // ignore: avoid_print
          print(
              'Story ID: ${story.storyId}, User: ${story.fullName}, Media URL: ${story.media.isNotEmpty ? story.media[0].mediaUrl : 'No Media'}');
        }

        // Separate "My Stories" and "Other Stories"
        List<story_model.Story> myStories =
            allStories.where((story) => story.userId == _userId).toList();
        List<story_model.Story> otherStories =
            allStories.where((story) => story.userId != _userId).toList();

        setState(() {
          _stories = [
            ...myStories,
            ...otherStories
          ]; // "My Stories" appear first
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Failed to fetch stories: $e');
    }
  }

  void _viewStoryFullscreen(int initialIndex) {
    final story = _stories[initialIndex];

    // Call the API to record the view
    _recordStoryView(story.storyId);

    // Show the story fullscreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenStoryView(
          stories: _stories,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _addStories(List<story_model.Story> newStories) {
    setState(() {
      _stories.insertAll(0, newStories);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      color: Colors.grey[100],
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _stories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return StoryBox(onStoriesUpdated: _addStories);
                }

                final story = _stories[index - 1];
                if (story.media.isEmpty) {
                  return Container();
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
                          border: Border.all(color: Color(0xFFF45F67), width: 3),
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
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      ),
                      Positioned(
                        bottom: 10.0,
                        left: 10.0,
                        right: 10.0,
                        child: Column(
                          children: [
                            CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(story.profilePicUrl),
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
    );
  }
}
