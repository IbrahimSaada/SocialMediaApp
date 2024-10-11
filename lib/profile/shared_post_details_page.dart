// shared_post_details_page.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cook/models/sharedpost_model.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cook/services/Post_Service.dart';
import 'package:cook/models/LikeRequest_model.dart';
import 'package:cook/models/bookmarkrequest_model.dart';
import 'package:cook/services/LoginService.dart';
import 'package:cook/home/comment.dart';

class SharedPostDetailsPage extends StatefulWidget {
  final List<SharedPostDetails> sharedPosts;
  final int initialIndex;

  const SharedPostDetailsPage({
    Key? key,
    required this.sharedPosts,
    required this.initialIndex,
  }) : super(key: key);

  @override
  _SharedPostDetailsPageState createState() => _SharedPostDetailsPageState();
}

class _SharedPostDetailsPageState extends State<SharedPostDetailsPage> with TickerProviderStateMixin {
  late ScrollController _scrollController;
  final LoginService _loginService = LoginService();

  // Lists to keep track of like status, like counts, and bookmark status for each post
  late List<bool> _isLikedList;
  late List<int> _likeCountList;
  late List<bool> _isBookmarkedList;
  late List<AnimationController> _bookmarkAnimationControllers;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: widget.initialIndex * 300.0,
    );

    // Initialize the lists
    _isLikedList = widget.sharedPosts.map((post) => post.isLiked).toList();
    _likeCountList = widget.sharedPosts.map((post) => post.likecount).toList();
    _isBookmarkedList = widget.sharedPosts.map((post) => post.isBookmarked).toList();

    // Initialize animation controllers for bookmarks
    _bookmarkAnimationControllers = List.generate(widget.sharedPosts.length, (_) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.8,
      upperBound: 1.2,
    ));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var controller in _bookmarkAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Handle like/unlike action
  Future<void> _handleLike(int index) async {
    final userId = await _loginService.getUserId();

    if (userId == null) {
      return;
    }

    final sharedPost = widget.sharedPosts[index];

    try {
      if (_isLikedList[index]) {
        // Unlike the post
        await PostService.unlikePost(
          LikeRequest(userId: userId, postId: sharedPost.postId),
        );
        setState(() {
          _isLikedList[index] = false;
          _likeCountList[index] -= 1;
        });
      } else {
        // Like the post
        await PostService.likePost(
          LikeRequest(userId: userId, postId: sharedPost.postId),
        );
        setState(() {
          _isLikedList[index] = true;
          _likeCountList[index] += 1;
        });
      }
    } catch (e) {
      if (e.toString().contains('Session expired')) {
        // Handle session expiration
        if (context.mounted) {
          handleSessionExpired(context);
        }
      } else {
        // Handle other errors
        print('Failed to like/unlike post: $e');
      }
    }
  }

  // Handle bookmark/unbookmark action
  Future<void> _handleBookmark(int index) async {
    final userId = await _loginService.getUserId();

    if (userId == null) {
      return;
    }

    final sharedPost = widget.sharedPosts[index];
    await _bookmarkAnimationControllers[index].forward();

    try {
      if (_isBookmarkedList[index]) {
        // Unbookmark the post
        await PostService.unbookmarkPost(
          BookmarkRequest(userId: userId, postId: sharedPost.postId),
        );
        setState(() {
          _isBookmarkedList[index] = false;
        });
      } else {
        // Bookmark the post
        await PostService.bookmarkPost(
          BookmarkRequest(userId: userId, postId: sharedPost.postId),
        );
        setState(() {
          _isBookmarkedList[index] = true;
        });
      }
    } catch (e) {
      if (e.toString().contains('Session expired')) {
        // Handle session expiration
        if (context.mounted) {
          handleSessionExpired(context);
        }
      } else {
        // Handle other errors
        print('Failed to bookmark/unbookmark post: $e');
      }
    }

    await _bookmarkAnimationControllers[index].reverse();
  }

  // Placeholder for session expiration handling
  void handleSessionExpired(BuildContext context) {
    // Implement your session expiration handling, e.g., navigate to login page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Session expired. Please log in again.'),
        backgroundColor: Colors.red,
      ),
    );
    // Navigate to login page or perform logout
  }

  // Navigate to Comment Page
  void _viewComments(int postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentPage(postId: postId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
          centerTitle: true,  // Center the title
          title: Text('Shared Posts', style: TextStyle(color: Color(0xFFF45F67))),
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Color(0xFFF45F67)),
        ),
      backgroundColor: Colors.grey[100],
      body: ListView.builder(
        controller: _scrollController,
        itemCount: widget.sharedPosts.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final sharedPost = widget.sharedPosts[index];
          return SharedPostCard(
            sharedPost: sharedPost,
            isLiked: _isLikedList[index],
            likeCount: _likeCountList[index],
            isBookmarked: _isBookmarkedList[index],
            bookmarkAnimationController: _bookmarkAnimationControllers[index],
            handleLike: () => _handleLike(index),
            handleBookmark: () => _handleBookmark(index),
            viewComments: () => _viewComments(sharedPost.postId),
          );
        },
      ),
    );
  }
}

class SharedPostCard extends StatelessWidget {
  final SharedPostDetails sharedPost;
  final bool isLiked;
  final int likeCount;
  final bool isBookmarked;
  final AnimationController bookmarkAnimationController;
  final VoidCallback handleLike;
  final VoidCallback handleBookmark;
  final VoidCallback viewComments;

  const SharedPostCard({
    Key? key,
    required this.sharedPost,
    required this.isLiked,
    required this.likeCount,
    required this.isBookmarked,
    required this.bookmarkAnimationController,
    required this.handleLike,
    required this.handleBookmark,
    required this.viewComments,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth,
      margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reposter Information Row with Remove Icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundImage: sharedPost.sharerProfileUrl != null
                    ? CachedNetworkImageProvider(sharedPost.sharerProfileUrl!)
                    : AssetImage('assets/images/default.png') as ImageProvider,
                radius: 18,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sharedPost.sharerUsername,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      timeago.format(sharedPost.sharedAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12.0),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.remove_circle_outline, color: Color(0xFFF45F67)),
                onPressed: () {
                  // Placeholder for delete functionality
                },
                tooltip: 'Remove Shared Post',
              ),
            ],
          ),
          // Optional Repost Comment
          if (sharedPost.comment != null && sharedPost.comment!.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            Text(
              sharedPost.comment!,
              style: const TextStyle(fontSize: 16.0, color: Colors.black87),
            ),
          ],
          const SizedBox(height: 8.0),
          // Original Post Inside the Repost
          _buildOriginalPost(context),
        ],
      ),
    );
  }

  Widget _buildOriginalPost(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
        padding: const EdgeInsets.all(12.0),
        margin: const EdgeInsets.only(top: 8.0), // Margin for spacing
        decoration: BoxDecoration(
          color: Colors.white,  // Changed to white background
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey[300]!, width: 1),  // Added grey border
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original Author Information Row
        Row(
          children: [
            CircleAvatar(
              backgroundImage: sharedPost.originalPostUserUrl != null
                  ? CachedNetworkImageProvider(sharedPost.originalPostUserUrl!)
                  : AssetImage('assets/images/default.png') as ImageProvider,
              radius: 18,
            ),
            const SizedBox(width: 8.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Aligns the text to the left
              children: [
                Text(
                  sharedPost.originalPostuserfullname,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
                Text(
                  timeago.format(sharedPost.postCreatedAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12.0),
                ),
              ],
            ),
          ],
        ),
          const SizedBox(height: 8.0),
          // Original Post Caption
          if (sharedPost.postContent.isNotEmpty)
            Text(
              sharedPost.postContent,
              style: const TextStyle(fontSize: 16.0),
            ),
          const SizedBox(height: 8.0),
          // Original Post Media Content
          _buildMediaContent(screenWidth),
          const SizedBox(height: 8.0),
          // Original Post Actions
          _buildPostActions(),
        ],
      ),
    );
  }

  Widget _buildMediaContent(double screenWidth) {
    if (sharedPost.media.isEmpty) {
      return const SizedBox.shrink();
    }

    double mediaHeight = screenWidth * 0.75;
    double maxHeight = 300.0;
    if (mediaHeight > maxHeight) {
      mediaHeight = maxHeight;
    }

    return SizedBox(
      height: mediaHeight,
       width: screenWidth,  // Explicitly set to full screen width
      child: PageView.builder(
        itemCount: sharedPost.media.length,
        itemBuilder: (context, index) {
          final media = sharedPost.media[index];
          if (media.mediaType == 'photo') {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: CachedNetworkImage(
                imageUrl: media.mediaUrl,
                fit: BoxFit.cover,
                width: screenWidth,
                height: mediaHeight,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            );
          } else if (media.mediaType == 'video') {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: VideoPost(mediaUrl: media.mediaUrl),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

Widget _buildPostActions() {
  return Row(
    children: [
      // Like Button with Border
      IconButton(
        icon: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              color: Color(0xFFF45F67), // Primary color for the border
              size: 28,
            ),
            if (isLiked)
              Icon(
                Icons.favorite,
                color: Color(0xFFF45F67), // Filled primary color when liked
                size: 28,
              ),
          ],
        ),
        onPressed: handleLike,
      ),
      Text(
        '$likeCount',
        style: TextStyle(color: Color(0xFFF45F67)),
      ),
      const SizedBox(width: 16.0),

      // Comment Button with Border
      IconButton(
        icon: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.comment,
              color: Color(0xFFF45F67), // Primary color for the border
              size: 28,
            ),
            Icon(
              Icons.comment,
              color: Colors.transparent, // Transparent to show only the border
              size: 28,
            ),
          ],
        ),
        onPressed: viewComments,
      ),
      Text(
        '${sharedPost.commentcount}',
        style: TextStyle(color: Color(0xFFF45F67)),
      ),
      const SizedBox(width: 16.0),
      
      const Spacer(),

      // Bookmark Button with Border
      ScaleTransition(
        scale: bookmarkAnimationController,
        child: IconButton(
          icon: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.bookmark_border,
                color: Color(0xFFF45F67), // Primary color for the border
                size: 28,
              ),
              if (isBookmarked)
                Icon(
                  Icons.bookmark,
                  color: Color(0xFFF45F67), // Filled primary color when bookmarked
                  size: 28,
                ),
            ],
          ),
          onPressed: handleBookmark,
        ),
      ),
    ],
  );
}
}

class VideoPost extends StatefulWidget {
  final String mediaUrl;

  const VideoPost({Key? key, required this.mediaUrl}) : super(key: key);

  @override
  _VideoPostState createState() => _VideoPostState();
}

class _VideoPostState extends State<VideoPost> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final file = await DefaultCacheManager().getSingleFile(widget.mediaUrl);
      _videoPlayerController = VideoPlayerController.file(file);
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        placeholder: Container(
          color: Colors.black12,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorBuilder: (context, errorMessage) {
          return const Center(
            child: Icon(Icons.error, color: Colors.red),
          );
        },
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing video: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError || _chewieController == null) {
      return const Center(child: Icon(Icons.error, color: Colors.red));
    }
    return Chewie(controller: _chewieController!);
  }
}
