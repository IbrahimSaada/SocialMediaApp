import 'package:flutter/material.dart';
import '../services/SessionExpiredException.dart';
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
import 'app_bar.dart';
// IMPORTANT: Import your new bottom nav bar file
import 'bottom_navigation_bar.dart';
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
  Map<int, Map<String, dynamic>> _postStates = {};
  bool _isBarVisible = true;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _scrollController.addListener(_scrollListener);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.value = 1.0;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Hide top/bottom bars on scroll
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isBarVisible) {
        _animationController.reverse();
        setState(() {
          _isBarVisible = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isBarVisible) {
        _animationController.forward();
        setState(() {
          _isBarVisible = true;
        });
      }
    }

    // Load more feed items when near the bottom
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isFetchingData &&
        _hasMoreData) {
      _fetchMoreFeed();
    }
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
        _currentPageNumber = 1;
        _hasMoreData = true;
      });
      if (_userId != null) {
        List<FeedItem> feedItems = await FeedService().fetchFeed(
          userId: _userId!,
          pageNumber: _currentPageNumber,
          pageSize: _pageSize,
        );
        _updatePostStatesFromFeed(feedItems);
        setState(() {
          _feedItems = feedItems;
          _isFetchingData = false;
          _hasMoreData = feedItems.length == _pageSize;
        });
      }
    } on SessionExpiredException {
      setState(() {
        _isFetchingData = false;
      });
      if (context.mounted) {
        handleSessionExpired(context);
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
        List<FeedItem> newFeedItems = await FeedService().fetchFeed(
          userId: _userId!,
          pageNumber: _currentPageNumber,
          pageSize: _pageSize,
        );

        if (newFeedItems.isNotEmpty) {
          // Update global post states
          _updatePostStatesFromFeed(newFeedItems);
        }

        if (newFeedItems.isNotEmpty) {
          setState(() {
            _feedItems.addAll(
              newFeedItems.where((newItem) => !_feedItems.contains(newItem)).toList(),
            );
            _isFetchingData = false;
            _hasMoreData = newFeedItems.length == _pageSize;
          });
        } else {
          setState(() {
            _isFetchingData = false;
            _hasMoreData = false;
          });
        }
      }
    } on SessionExpiredException {
      setState(() {
        _isFetchingData = false;
        _currentPageNumber--;
      });
      if (context.mounted) {
        handleSessionExpired(context);
      }
    } catch (e) {
      setState(() {
        _isFetchingData = false;
        _currentPageNumber--;
      });
      print('Failed to load more feed: $e');
    }
  }

  Future<void> _refreshFeed() async {
    await _fetchFeed();
  }

  void _updatePostStatesFromFeed(List<FeedItem> items) {
    for (var item in items) {
      int? postId;
      bool? isLiked;
      int? likeCount;

      if (item is PostItem) {
        postId = item.post.postId;
        isLiked = item.isLiked;
        likeCount = item.post.likeCount;
      } else if (item is RepostItem) {
        postId = item.post.postId;
        isLiked = item.isLiked;
        likeCount = item.post.likeCount;
      }

      if (postId != null && isLiked != null && likeCount != null) {
        _postStates[postId] = {
          "isLiked": isLiked,
          "likeCount": likeCount,
        };
      }
    }
  }

  /// Called by PostCard/RepostCard to update global state (like/unlike)
  void updatePostState(int postId, bool isLiked, int likeCount) {
    setState(() {
      _postStates[postId] = {
        "isLiked": isLiked,
        "likeCount": likeCount,
      };
    });
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
                onTap: () async {
                  // Navigate to CreatePostPage and wait for result
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatePostPage(),
                    ),
                  );
                  // If the result is true, refresh the feed
                  if (result == true) {
                    _refreshFeed();
                  }
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
        onPostStateChange: updatePostState, // new
        globalPostStates: _postStates,      // new
      );
    } else if (item is RepostItem) {
      return RepostCard(
        feedItem: item,
        onPostStateChange: updatePostState, // new
        globalPostStates: _postStates,      // new
      );
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
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
          itemCount: _isFetchingData ? 10 : _feedItems.length + 6,
          itemBuilder: (context, index) {
            if (index == 0) {
              return StorySection(userId: _userId);
            } else if (index == 1) {
              return buildDivider();
            } else if (index == 2) {
              return buildPostInputSection();
            } else if (index == 3) {
              return buildDivider();
            } else if (_isFetchingData) {
              // Show shimmer placeholders
              return index % 2 == 0
                  ? const ShimmerPostCard()
                  : const ShimmerRepostCard();
            } else if (index - 4 < _feedItems.length) {
              return Container(
                color: Colors.grey[100],
                child: buildFeedItem(_feedItems[index - 4]),
              );
            } else if (index == _feedItems.length + 4) {
              // If we have more data to load, show a loading indicator
              return _hasMoreData
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: const Color(0xFFF45F67),
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            } else if (index == _feedItems.length + 5) {
              // Extra space at the bottom
              return Container(
                height: 100,
                color: Colors.grey[300],
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ),
      // Use your new bottom nav bar widget instead of buildBottomNavigationBar()
      bottomNavigationBar: SizeTransition(
        sizeFactor: _animation,
        axisAlignment: 1.0,
        child: const BottomNavigationBarCook(),
      ),
    );
  }
}
