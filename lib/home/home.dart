import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cook/home/add_friends_page.dart';
import 'package:cook/home/contacts_page.dart';
import 'package:cook/home/notification_page.dart';
import 'package:cook/menu/menu_page.dart';
import 'package:cook/services/LoginService.dart';
import 'package:cook/models/LikeRequest_model.dart';
import 'package:cook/home/comment.dart';
import 'package:cook/services/post_service.dart';
import 'package:cook/models/post_model.dart';
import 'package:cook/models/repost_model.dart';
import 'package:cook/services/RepostServices.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:cook/home/posting.dart';
import 'package:cook/home/search.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cook/home/report_dialog.dart';
import 'package:cook/home/share.dart';
import 'package:cook/home/story.dart';
import 'package:cook/home/full_screen_story_view.dart';
import 'package:cook/models/story_model.dart' as story_model;
import 'package:cook/services/StoryService.dart'; // Import Story service
import 'package:cook/models/storyview_request_model.dart';
import 'package:cook/services/storyview_Service.dart';
import 'package:cook/askquestion/qna_page.dart';
import 'package:cook/maintenance/expiredtoken.dart';  // Importing the expired token handler
import 'package:cook/models/bookmarkrequest_model.dart';
import 'package:cook/profile/otheruserprofilepage.dart';
import 'package:cook/profile/profile_page.dart';

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
  bool _isLoading = false;



  @override
  void initState() {
    super.initState();
    _initializeApp();
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
  setState(() {
    _isLoading = true;
  });
  
  try {
    bool isLoggedIn = await LoginService().isLoggedIn();
    if (isLoggedIn) {
      await _fetchPostsAndReposts();
    } else {
      // ignore: use_build_context_synchronously
      handleSessionExpired(context);
    }
  } catch (e) {
    print('Initialization failed: $e');
  } finally {
    setState(() {
      _isLoading = false;
    });
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
  setState(() {
    _isLoading = true;
  });

  await _fetchPostsAndReposts();
  await _fetchStories();

  setState(() {
    _isLoading = false;
  });
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

PreferredSizeWidget buildTopAppBar(BuildContext context) {
  return AppBar(
    backgroundColor: const Color(0xFFF45F67), // Primary color for the app
    automaticallyImplyLeading: false,
    elevation: 0,
    leading: Padding(
      padding: const EdgeInsets.only(left: 16.0), // Consistent left padding
      child: IconButton(
        padding: EdgeInsets.zero, // Remove default padding
        icon: FutureBuilder<String?>(
          future: LoginService().getProfilePic(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircleAvatar(
                backgroundImage: AssetImage('assets/images/default.png'),
              );
            } else if (snapshot.hasData && snapshot.data != null) {
              return CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(snapshot.data!),
              );
            } else {
              return const CircleAvatar(
                backgroundImage: AssetImage('assets/images/default.png'),
              );
            }
          },
        ),
        onPressed: () {
          // Open Menu Page
          showDialog(
            context: context,
            builder: (context) => MenuPage(),
          );
        },
      ),
    ),
    title: Text(
      'CookTalk',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1.2,
        shadows: [
          Shadow(
            blurRadius: 5.0,
            color: Color(0xFFF45F67).withOpacity(0.6),
            offset: Offset(2.0, 2.0),
          ),
          Shadow(
            blurRadius: 5.0,
            color: Colors.black.withOpacity(0.3),
            offset: Offset(-2.0, -2.0),
          ),
        ],
      ),
    ),
    centerTitle: true, // Center the title
  );
}


Widget buildBottomNavigationBar() {
  return BottomAppBar(
    color: const Color(0xFFF45F67), // Main color for BottomAppBar
    shape: const CircularNotchedRectangle(),
    notchMargin: 4.0, // Margin for the center notch around the search icon
    child: SizedBox(
      height: 50, // Reduced height for a more compact BottomAppBar
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Left side icons
          IconButton(
            icon: const Icon(Icons.person_add_alt, size: 24, color: Colors.white), // Modern 'Add Friend' icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddFriendsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, size: 24, color: Colors.white), // Modern 'Notification' icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationPage()),
              );
            },
          ),
          const SizedBox(width: 40), // Spacer to center items around the notch

          // Right side icons
          IconButton(
            icon: const Icon(Icons.help_outline, size: 24, color: Colors.white), // Modern 'Help' icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QnaPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, size: 24, color: Colors.white), // Modern 'Chat' icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ContactsPage()),
              );
            },
          ),
        ],
      ),
    ),
  );
}


Widget buildSearchIcon() {
  return Positioned(
    bottom: -22, // Adjusted to ensure the circle sits within the bar
    child: Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.search, color: Color(0xFFF45F67), size: 24), // Modern search icon inside white circle
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Search()),
          );
        },
      ),
    ),
  );
}



FloatingActionButton buildCenterSearchButton() {
  return FloatingActionButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Search()),
      );
    },
    backgroundColor: Colors.white,
    child: const Icon(Icons.search, color: Color(0xFFF45F67)), // Main color for the search icon
  );
}


Widget buildDivider() {
  return const Divider(
    thickness: 1.5, // Thickness of the divider
    color: Color(0xFFF45F67), // Light bronze color
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
            itemCount: _stories.isNotEmpty ? _stories.length + 1 : 5, // Show 5 shimmer boxes if loading
            itemBuilder: (context, index) {
              if (_isLoading) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                );
              }

              if (index == 0) {
                return StoryBox(onStoriesUpdated: _addStories);
              }

              final story = _stories[index - 1];
              if (story.media.isEmpty) {
                return Container(); // Skip if no media
              }

              return GestureDetector(
                onTap: () => _viewStoryFullscreen(index - 1),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: Color(0xFFF45F67), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 3,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(story.media[0].mediaUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
  final combinedPostsAndReposts = List.from(_posts)..addAll(_reposts);

  combinedPostsAndReposts.sort((a, b) {
    final aTime = a is Post ? a.localCreatedAt : a.sharedAt;
    final bTime = b is Post ? b.localCreatedAt : b.sharedAt;
    return bTime.compareTo(aTime);
  });

  return Scaffold(
    appBar: buildTopAppBar(context),
    body: RefreshIndicator(
      onRefresh: _refreshPosts, // This will trigger the refresh only at the top
      color: Color(0xFFF45F67), // Primary color of the refresh indicator
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh is available
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildStoriesSection(),
            buildDivider(),
            buildPostInputSection(),
            buildDivider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: combinedPostsAndReposts.isEmpty ? 0 : combinedPostsAndReposts.length,
              itemBuilder: (context, index) {
                return buildPostOrRepost(combinedPostsAndReposts[index]);
              },
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: buildBottomNavigationBar(),
    floatingActionButton: buildSearchIcon(),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
  );
}



Widget buildPostInputSection() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF45F67), width: 2),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.kitchen, color: Color(0xFFF45F67)),
            onPressed: () {
              // Add functionality for the cuisine icon
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePostPage(),
                  ),
                );
              },
              child: const Text(
                'What do you want to share',
                style: TextStyle(
                  color: Color(0xFFF45F67),
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1, // Ensures text stays on one line
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.restaurant, color: Color(0xFFF45F67)),
            onPressed: () {
              // Add functionality for the restaurant icon
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
                  GestureDetector(
                    onTap: () async {
                      int? currentUserId = await LoginService().getUserId(); // Fetch current user's ID
                      if (currentUserId == widget.post.userId) {
                        // If it's the logged-in user, navigate to ProfilePage
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(), // Navigate to ProfilePage
                          ),
                        );
                      } else {
                        // If it's another user, navigate to OtherUserProfilePage
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OtherUserProfilePage(
                              otherUserId: widget.post.userId, // Navigate to the other user's profile
                            ),
                          ),
                        );
                      }
                    },
                    child: CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(widget.post.profilePic),
                          onBackgroundImageError: (_, __) {
                            // Optionally handle the error
                          },
                        )

                  ),
                  const SizedBox(width: 8.0),
                  GestureDetector(
                    onTap: () async {
                      int? currentUserId = await LoginService().getUserId(); // Fetch current user's ID
                      if (currentUserId == widget.post.userId) {
                        // If it's the logged-in user, navigate to ProfilePage
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(), // Navigate to ProfilePage
                          ),
                        );
                      } else {
                        // If it's another user, navigate to OtherUserProfilePage
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OtherUserProfilePage(
                              otherUserId: widget.post.userId, // Navigate to the other user's profile
                            ),
                          ),
                        );
                      }
                    },
                    child: Column(
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
                  ),
                  const Spacer(),
                  if (_currentUserId != widget.post.userId)
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'hide',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_off, color: Color(0xFFF45F67)),
                              const SizedBox(width: 10),
                              Text('Hide this post', style: TextStyle(color: Color(0xFFF45F67))),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Color(0xFFF45F67)),
                              const SizedBox(width: 10),
                              Text('Report', style: TextStyle(color: Color(0xFFF45F67))),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(Icons.block, color: Color(0xFFF45F67)),
                              const SizedBox(width: 10),
                              Text('Block', style: TextStyle(color: Color(0xFFF45F67))),
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
                      child: Icon(Icons.more_vert, color: Color(0xFFF45F67)),
                    ),
                ],
              ),
              const SizedBox(height: 12.0),

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
                      color: Color(0xFFF45F67),
                    ),
                    onPressed: _handleLike,
                  ),
                  Text('${widget.post.likeCount}', style: TextStyle(color: Color(0xFFF45F67))),
                  const SizedBox(width: 16.0),
                  IconButton(
                    icon: Icon(Icons.comment, color: Color(0xFFF45F67)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommentPage(postId: widget.post.postId),
                        ),
                      );
                    },
                  ),
                  Text('${widget.post.commentCount}', style: TextStyle(color: Color(0xFFF45F67))),
                  IconButton(
                    icon: Icon(Icons.share, color: Color(0xFFF45F67)),
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
                        color: Color(0xFFF45F67),
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
          border: Border.all(color: Colors.grey.shade300, width: 1.0), // Outer border only
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
                    backgroundImage: CachedNetworkImageProvider(repost.sharerProfileUrl),
                    onBackgroundImageError: (_, __) {
                      // Optionally handle the error
                    },
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

              // Original Post content inside repost (PostCard itself manages its own design)
              PostCard(post: repost.originalPost!), // Display original post inside
            ],
          ),
        ),
      ),
    );
  }
}
