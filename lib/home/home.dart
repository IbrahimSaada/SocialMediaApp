// home/home.dart

import 'package:flutter/material.dart';
import 'post_card.dart';
import 'repost_card.dart';
import '***REMOVED***/services/loginservice.dart';
import '***REMOVED***/maintenance/expiredtoken.dart';
import 'posting.dart';
import '***REMOVED***/services/feed_service.dart';
import '***REMOVED***/models/feed/feed_item.dart';
import '***REMOVED***/models/feed/post_item.dart';
import '***REMOVED***/models/feed/repost_item.dart';
import 'story_section.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/rendering.dart';
import 'app_bar.dart'; // Import the app_bar.dart
import 'bottom_navigation_bar.dart'; // Import the bottom_navigation_bar.dart
import 'shimmer_post_card.dart';
import 'shimmer_repost_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<FeedItem> _feedItems = [];
  int _currentPageNumber = 1;
  final int _pageSize = 10;
  bool _isFetchingData = false;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  int? _userId;

  bool _isBarVisible = true; // Bar visibility flag
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _scrollController.addListener(_scrollListener);

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Initially, make sure both bars are visible
    _animationController.value = 1.0; // Fully expanded (visible)
  }

  void _scrollListener() {
    // Hide the AppBar and BottomNavigationBar when scrolling down
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isBarVisible) {
        _animationController.reverse(); // Hide bars
        setState(() {
          _isBarVisible = false;
        });
      }
    }
    // Show the AppBar and BottomNavigationBar when scrolling up
    else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isBarVisible) {
        _animationController.forward(); // Show bars
        setState(() {
          _isBarVisible = true;
        });
      }
    }

    // Pagination logic: Load more data when reaching near the bottom of the list
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isFetchingData &&
        _hasMoreData) {
      _fetchMoreFeed();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  Future<void> _initializeApp() async {
    try {
      bool isLoggedIn = await LoginService().isLoggedIn();
      if (isLoggedIn) {
        _userId = await LoginService().getUserId();
        await _fetchFeed();
      } else {
        if (context.mounted) {
          handleSessionExpired(context);
        }
      }
    } catch (e) {
      print('Initialization failed: $e');
    }
  }

  Future<void> _fetchFeed() async {
    try {
      setState(() {
        _isFetchingData = true;
        _currentPageNumber = 1; // Reset to first page when refreshing
        _hasMoreData = true;
      });
      if (_userId != null) {
        List<FeedItem> feedItems = await FeedService().fetchFeed(
          userId: _userId!,
          pageNumber: _currentPageNumber,
          pageSize: _pageSize,
        );
        setState(() {
          _feedItems = feedItems;
          _isFetchingData = false;
          _hasMoreData = feedItems.length == _pageSize;
        });
      }
    } catch (e) {
      setState(() {
        _isFetchingData = false;
      });
      print('Failed to load feed: $e');
    }
  }

Future<void> _fetchMoreFeed() async {
  if (_isFetchingData || !_hasMoreData) return;

  try {
    setState(() {
      _isFetchingData = true;
      _currentPageNumber++;
    });

    if (_userId != null) {
      // Fetch the new feed items
      List<FeedItem> newFeedItems = await FeedService().fetchFeed(
        userId: _userId!,
        pageNumber: _currentPageNumber,
        pageSize: _pageSize,
      );

      if (newFeedItems.isNotEmpty) {
        setState(() {
          // Add only unique feed items to avoid duplication
          _feedItems.addAll(
            newFeedItems.where((newItem) => !_feedItems.contains(newItem)).toList(),
          );
          _isFetchingData = false;
          _hasMoreData = newFeedItems.length == _pageSize;
        });
      } else {
        // No more data available
        setState(() {
          _isFetchingData = false;
          _hasMoreData = false;
        });
      }
    }
  } catch (e) {
    setState(() {
      _isFetchingData = false;
      _currentPageNumber--; // Decrement page number if fetching fails
    });
    print('Failed to load more feed: $e');
  }
}

  Future<void> _refreshFeed() async {
    await _fetchFeed();
  }

  Widget buildDivider() {
    return Divider(
      thickness: 1.5,
      color: Colors.grey[300],
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
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
          ),
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
                  maxLines: 1,
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

  Widget buildFeedItem(FeedItem item) {
    if (item is PostItem) {
      return PostCard(
        postInfo: item.post,
        author: item.post.author ?? item.user,
        isLiked: item.isLiked,
        isBookmarked: item.isBookmarked,
        createdAt: item.createdAt,
        content: item.content,
      );
    } else if (item is RepostItem) {
      return RepostCard(feedItem: item);
    } else {
      return Container(); // Handle unknown types gracefully
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[100], // Neutral background for other areas
    appBar: PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: SizeTransition(
        sizeFactor: _animation,
        axisAlignment: -1.0,
        child: buildTopAppBar(context),
      ),
    ),
    body: RefreshIndicator(
      onRefresh: _refreshFeed,
      color: const Color(0xFFF45F67),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _isFetchingData && _feedItems.isEmpty ? 6 : _feedItems.length + 6, // Show shimmer if loading and feed is empty
        itemBuilder: (context, index) {
          if (index == 0) {
            return StorySection(userId: _userId);
          } else if (index == 1) {
            return buildDivider();
          } else if (index == 2) {
            return buildPostInputSection();
          } else if (index == 3) {
            return buildDivider();
          } else if (index - 4 < _feedItems.length) {
            // Display actual feed item when data is loaded
            return Container(
              color: Colors.grey[100], // Background color for posts and reposts
              child: buildFeedItem(_feedItems[index - 4]),
            );
          } else if (_isFetchingData && _feedItems.isEmpty) {
            // Show shimmer effect while loading
            return index % 2 == 0 
              ? const ShimmerPostCard() 
              : const ShimmerRepostCard();
          } else if (index == _feedItems.length + 4) {
            // Show loading indicator at the bottom if more data is being fetched
            return _hasMoreData
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(color: const Color(0xFFF45F67)),
                    ),
                  )
                : const SizedBox.shrink();
          } else if (index == _feedItems.length + 5) {
            // Grey background for the area below posts and reposts
            return Container(
              height: 100, // Set appropriate height for the grey area
              color: Colors.grey[300], // Grey color for the bottom
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    ),
    bottomNavigationBar: SizeTransition(
      sizeFactor: _animation,
      axisAlignment: 1.0,
      child: buildBottomNavigationBar(context),
    ),
  );
}


}