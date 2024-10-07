import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cook/services/post_service.dart';
import 'package:cook/models/post_model.dart';
import 'package:cook/models/LikeRequest_model.dart';
import 'package:cook/models/bookmarkrequest_model.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:cook/home/comment.dart';
import 'package:cook/services/LoginService.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ProfilePostDetails extends StatefulWidget {
  final List<Post> userPosts;
  final List<Post> bookmarkedPosts;
  final int initialIndex;
  final int userId;
  final bool isPostsSelected;

  const ProfilePostDetails({
    Key? key,
    required this.userPosts,
    required this.bookmarkedPosts,
    required this.initialIndex,
    required this.userId,
    required this.isPostsSelected,
  }) : super(key: key);

  @override
  _ProfilePostDetailsState createState() => _ProfilePostDetailsState();
}

class _ProfilePostDetailsState extends State<ProfilePostDetails> {
  late ScrollController _scrollController;
  late List<Post> displayedPosts;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: widget.initialIndex * 300.0,
    );
    displayedPosts = widget.isPostsSelected ? widget.userPosts : widget.bookmarkedPosts;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildCustomAppBar(),
      backgroundColor: Colors.grey[100],
      body: ListView.builder(
        controller: _scrollController,
        itemCount: displayedPosts.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final post = displayedPosts[index];
          return PostCard(post: post);
        },
      ),
    );
  }

  AppBar _buildCustomAppBar() {
    return AppBar(
      backgroundColor: Colors.white, // Set AppBar background to white
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Color(0xFFF45F67)),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: const Text(
        "POSTS",
        style: TextStyle(
          color: Color(0xFFF45F67), // Set text color to primary color
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFFF45F67)), // Icon color for actions
    );
  }
}

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  bool _isBookmarked = false;
  late int _likeCount;
  late AnimationController _bookmarkAnimationController;

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
            Text(
              widget.post.caption,
              style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
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
