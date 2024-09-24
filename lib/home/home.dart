import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import '***REMOVED***/home/add_friends_page.dart';
import '***REMOVED***/home/contacts_page.dart';
import '***REMOVED***/home/notification_page.dart';
import '***REMOVED***/menu/menu_page.dart';
import '***REMOVED***/services/LoginService.dart';
import '***REMOVED***/models/LikeRequest_model.dart';
import '***REMOVED***/home/comment.dart';
import '***REMOVED***/services/post_service.dart';
import '***REMOVED***/models/post_model.dart';
import '***REMOVED***/models/repost_model.dart';
import '***REMOVED***/services/RepostServices.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '***REMOVED***/home/posting.dart';
import '***REMOVED***/home/search.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '***REMOVED***/home/report_dialog.dart';
import '***REMOVED***/home/share.dart';
import '***REMOVED***/home/story.dart';
import '***REMOVED***/home/full_screen_story_view.dart';
import '***REMOVED***/models/story_model.dart' as story_model;
import '***REMOVED***/services/StoryService.dart'; // Import Story service
import '***REMOVED***/models/storyview_request_model.dart';
import '***REMOVED***/services/storyview_Service.dart';
import '***REMOVED***/askquestion/qna_page.dart';
import '***REMOVED***/maintenance/expiredtoken.dart';  // Importing the expired token handler
import '***REMOVED***/models/bookmarkrequest_model.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ignore: unused_field
  final TextEditingController _postController = TextEditingController();
  int likeCount = 0;
  int commentCount = 0;
  List<Post> _posts = [];
  List<Repost> _reposts = [];
  List<story_model.Story> _stories = []; // Use story_model.Story
  final List<story_model.Story> _userGeneratedStories =
      []; // Use Storys for user-generated stories
  int? _userId; // Store the user ID


  @override
  void initState() {
    super.initState();
    _initializeApp();
    _fetchUserIdAndStories();
  }

  Future<void> _fetchUserIdAndStories() async {
    final userId = await LoginService().getUserId();

    if (userId != null) {
      _userId = userId;
      await _fetchStories();
    } else {
      // ignore: avoid_print
      print('User ID not found');
    }
  }

// request viewstroy
  Future<void> _recordStoryView(int storyId) async {
    if (_userId != null) {
      StoryViewRequest request =
          StoryViewRequest(storyId: storyId, viewerId: _userId!);
      StoryViewResponse? response =
          await StoryServiceRequest().recordStoryView(request);

      if (response != null) {
        // ignore: avoid_print
        print(response.message); // Handle the response message, if needed
      } else {
        // ignore: avoid_print
        print("Failed to record story view.");
      }
    }
  }

  Future<void> _fetchStories() async {
    try {
      if (_userId != null) {
        List<story_model.Story> allStories =
            await StoryService().fetchStories(_userId!);

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

Future<void> _initializeApp() async {
  try {
    bool isLoggedIn = await LoginService().isLoggedIn();
    if (isLoggedIn) {
      await _fetchPostsAndReposts(); // Fetch both posts and reposts
    } else {
      // ignore: use_build_context_synchronously
      handleSessionExpired(context);  // Using global handler
    }
  } catch (e) {
    // ignore: avoid_print
    print('Initialization failed: $e');
  }
}


  

 Future<void> _fetchPostsAndReposts() async {
  try {
    final userId = await LoginService().getUserId();
    if (userId == null) {
      throw Exception('User not logged in');
    }

    List<Post> posts = await PostService.fetchPosts(userId: userId);
    List<Repost> reposts = await RepostService().fetchReposts();

    final postMap = {for (var post in posts) post.postId: post};

    for (var repost in reposts) {
      repost.originalPost = postMap[repost.postId];
    }

    setState(() {
      _posts = posts;
      _reposts = reposts;
    });
  } catch (e) {
    if (e.toString().contains('Session expired')) {
      // ignore: use_build_context_synchronously
      handleSessionExpired(context);  // Global session expired handler
    } else {
      // ignore: avoid_print
      print('Failed to load posts and reposts: $e');
    }
  }
}


  Future<void> _refreshPosts() async {
    await _fetchPostsAndReposts();
    await _fetchStories();
  }

  // When a story is tapped, record the view and then show the story
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
      _userGeneratedStories.insertAll(
          0, newStories); // Insert at the beginning of the list
    });
  }

PreferredSizeWidget buildAppBar() {
  return PreferredSize(
    preferredSize: const Size.fromHeight(130.0), // Slightly increased height to prevent overflow
    child: AppBar(
      backgroundColor: const Color(0xFF557C56), // Deep earthy green color
      automaticallyImplyLeading: false,
      elevation: 8.0, // Elevation for shadow effect
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(12), // Rounded bottom border
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          border: const Border(
            bottom: BorderSide(
              color: Color(0xFFD4AF37), // Light bronze for border shadow
              width: 2.0, // Border thickness
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withOpacity(0.5), // Light bronze shadow
              spreadRadius: 4,
              blurRadius: 8,
              offset: const Offset(0, 4), // Shadow position
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0), // Reduced top padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Menu Icon
                    IconButton(
                      icon: const CircleAvatar(
                        backgroundImage: NetworkImage(
                          '***REMOVED***/stories/fc8b94cf-0517-442c-be94-9fdceacc072e-43b8f63e-ee93-46c7-8519-400843a67c288688464432617468164.jpg',
                        ),
                      ),
                      onPressed: () {
                        // Handle menu button press
                        showDialog(
                          context: context,
                          builder: (context) {
                            final screenWidth = MediaQuery.of(context).size.width;
                            return Dialog(
                              insetPadding: EdgeInsets.only(left: 0, right: screenWidth * 0.5),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              child: Container(
                                color: Colors.white,
                                width: screenWidth * 0.5,
                                height: double.infinity,
                                child: const MenuPage(), // Replace with your menu page widget
                              ),
                            );
                          },
                        );
                      },
                    ),
                    // App Title
                    const Text(
                      'MyApp',
                      style: TextStyle(
                        color: Colors.white, // White text for contrast
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Help Icon
                    IconButton(
  icon: const Icon(Icons.question_mark, color: Colors.white),
  onPressed: () {
    // Navigate to AskQuestionPage
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QnaPage()),
    );
  },
),

                  ],
                ),
              ),
              const SizedBox(height: 8), // Reduced spacing between elements
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Add Friends Icon
                     IconButton(
          icon: const Icon(Icons.person_add, color: Colors.white),
          onPressed: () {
            // Navigate to Add Friends Page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddFriendsPage()), // Properly invoke AddFriendsPage
            );
          },
        ),
                    // Search Icon
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () {
                        // Navigate to Search Page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Search()),
                        );
                      },
                    ),
                    // Notifications Icon
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.white),
                      onPressed: () {
                        // Navigate to Notifications Page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationPage()),
                        );
                      },
                    ),
                    // Messages Icon
                    IconButton(
                      icon: const Icon(Icons.message, color: Colors.white),
                      onPressed: () {
                        // Navigate to Contacts Page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ContactsPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );


}

Widget buildDivider() {
  return const Divider(
    thickness: 1.5, // Thickness of the divider
    color: Color(0xFFD4AF37), // Light bronze color
  );
}

Widget buildStoriesSection() {
  return Container(
    height: 220,
    padding: const EdgeInsets.symmetric(vertical: 10.0),
    color: Colors.grey[100],
    child: Column(
      children: [
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _stories.length + 1, // +1 for the create story box
            itemBuilder: (context, index) {
              if (index == 0) {
                return StoryBox(onStoriesUpdated: _addStories); // The StoryBox widget we edited
              }

              final story = _stories[index - 1];
              if (story.media.isEmpty) {
                return Container(); // Skip if no media
              }

              return GestureDetector(
                onTap: () => _viewStoryFullscreen(index - 1), // Pass the index
                child: Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0), // Rounded corners
                        border: Border.all(color: const Color(0xFFD4AF37), width: 3), // Warm gold border
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1), // Soft shadow for depth
                            spreadRadius: 3,
                            blurRadius: 8,
                            offset: const Offset(0, 4), // Position of shadow
                          ),
                        ],
                      ),
                      child: CachedNetworkImage(
                        imageUrl: story.media[0].mediaUrl, // Display the first story image
                        imageBuilder: (context, imageProvider) => Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.0), // Match rounded corners
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0), // Match the rounded corners
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
                            backgroundImage: NetworkImage(story.profilePicUrl),
                            radius: 25.0,
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

  Widget buildPostOrRepost(dynamic item) {
    if (item is Post) {
      return PostCard(post: item);
    } else if (item is Repost) {
      return RepostCard(repost: item); // Assuming RepostCard is implemented
    } else {
      return Container(); // Handle unexpected types gracefully
    }
  }

 @override
Widget build(BuildContext context) {
  // Combine posts and reposts
  final combinedPostsAndReposts = List.from(_posts)..addAll(_reposts);

  // Sort combined posts and reposts by time
  combinedPostsAndReposts.sort((a, b) {
    final aTime = a is Post ? a.localCreatedAt : a.sharedAt;
    final bTime = b is Post ? b.localCreatedAt : b.sharedAt;
    return bTime.compareTo(aTime);
  });

  return Scaffold(
    backgroundColor: const Color(0xFFF0F0F0), // Light grey background
    appBar: buildAppBar(),
    body: RefreshIndicator(
      onRefresh: _refreshPosts,
      color: Colors.orange,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stories section
            buildStoriesSection(),
            buildDivider(),

            // Post input section
            buildPostInputSection(),
            buildDivider(),

            // Post and Repost list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // Disable scrolling within the ListView
              itemCount: combinedPostsAndReposts.isEmpty ? 0 : combinedPostsAndReposts.length,
              itemBuilder: (context, index) {
                return buildPostOrRepost(combinedPostsAndReposts[index]);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildPostInputSection() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFCCD5AE), // Soft green background
        borderRadius: BorderRadius.circular(30.0), // Smooth rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Soft shadow
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFD4AF37), width: 2), // Gold border
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.kitchen, color: Color(0xFF6B705C), size: 28), // Icon
            onPressed: () {
              // Handle icon action if needed
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePostPage(),  // Ensure CreatePostPage is correctly defined
                  ),
                );
              },
              child: Text(
                'What do you like to share...',  // Placeholder text
                style: TextStyle(
                  color: Colors.grey[700],  // Darker gray placeholder text
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.restaurant, color: Color(0xFFD4AF37), size: 28), // Icon
            onPressed: () {
              // Handle icon action if needed
            },
          ),
        ],
      ),
    ),
  );
}
}
// PostCard widget displaying a post with like and bookmark functionality
class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  // ignore: library_private_types_in_public_api
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isExpanded = false;
  late bool _isLiked;
  bool _isBookmarked = false; // To track bookmark state
  late AnimationController _animationController; // For animation
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _isBookmarked = widget.post.isBookmarked; // Assuming `post` model has isBookmarked field
    _fetchCurrentUserId();

    // Initialize the animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Animation duration
      lowerBound: 0.8, // Minimum scale for animation
      upperBound: 1.2, // Maximum scale for animation
    );
  }

  @override
  void dispose() {
    _animationController.dispose(); // Dispose of the controller to avoid memory leaks
    super.dispose();
  }

  Future<void> _fetchCurrentUserId() async {
    _currentUserId = await LoginService().getUserId();
  }

Future<void> _toggleBookmark() async {
  try {
    // Check if the user is logged in (this also refreshes the token if it's expired)
    bool isLoggedIn = await LoginService().isLoggedIn();
    
    if (!isLoggedIn) {
      throw Exception('Session expired');
    }

    final userId = await LoginService().getUserId();
    if (userId == null) {
      throw Exception('User ID not found');
    }

    // Start the animation for toggling the bookmark
    await _animationController.forward();

    // Now, attempt to bookmark/unbookmark
    if (_isBookmarked) {
      // Unbookmark the post
      await PostService.unbookmarkPost(
        BookmarkRequest(userId: userId, postId: widget.post.postId),
      );
      // Reverse the bookmark animation (remove glow)
      await _animationController.reverse();
    } else {
      // Bookmark the post
      await PostService.bookmarkPost(
        BookmarkRequest(userId: userId, postId: widget.post.postId),
      );
    }

    // Update the bookmark state
    setState(() {
      _isBookmarked = !_isBookmarked;
    });

  } catch (e) {
    // Handle session expiration
    if (e.toString().contains('Session expired')) {
      if (context.mounted) {
        handleSessionExpired(context); // Show session expired dialog
      }
    } else {
      // For any other errors, just print them
      print('Failed to bookmark/unbookmark post: $e');
    }
  }
}

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _viewImageFullscreen(List<String> mediaUrls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenImagePage(
          mediaUrls: mediaUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _handleLike() async {
    final userId = await LoginService().getUserId();

    if (userId == null) {
      return;
    }

    try {
      if (_isLiked) {
        await PostService.unlikePost(
          LikeRequest(userId: userId, postId: widget.post.postId),
        );
        setState(() {
          _isLiked = false;
          widget.post.likeCount -= 1;
        });
      } else {
        await PostService.likePost(
          LikeRequest(userId: userId, postId: widget.post.postId),
        );
        setState(() {
          _isLiked = true;
          widget.post.likeCount += 1;
        });
      }
    } catch (e) {
      if (e.toString().contains('Session expired')) {
        // ignore: use_build_context_synchronously
        handleSessionExpired(context);  // Global session expired handler
      } else {
        // ignore: avoid_print
        print('Failed to like/unlike post: $e');
      }
    }
  }

  void _showShareBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ShareBottomSheet(post: widget.post);
      },
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
      child: Container(
        width: MediaQuery.of(context).size.width, // Full width
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0), // Softer rounded corners
          color: Colors.white, // White background for the PostCard
          border: Border.all(color: Colors.grey.shade300, width: 1), // Thin grey border
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with avatar and post info
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(widget.post.profilePic),
                  ),
                  const SizedBox(width: 8.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Black for the username/fullname
                        ),
                      ),
                      Text(
                        timeago.format(widget.post.localCreatedAt),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (_currentUserId != widget.post.userId)
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'hide',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_off, color: Colors.grey.shade600),
                              const SizedBox(width: 10),
                              Text('Hide this post', style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.grey.shade600),
                              const SizedBox(width: 10),
                              Text('Report', style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(Icons.block, color: Colors.grey.shade600),
                              const SizedBox(width: 10),
                              Text('Block', style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'report') {
                          showReportDialog(
                            context: context,
                            reportedUser: widget.post.userId,
                            contentId: widget.post.postId,
                          );
                        } else if (value == 'block') {
                          // Handle block action
                        }
                      },
                      child: Icon(Icons.more_vert, color: Colors.grey.shade600),
                    ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Caption text
              if (widget.post.caption.isNotEmpty)
                _isExpanded
                    ? Text(widget.post.caption)
                    : Text(
                        widget.post.caption,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
              if (widget.post.caption.length > 100)
                GestureDetector(
                  onTap: _toggleExpansion,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        _isExpanded ? 'Show Less' : 'Show More',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16.0),

              // Post media (images or videos)
              if (widget.post.media.isNotEmpty)
                SizedBox(
                  height: 300,
                  width: double.infinity, // Ensures full-width media
                  child: PageView.builder(
                    itemCount: widget.post.media.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final media = widget.post.media[index];
                      return GestureDetector(
                        onDoubleTap: () {
                          _viewImageFullscreen(
                            widget.post.media.map((m) => m.mediaUrl).toList(),
                            index,
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0), // Rounded media edges
                          child: media.mediaType == 'photo'
                              ? Image.network(media.mediaUrl, fit: BoxFit.cover)
                              : VideoPost(mediaUrl: media.mediaUrl),
                        ),
                      );
                    },
                  ),
                ),

              if (widget.post.media.length > 1) // Show media indicators if more than one media
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.post.media.length, (index) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentIndex == index
                            ? Colors.grey.shade600
                            : Colors.grey.shade300,
                      ),
                    );
                  }),
                ),

              const SizedBox(height: 16.0),

              // Like, comment, share buttons
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: _handleLike,
                  ),
                  Text('${widget.post.likeCount}', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(width: 16.0),
                  IconButton(
                    icon: Icon(Icons.comment, color: Colors.grey.shade600),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommentPage(postId: widget.post.postId),
                        ),
                      );
                    },
                  ),
                  Text('${widget.post.commentCount}', style: TextStyle(color: Colors.grey.shade600)),
                  IconButton(
                    icon: Icon(Icons.share, color: Colors.grey.shade600),
                    onPressed: () {
                      // Show share bottom sheet
                      _showShareBottomSheet(context);
                    },
                  ),
                  const Spacer(),

                  // Bookmark button with animation
                  ScaleTransition(
                    scale: _animationController,
                    child: IconButton(
                      icon: Icon(
                        _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: Colors.grey.shade600,
                        size: 28,
                      ),
                      onPressed: _toggleBookmark, // Toggle bookmark state
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class FullscreenImagePage extends StatelessWidget {
  final List<String> mediaUrls;
  final int initialIndex;

  const FullscreenImagePage({super.key, required this.mediaUrls, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PhotoViewGallery.builder(
        itemCount: mediaUrls.length,
        pageController: PageController(initialPage: initialIndex),
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(mediaUrls[index]),
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 2.0,
            initialScale: PhotoViewComputedScale.contained,
            heroAttributes: PhotoViewHeroAttributes(tag: mediaUrls[index]),
          );
        },
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    );
  }
}

class VideoPost extends StatefulWidget {
  final String mediaUrl;

  const VideoPost({super.key, required this.mediaUrl});

  @override
  // ignore: library_private_types_in_public_api
  _VideoPostState createState() => _VideoPostState();
}

class _VideoPostState extends State<VideoPost> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl))
          ..initialize().then((_) {
            setState(() {});
            _chewieController = ChewieController(
              videoPlayerController: _videoPlayerController,
              aspectRatio: _videoPlayerController.value.aspectRatio,
              autoPlay: false,
              looping: true,
            );
          });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _handleVisibility(double visibleFraction) {
    if (visibleFraction > 0.5 && !_isVisible) {
      _videoPlayerController.play();
      _isVisible = true;
    } else if (visibleFraction <= 0.5 && _isVisible) {
      _videoPlayerController.pause();
      _isVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.mediaUrl),
      onVisibilityChanged: (visibilityInfo) {
        _handleVisibility(visibilityInfo.visibleFraction);
      },
      child: _chewieController != null &&
              _chewieController!.videoPlayerController.value.isInitialized
          ? Chewie(controller: _chewieController!)
          : const Center(child: CircularProgressIndicator()),
    );
  }
}


class RepostCard extends StatelessWidget {
  final Repost repost;

  const RepostCard({super.key, required this.repost});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Vertical padding for spacing
      child: Container(
        width: MediaQuery.of(context).size.width, // Full width for repost
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0), // Rounded corners
          color: Colors.white, // White background for the RepostCard
          // No border for the repost card itself
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reposter's info
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(repost.sharerProfileUrl),
                  ),
                  const SizedBox(width: 8.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        repost.sharerUsername,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Black for username/fullname
                        ),
                      ),
                      Text(
                        timeago.format(repost.sharedAt),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

              // Repost comment (if any)
              if (repost.comment != null && repost.comment!.isNotEmpty)
                Text(
                  repost.comment!,
                  style: const TextStyle(fontSize: 16.0, color: Colors.black87),
                ),
              const SizedBox(height: 12.0),

              // Original Post content inside repost (No border around posts inside repost)
              PostCard(post: repost.originalPost!),
            ],
          ),
        ),
      ),
    );
  }
}
