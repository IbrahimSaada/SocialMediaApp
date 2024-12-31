import '***REMOVED***/services/Userprofile_service.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '***REMOVED***/models/sharedpost_model.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '***REMOVED***/services/Post_Service.dart';
import '***REMOVED***/models/LikeRequest_model.dart';
import '***REMOVED***/models/bookmarkrequest_model.dart';
import '***REMOVED***/services/LoginService.dart';
import '***REMOVED***/home/comment.dart';
import '***REMOVED***/home/report_dialog.dart';
import '***REMOVED***/services/SessionExpiredException.dart';
import '***REMOVED***/maintenance/expiredtoken.dart';
import '***REMOVED***/services/userpost_service.dart';

class SharedPostDetailsPage extends StatefulWidget {
  final List<SharedPostDetails> sharedPosts;
  final int initialIndex;
  final bool isCurrentUserProfile; // Add this flag

  SharedPostDetailsPage({
    Key? key,
    required List<SharedPostDetails> sharedPosts,
    required this.initialIndex,
    required this.isCurrentUserProfile, // Pass this flag
  })  : sharedPosts = sharedPosts
            .toList()
            ..sort((a, b) => b.sharedAt.compareTo(a.sharedAt)),
        super(key: key);

  @override
  _SharedPostDetailsPageState createState() => _SharedPostDetailsPageState();
}

class _SharedPostDetailsPageState extends State<SharedPostDetailsPage>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  final LoginService _loginService = LoginService();
  final UserProfileService _userProfileService = UserProfileService();
  final UserpostService _userpostService = UserpostService();

  // Lists to keep track of like status, like counts, and bookmark status
  late List<bool> _isLikedList;
  late List<int> _likeCountList;
  late List<bool> _isBookmarkedList;
  late List<AnimationController> _bookmarkAnimationControllers;

  // Pagination variables
  bool isPaginating = false;
  bool hasMoreSharedPosts = true;
  int currentPageNumber = 1;
  final int pageSize = 10;
  int? userId;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: widget.initialIndex * 300.0,
    );
    _scrollController.addListener(_scrollListener);

    _loginService.getUserId().then((id) {
      setState(() {
        userId = id;
      });
    });

    // Calculate initial page number based on already loaded posts
    currentPageNumber = 1 + (widget.sharedPosts.length ~/ pageSize);

    // Initialize helper lists
    _isLikedList = widget.sharedPosts.map((post) => post.isLiked).toList();
    _likeCountList = widget.sharedPosts.map((post) => post.likecount).toList();
    _isBookmarkedList =
        widget.sharedPosts.map((post) => post.isBookmarked).toList();

    // Create bookmark animation controllers
    _bookmarkAnimationControllers = List.generate(
      widget.sharedPosts.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
        lowerBound: 0.8,
        upperBound: 1.2,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    for (var controller in _bookmarkAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent &&
        !isPaginating &&
        hasMoreSharedPosts) {
      _fetchMoreSharedPosts();
    }
  }

  Future<void> _fetchMoreSharedPosts() async {
    if (isPaginating || !hasMoreSharedPosts || userId == null) return;

    setState(() {
      isPaginating = true;
    });

    try {
      List<SharedPostDetails> newSharedPosts = await _userpostService.fetchSharedPosts(
        userId!, // The user whose shared posts are being viewed
        userId!,
        currentPageNumber,
        pageSize,
      );

      setState(() {
        final existingShareIds = widget.sharedPosts.map((p) => p.shareId).toSet();
        final uniqueNewPosts = newSharedPosts
            .where((p) => !existingShareIds.contains(p.shareId))
            .toList();

        widget.sharedPosts.addAll(uniqueNewPosts);

        // If we exactly got "pageSize" items, there's potentially more to load
        if (newSharedPosts.length == pageSize) {
          currentPageNumber++;
        } else {
          hasMoreSharedPosts = false;
        }
        isPaginating = false;

        // Update helper lists
        _isLikedList.addAll(uniqueNewPosts.map((p) => p.isLiked));
        _likeCountList.addAll(uniqueNewPosts.map((p) => p.likecount));
        _isBookmarkedList.addAll(uniqueNewPosts.map((p) => p.isBookmarked));
        _bookmarkAnimationControllers.addAll(
          List.generate(uniqueNewPosts.length, (_) {
            return AnimationController(
              vsync: this,
              duration: const Duration(milliseconds: 300),
              lowerBound: 0.8,
              upperBound: 1.2,
            );
          }),
        );
      });
    } on SessionExpiredException {
      print("SessionExpired detected in _fetchMoreSharedPosts");
      handleSessionExpired(context);
      setState(() {
        isPaginating = false;
      });
    } catch (e) {
      print('Error fetching more shared posts: $e');
      setState(() {
        isPaginating = false;
      });
    }
  }

  Future<void> _editSharedPostComment(SharedPostDetails sharedPost, String newComment) async {
    final userId = await _loginService.getUserId();
    if (userId == null) return;

    try {
      bool success = await _userProfileService.editSharedPostComment(
        sharedPost.shareId,
        newComment,
        userId,
      );

      if (success) {
        setState(() {
          sharedPost.comment = newComment; 
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Shared post comment updated successfully!'),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to update shared post comment.'),
          backgroundColor: Colors.red,
        ));
      }
    } on SessionExpiredException {
      print('SessionExpired detected in _editSharedPostComment');
      handleSessionExpired(context);
    } catch (e) {
      print('Error updating shared post comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('An error occurred while updating the shared post comment.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _deleteSharedPost(int index) async {
    final userId = await LoginService().getUserId();
    if (userId == null) return;

    try {
      bool success = await _userProfileService.deleteSharedPost(
        widget.sharedPosts[index].shareId,
        userId,
      );

      if (success) {
        setState(() {
          widget.sharedPosts.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Shared post deleted successfully!'),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to delete the shared post'),
          backgroundColor: Colors.red,
        ));
      }
    } on SessionExpiredException {
      print('SessionExpired detected in _deleteSharedPost');
      handleSessionExpired(context);
    } catch (e) {
      print('Error occurred while deleting sharedpost: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('An error occurred while deleting the sharedpost'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Handle like/unlike action
  Future<void> _handleLike(int index) async {
    final userId = await _loginService.getUserId();
    if (userId == null) return;

    final sharedPost = widget.sharedPosts[index];
    try {
      if (_isLikedList[index]) {
        // Unlike
        await PostService.unlikePost(
          LikeRequest(userId: userId, postId: sharedPost.postId),
        );
        setState(() {
          _isLikedList[index] = false;
          _likeCountList[index] -= 1;
        });
      } else {
        // Like
        await PostService.likePost(
          LikeRequest(userId: userId, postId: sharedPost.postId),
        );
        setState(() {
          _isLikedList[index] = true;
          _likeCountList[index] += 1;
        });
      }
    } catch (e) {
      print('Failed to like/unlike post: $e');
    }
  }

  // Handle bookmark/unbookmark action
  Future<void> _handleBookmark(int index) async {
    final userId = await _loginService.getUserId();
    if (userId == null) return;

    final sharedPost = widget.sharedPosts[index];
    await _bookmarkAnimationControllers[index].forward();

    try {
      if (_isBookmarkedList[index]) {
        await PostService.unbookmarkPost(
          BookmarkRequest(userId: userId, postId: sharedPost.postId),
        );
        setState(() {
          _isBookmarkedList[index] = false;
        });
      } else {
        await PostService.bookmarkPost(
          BookmarkRequest(userId: userId, postId: sharedPost.postId),
        );
        setState(() {
          _isBookmarkedList[index] = true;
        });
      }
    } catch (e) {
      print('Failed to bookmark/unbookmark post: $e');
    }

    await _bookmarkAnimationControllers[index].reverse();
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
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Shared Posts', style: TextStyle(color: Color(0xFFF45F67))),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFFF45F67)),
      ),
      backgroundColor: Colors.grey[100],
      body: widget.sharedPosts.isEmpty
          ? const Center(
              child: Text(
                'No shared posts yet.',
                style: TextStyle(fontSize: 18.0, color: Colors.grey),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              itemCount: widget.sharedPosts.length + (isPaginating ? 1 : 0),
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                if (index == widget.sharedPosts.length) {
                  // Loading indicator at the end
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFF45F67),
                    ),
                  );
                }

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
                  isCurrentUserProfile: widget.isCurrentUserProfile,
                  handleEdit: (newComment) => _editSharedPostComment(sharedPost, newComment),
                  handleDelete: () => _deleteSharedPost(index),
                );
              },
            ),
    );
  }
}

class SharedPostCard extends StatefulWidget {
  final SharedPostDetails sharedPost;
  final bool isLiked;
  final int likeCount;
  final bool isBookmarked;
  final AnimationController bookmarkAnimationController;
  final VoidCallback handleLike;
  final VoidCallback handleBookmark;
  final VoidCallback viewComments;
  final bool isCurrentUserProfile;
  final Function(String) handleEdit;
  final VoidCallback handleDelete;

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
    required this.isCurrentUserProfile,
    required this.handleEdit,
    required this.handleDelete,
  }) : super(key: key);

  @override
  _SharedPostCardState createState() => _SharedPostCardState();
}

class _SharedPostCardState extends State<SharedPostCard> {
  bool _isEditingComment = false; // For editing shared comment
  late TextEditingController _commentController;

  // For "Show More / Show Less" expansions
  bool _isSharedCommentExpanded = false;
  bool _isOriginalContentExpanded = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.sharedPost.comment ?? '');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toggleEditComment() {
    setState(() {
      _isEditingComment = !_isEditingComment;
      // If user cancels editing, revert the text
      if (!_isEditingComment) {
        _commentController.text = widget.sharedPost.comment ?? '';
      }
    });
  }

  void _saveEditedComment() {
    widget.handleEdit(_commentController.text); // Update comment in backend
    setState(() {
      _isEditingComment = false;
    });
  }

  void _showPostOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Choose an Action",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                    color: Color(0xFFF45F67),
                  ),
                ),
                const SizedBox(height: 16.0),
                Divider(color: Colors.grey[300], thickness: 1.0),
                const SizedBox(height: 12.0),

                // If it's the current user's profile
                if (widget.isCurrentUserProfile) ...[
                  ListTile(
                    leading: const Icon(Icons.edit, color: Color(0xFFF45F67)),
                    title: const Text(
                      'Edit Comment',
                      style: TextStyle(color: Color(0xFFF45F67)),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _toggleEditComment();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.delete, color: Colors.red[400]),
                    title: Text(
                      'Delete Post',
                      style: TextStyle(color: Colors.red[400]),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(context);
                    },
                  ),
                ] else ...[
                  // If it's another user, show "Report Post"
                  ListTile(
                    leading: Icon(Icons.report, color: Colors.red[400]),
                    title: Text(
                      'Report Post',
                      style: TextStyle(color: Colors.red[400]),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.sharedPost.originalPostUserId != null) {
                        final int userId = widget.sharedPost.originalPostUserId!;
                        showReportDialog(
                          context: context,
                          reportedUser: userId,
                          contentId: widget.sharedPost.postId,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User ID not available for this post.')),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          backgroundColor: Colors.white,
          title: const Text(
            "Confirm Deletion",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
              color: Color(0xFFF45F67),
            ),
          ),
          content: const Text(
            "Are you sure you want to delete this post?",
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.handleDelete();
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

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
          /// =========== Sharer (Re-poster) Header =============
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundImage: widget.sharedPost.sharerProfileUrl != null
                    ? CachedNetworkImageProvider(widget.sharedPost.sharerProfileUrl!)
                    : const AssetImage('assets/images/default.png') as ImageProvider,
                radius: 18,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.sharedPost.sharerUsername,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      timeago.format(widget.sharedPost.sharedAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12.0),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFFF45F67)),
                onPressed: () {
                  _showPostOptions(context);
                },
              ),
            ],
          ),

          /// =========== Shared Post's Comment (if any) ===========
          if (_isEditingComment)
            _buildCommentEditor()
          else if (widget.sharedPost.comment != null && widget.sharedPost.comment!.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            // If expanded, show entire comment. Otherwise, show truncated.
            if (!_isSharedCommentExpanded)
              Text(
                widget.sharedPost.comment!,
                overflow: TextOverflow.ellipsis,
              )
            else
              Text(widget.sharedPost.comment!),

            // Only show toggle if text is long
            if (widget.sharedPost.comment!.length > 100)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isSharedCommentExpanded = !_isSharedCommentExpanded;
                  });
                },
                child: Text(
                  _isSharedCommentExpanded ? 'Show Less' : 'Show More',
                  style: const TextStyle(color: Color(0xFFF45F67)),
                ),
              ),
          ],

          /// =========== Original Post Content =============
          const SizedBox(height: 8.0),
          _buildOriginalPost(context),
        ],
      ),
    );
  }

  /// Editing the re-poster's comment
  Widget _buildCommentEditor() {
    return Column(
      children: [
        TextField(
          controller: _commentController,
          decoration: InputDecoration(
            hintText: 'Edit your comment...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _toggleEditComment,
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: _saveEditedComment,
              child: const Text('Save', style: TextStyle(color: Color(0xFFF45F67))),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the original post snippet (author, content, media, etc.)
  Widget _buildOriginalPost(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.only(top: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// =========== Original Post Header =============
          Row(
            children: [
              CircleAvatar(
                backgroundImage: widget.sharedPost.originalPostUserUrl != null
                    ? CachedNetworkImageProvider(widget.sharedPost.originalPostUserUrl!)
                    : const AssetImage('assets/images/default.png') as ImageProvider,
                radius: 18,
              ),
              const SizedBox(width: 8.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.sharedPost.originalPostuserfullname,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    timeago.format(widget.sharedPost.postCreatedAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 12.0),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8.0),

          /// =========== Original Post Content w/ Show More / Less ===========
          if (widget.sharedPost.postContent.isNotEmpty) ...[
            if (!_isOriginalContentExpanded)
              Text(
                widget.sharedPost.postContent,
                overflow: TextOverflow.ellipsis,
              )
            else
              Text(widget.sharedPost.postContent),

            if (widget.sharedPost.postContent.length > 100)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isOriginalContentExpanded = !_isOriginalContentExpanded;
                  });
                },
                child: Text(
                  _isOriginalContentExpanded ? 'Show Less' : 'Show More',
                  style: const TextStyle(color: Color(0xFFF45F67)),
                ),
              ),
          ],

          const SizedBox(height: 8.0),

          /// =========== Media (photos/videos) ===========
          _buildMediaContent(screenWidth),

          const SizedBox(height: 8.0),

          /// =========== Post Actions (like, comment, bookmark) ===========
          _buildPostActions(),
        ],
      ),
    );
  }

  Widget _buildMediaContent(double screenWidth) {
    if (widget.sharedPost.media.isEmpty) {
      return const SizedBox.shrink();
    }

    double mediaHeight = screenWidth * 0.75;
    const double maxHeight = 300.0;
    if (mediaHeight > maxHeight) {
      mediaHeight = maxHeight;
    }

    return SizedBox(
      height: mediaHeight,
      width: screenWidth,
      child: PageView.builder(
        itemCount: widget.sharedPost.media.length,
        itemBuilder: (context, index) {
          final media = widget.sharedPost.media[index];
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
        // Like
        IconButton(
          icon: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.favorite_border, color: Color(0xFFF45F67), size: 28),
              if (widget.isLiked)
                const Icon(Icons.favorite, color: Color(0xFFF45F67), size: 28),
            ],
          ),
          onPressed: widget.handleLike,
        ),
        Text(
          '${widget.likeCount}',
          style: const TextStyle(color: Color(0xFFF45F67)),
        ),
        const SizedBox(width: 16.0),

        // Comment
        IconButton(
          icon: Stack(
            alignment: Alignment.center,
            children: const [
              Icon(Icons.comment, color: Color(0xFFF45F67), size: 28),
              Icon(Icons.comment, color: Colors.transparent, size: 28),
            ],
          ),
          onPressed: widget.viewComments,
        ),
        Text(
          '${widget.sharedPost.commentcount}',
          style: const TextStyle(color: Color(0xFFF45F67)),
        ),
        const Spacer(),

        // Bookmark
        ScaleTransition(
          scale: widget.bookmarkAnimationController,
          child: IconButton(
            icon: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.bookmark_border, color: Color(0xFFF45F67), size: 28),
                if (widget.isBookmarked)
                  const Icon(Icons.bookmark, color: Color(0xFFF45F67), size: 28),
              ],
            ),
            onPressed: widget.handleBookmark,
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
