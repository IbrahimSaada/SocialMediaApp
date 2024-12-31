import '***REMOVED***/services/Userprofile_service.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '***REMOVED***/services/post_service.dart';
import '***REMOVED***/models/post_model.dart';
import '***REMOVED***/models/LikeRequest_model.dart';
import '***REMOVED***/models/bookmarkrequest_model.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '***REMOVED***/home/comment.dart';
import '***REMOVED***/services/LoginService.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '***REMOVED***/services/userpost_service.dart';
import '***REMOVED***/home/report_dialog.dart';
import '***REMOVED***/maintenance/expiredtoken.dart';
import '***REMOVED***/services/SessionExpiredException.dart';

class ProfilePostDetails extends StatefulWidget {
  final List<Post> userPosts;
  final List<Post> bookmarkedPosts;
  final int initialIndex;
  final int userId;
  final bool isPostsSelected;
  final bool isCurrentUserProfile;

  const ProfilePostDetails({
    Key? key,
    required this.userPosts,
    required this.bookmarkedPosts,
    required this.initialIndex,
    required this.userId,
    required this.isPostsSelected,
    required this.isCurrentUserProfile,
  }) : super(key: key);

  @override
  _ProfilePostDetailsState createState() => _ProfilePostDetailsState();
}

class _ProfilePostDetailsState extends State<ProfilePostDetails> {
  late ScrollController _scrollController;
  late List<Post> displayedPosts;
  bool isPaginating = false;
  bool hasMorePosts = true;
  int currentPageNumber = 1;
  final int pageSize = 10;
  final UserpostService _userpostService = UserpostService();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: widget.initialIndex * 300.0,
    );
    _scrollController.addListener(_scrollListener);

    displayedPosts = widget.isPostsSelected ? widget.userPosts : widget.bookmarkedPosts;

    // Calculate the current page number based on the number of posts already loaded
    currentPageNumber = 1 + (displayedPosts.length ~/ pageSize);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent &&
        !isPaginating &&
        hasMorePosts) {
      _fetchMorePosts();
    }
  }

  Future<void> _fetchMorePosts() async {
    if (isPaginating || !hasMorePosts) return;

    setState(() {
      isPaginating = true;
    });

    try {
      List<Post> newPosts = [];

      if (widget.isPostsSelected) {
        // Fetch user posts
        newPosts = await _userpostService.fetchUserPosts(
          widget.userId,
          widget.userId, // Assuming the viewer is the user themselves
          currentPageNumber,
          pageSize,
        );
      } else {
        // Fetch bookmarked posts
        newPosts = await _userpostService.fetchBookmarkedPosts(
          widget.userId,
          currentPageNumber,
          pageSize,
        );
      }

      setState(() {
        // Prevent duplicates
        final existingPostIds = displayedPosts.map((post) => post.postId).toSet();
        final uniqueNewPosts = newPosts.where((post) => !existingPostIds.contains(post.postId)).toList();

        displayedPosts.addAll(uniqueNewPosts);

        if (newPosts.length == pageSize) {
          currentPageNumber++;
        } else {
          hasMorePosts = false; // No more posts to load
        }

        isPaginating = false;
      });
    } on SessionExpiredException {
      print("SessionExpired detected in _fetchMorePosts");
      handleSessionExpired(context);
      setState(() {
        isPaginating = false;
      });
    } catch (e) {
      print('Error fetching more posts: $e');
      setState(() {
        isPaginating = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildCustomAppBar(),
      backgroundColor: Colors.grey[100],
      body: displayedPosts.isEmpty
          ? Center(
              child: Text(
                'No posts available',
                style: TextStyle(fontSize: 18.0, color: Colors.grey[600]),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              itemCount: displayedPosts.length + (hasMorePosts ? 1 : 0),
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                if (index == displayedPosts.length) {
                  // Loading indicator at the end of the list
                  return Center(child: CircularProgressIndicator(color: Color(0xFFF45F67)));
                }

                final post = displayedPosts[index];
                return PostCard(
                  post: post,
                  isPostsSelected: widget.isPostsSelected,
                  isCurrentUserProfile: widget.isCurrentUserProfile,
                  onDelete: () {
                    setState(() {
                      displayedPosts.remove(post);
                    });
                  },
                );
              },
            ),
    );
  }

  AppBar _buildCustomAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Color(0xFFF45F67)),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: const Text(
        "POSTS",
        style: TextStyle(
          color: Color(0xFFF45F67),
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFFF45F67)),
    );
  }
}

class PostCard extends StatefulWidget {
  final Post post;
  final bool isPostsSelected;
  final bool isCurrentUserProfile;
  final VoidCallback onDelete; // Callback to handle deletion

  const PostCard({
    Key? key,
    required this.post,
    required this.isPostsSelected,
    required this.isCurrentUserProfile,
    required this.onDelete,
  }) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  bool _isBookmarked = false;
  bool _isEditing = false;
  String _newCaption = "";
  late int _likeCount;

  // For "Show More/Show Less" in caption
  bool _isCaptionExpanded = false;

  late AnimationController _bookmarkAnimationController;
  final UserProfileService _userProfileService = UserProfileService();

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _isBookmarked = widget.post.isBookmarked;
    _likeCount = widget.post.likeCount;

    _bookmarkAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.8,
      upperBound: 1.2,
    );
  }

  @override
  void dispose() {
    _bookmarkAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      _isLiked ? _likeCount++ : _likeCount--;
    });

    final userId = await LoginService().getUserId();
    if (_isLiked) {
      await PostService.likePost(LikeRequest(userId: userId!, postId: widget.post.postId));
    } else {
      await PostService.unlikePost(LikeRequest(userId: userId!, postId: widget.post.postId));
    }
  }

  Future<void> _handleBookmark() async {
    final userId = await LoginService().getUserId();
    await _bookmarkAnimationController.forward();

    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    if (_isBookmarked) {
      await PostService.bookmarkPost(BookmarkRequest(userId: userId!, postId: widget.post.postId));
    } else {
      await PostService.unbookmarkPost(BookmarkRequest(userId: userId!, postId: widget.post.postId));
    }

    await _bookmarkAnimationController.reverse();
  }

  void _viewComments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentPage(postId: widget.post.postId),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this post?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deletePost();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePost() async {
    final userId = await LoginService().getUserId();
    if (userId == null) return;

    try {
      bool success = await _userProfileService.deletePost(widget.post.postId, userId);

      if (success) {
        widget.onDelete(); // Update UI immediately
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Post deleted successfully!'),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to delete the post'),
          backgroundColor: Colors.red,
        ));
      }
    } on SessionExpiredException {
      print('SessionExpired detected in _deletePost');
      handleSessionExpired(context);
    } catch (e) {
      print('Error occurred while deleting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('An error occurred while deleting the post'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _editPostCaption() async {
    final userId = await LoginService().getUserId();
    if (userId == null) return;

    try {
      bool success = await _userProfileService.editPostCaption(
        widget.post.postId,
        _newCaption,
        userId,
      );

      if (success) {
        setState(() {
          widget.post.caption = _newCaption;
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Post updated successfully!'),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update the post'),
          backgroundColor: Colors.red,
        ));
      }
    } on SessionExpiredException {
      print('SessionExpired detected in _editPostCaption');
      handleSessionExpired(context);
    } catch (e) {
      print('Error updating post caption: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('An error occurred while updating the post'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _showPostOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
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
                if (widget.isCurrentUserProfile) ...[
                  ListTile(
                    leading: Icon(Icons.edit, color: Color(0xFFF45F67)),
                    title: Text(
                      'Edit Post',
                      style: TextStyle(color: Color(0xFFF45F67)),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _isEditing = true;
                        _newCaption = widget.post.caption;
                      });
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
                  ListTile(
                    leading: Icon(Icons.report, color: Colors.red[400]),
                    title: Text(
                      'Report Post',
                      style: TextStyle(color: Colors.red[400]),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showReportDialog(
                        context: context,
                        reportedUser: widget.post.userId,
                        contentId: widget.post.postId,
                      );
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

  /// Builds the caption editor if `_isEditing` is true.
  /// Otherwise, displays the caption with a Show More / Show Less functionality.
  Widget _buildCaptionEditor() {
    if (_isEditing) {
      return Column(
        children: [
          TextField(
            onChanged: (value) {
              _newCaption = value;
            },
            controller: TextEditingController(text: _newCaption),
            decoration: InputDecoration(
              hintText: "Edit caption...",
              border: OutlineInputBorder(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: _editPostCaption,
                child: Text("Save"),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                  });
                },
                child: Text("Cancel"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              ),
            ],
          ),
        ],
      );
    } else {
      // Determine if the text exceeds 3 lines to conditionally show "Show more".
      final textStyle = const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600);
      final span = TextSpan(text: widget.post.caption, style: textStyle);

      // Use a TextPainter to check if the text exceeds 3 lines
      final tp = TextPainter(
        text: span,
        maxLines: 3,
        textDirection: TextDirection.ltr,
      );

      // We need to layout with an arbitrary max width; we'll approximate by using screen width
      final maxTextWidth = MediaQuery.of(context).size.width - 40; 
      tp.layout(maxWidth: maxTextWidth);

      final exceedsMaxLines = tp.didExceedMaxLines;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.post.caption,
            style: textStyle,
            maxLines: _isCaptionExpanded ? null : 3,
            overflow: _isCaptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          if (exceedsMaxLines)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isCaptionExpanded = !_isCaptionExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  _isCaptionExpanded ? 'Show Less' : 'Show More',
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
        ],
      );
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(widget.post.profilePic),
          radius: 18,
        ),
        const SizedBox(width: 8.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.post.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            Text(
              timeago.format(widget.post.localCreatedAt),
              style: const TextStyle(color: Colors.grey, fontSize: 12.0),
            ),
          ],
        ),
        Spacer(),
        if (widget.isPostsSelected)
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () => _showPostOptions(context),
          )
      ],
    );
  }

  Widget _buildMedia(double screenWidth) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double mediaHeight = screenWidth * 0.75;
        double maxHeight = 300.0;
        if (mediaHeight > maxHeight) {
          mediaHeight = maxHeight;
        }
        return SizedBox(
          height: mediaHeight,
          width: double.infinity,
          child: PageView.builder(
            itemCount: widget.post.media.length,
            itemBuilder: (context, index) {
              final media = widget.post.media[index];
              if (media.mediaType == 'photo') {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: CachedNetworkImage(
                    imageUrl: media.mediaUrl,
                    fit: BoxFit.cover,
                    width: screenWidth,
                    height: mediaHeight,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
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
      },
    );
  }

  Widget _buildPostActions() {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.red : Colors.grey,
          ),
          onPressed: _handleLike,
        ),
        Text('$_likeCount', style: const TextStyle(color: Colors.grey)),
        const SizedBox(width: 16.0),
        IconButton(
          icon: const Icon(Icons.comment, color: Colors.grey),
          onPressed: _viewComments,
        ),
        Text('${widget.post.commentCount}', style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        ScaleTransition(
          scale: _bookmarkAnimationController,
          child: IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? Color(0xFFF45F67) : Colors.grey,
            ),
            onPressed: _handleBookmark,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth,
      margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 8.0),
          if (widget.post.caption.isNotEmpty)
            _buildCaptionEditor(),
          if (widget.post.media.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            _buildMedia(screenWidth),
          ],
          const SizedBox(height: 8.0),
          _buildPostActions(),
        ],
      ),
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
        looping: true,
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
