import 'package:flutter/material.dart';
import '***REMOVED***/models/feed/repost_item.dart';
import '***REMOVED***/models/feed/user_info.dart';
import '***REMOVED***/home/video_post.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '***REMOVED***/services/loginservice.dart';
import '***REMOVED***/home/comment.dart';
import '***REMOVED***/maintenance/expiredtoken.dart';
import 'package:timeago/timeago.dart' as timeago;
import '***REMOVED***/models/LikeRequest_model.dart';
import '***REMOVED***/models/bookmarkrequest_model.dart';
import '***REMOVED***/services/post_service.dart';
import '***REMOVED***/profile/otheruserprofilepage.dart';
import '***REMOVED***/profile/profile_page.dart';
import '../services/SessionExpiredException.dart';
import 'full_screen_image_page.dart';
import 'report_dialog.dart';

void showBlockSnackbar(BuildContext context, String reason) {
  String message;
  if (reason.contains('You are blocked by the post owner')) {
    message = 'User blocked you';
  } else if (reason.contains('You have blocked the post owner')) {
    message = 'You blocked the user';
  } else {
    message = 'Action not allowed due to blocking';
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
      duration: const Duration(seconds: 3),
    ),
  );
}

class RepostCard extends StatefulWidget {
  final RepostItem feedItem;
  final Function(int postId, bool isLiked, int likeCount)? onPostStateChange; // Notifies parent
  final Map<int, Map<String, dynamic>> globalPostStates; // Global states

  const RepostCard({
    Key? key,
    required this.feedItem,
    required this.onPostStateChange,
    required this.globalPostStates,
  }) : super(key: key);

  @override
  _RepostCardState createState() => _RepostCardState();
}

class _RepostCardState extends State<RepostCard> with TickerProviderStateMixin {
  late bool _isLiked;
  late int _likeCount;
  late bool _isBookmarked;
  int? _currentUserId;

  // Booleans to handle show more/show less
  bool _isRepostCaptionExpanded = false;
  bool _isOriginalCaptionExpanded = false;

  late AnimationController _bookmarkAnimationController;

  @override
  void initState() {
    super.initState();
    final postId = widget.feedItem.post.postId;

    // If a global state entry exists, use it:
    if (widget.globalPostStates.containsKey(postId)) {
      _isLiked = widget.globalPostStates[postId]!["isLiked"];
      _likeCount = widget.globalPostStates[postId]!["likeCount"];
    } else {
      _isLiked = widget.feedItem.isLiked;
      _likeCount = widget.feedItem.post.likeCount;
    }

    // Ensure local variables are definitely set
    _isLiked = widget.feedItem.isLiked;
    _likeCount = widget.feedItem.post.likeCount;
    _isBookmarked = widget.feedItem.isBookmarked;

    _bookmarkAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.8,
      upperBound: 1.2,
    );

    _fetchCurrentUserId();
  }

  @override
  void didUpdateWidget(covariant RepostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If global states change, update local state
    final postId = widget.feedItem.post.postId;
    if (widget.globalPostStates.containsKey(postId)) {
      setState(() {
        _isLiked = widget.globalPostStates[postId]!["isLiked"];
        _likeCount = widget.globalPostStates[postId]!["likeCount"];
      });
    }
  }

  @override
  void dispose() {
    _bookmarkAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentUserId() async {
    _currentUserId = await LoginService().getUserId();
  }

  void _viewImageFullscreen(List<String> mediaUrls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImagePage(
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

    final postId = widget.feedItem.post.postId;

    try {
      if (_isLiked) {
        await PostService.unlikePost(
          LikeRequest(userId: userId, postId: postId),
        );
        setState(() {
          _isLiked = false;
          _likeCount -= 1;
        });
      } else {
        await PostService.likePost(
          LikeRequest(userId: userId, postId: postId),
        );
        setState(() {
          _isLiked = true;
          _likeCount += 1;
        });
      }

      // Notify parent about like state change
      if (widget.onPostStateChange != null) {
        widget.onPostStateChange!(postId, _isLiked, _likeCount);
      }
    } on SessionExpiredException {
      if (context.mounted) {
        handleSessionExpired(context);
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.startsWith('Exception: BLOCKED:') || errStr.toLowerCase().contains('blocked')) {
        String reason = errStr.startsWith('Exception: BLOCKED:')
            ? errStr.replaceFirst('Exception: BLOCKED:', '')
            : errStr;
        showBlockSnackbar(context, reason);
      } else {
        print('Failed to like/unlike post: $e');
      }
    }
  }

  Future<void> _handleBookmark() async {
    final userId = await LoginService().getUserId();

    if (userId == null) {
      handleSessionExpired(context);
      return;
    }

    await _bookmarkAnimationController.forward();

    try {
      final postId = widget.feedItem.post.postId;

      if (_isBookmarked) {
        await PostService.unbookmarkPost(
          BookmarkRequest(userId: userId, postId: postId),
        );
        setState(() {
          _isBookmarked = false;
        });
      } else {
        await PostService.bookmarkPost(
          BookmarkRequest(userId: userId, postId: postId),
        );
        setState(() {
          _isBookmarked = true;
        });
      }
    } on SessionExpiredException {
      if (context.mounted) {
        handleSessionExpired(context);
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.startsWith('Exception: BLOCKED:')) {
        String reason = errStr.replaceFirst('Exception: BLOCKED:', '');
        showBlockSnackbar(context, reason);
      } else {
        print('Failed to bookmark/unbookmark post: $e');
      }
    }

    await _bookmarkAnimationController.reverse();
  }

  void _viewComments(int postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentPage(postId: postId),
      ),
    );
  }

  Future<void> _deleteRepost() async {
    try {
      final userId = await LoginService().getUserId();
      if (userId == null) {
        throw SessionExpiredException();
      }
      // Implement repost deletion functionality if needed:
      // await PostService.deleteRepost(widget.feedItem.post.postId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repost deleted successfully')),
      );
    } on SessionExpiredException {
      if (context.mounted) {
        handleSessionExpired(context);
      }
    } catch (e) {
      print('Failed to delete repost: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete repost')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sharer = widget.feedItem.user;
    final post = widget.feedItem.post;
    final author = post.author;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth,
      margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[300]!, width: 1),
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
          /// =========== Repost Header (Sharer info) ==============
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () async {
                  int? currentUserId = await LoginService().getUserId();
                  if (currentUserId == sharer.userId) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OtherUserProfilePage(
                          otherUserId: sharer.userId,
                        ),
                      ),
                    );
                  }
                },
                child: CircleAvatar(
                  backgroundImage: sharer.profilePictureUrl.isNotEmpty
                      ? CachedNetworkImageProvider(sharer.profilePictureUrl)
                      : const AssetImage('assets/images/default.png')
                          as ImageProvider,
                  radius: 18,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    int? currentUserId = await LoginService().getUserId();
                    if (currentUserId == sharer.userId) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OtherUserProfilePage(
                            otherUserId: sharer.userId,
                          ),
                        ),
                      );
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sharer.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        timeago.format(widget.feedItem.createdAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 12.0),
                      ),
                    ],
                  ),
                ),
              ),
              if (_currentUserId != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFFF45F67)),
                  onSelected: (value) {
                    if (value == 'report') {
                      // Report original post
                      showReportDialog(
                        context: context,
                        reportedUser: post.author?.userId ?? 0,
                        contentId: post.postId,
                      );
                    } else if (value == 'delete') {
                      // Delete Repost
                      _deleteRepost();
                    }
                  },
                  itemBuilder: (context) {
                    if (_currentUserId == sharer.userId) {
                      // Owner of the repost can delete
                      return [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: const [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 10),
                              Text('Delete Repost'),
                            ],
                          ),
                        ),
                      ];
                    } else {
                      // Non-owner can report
                      return [
                        PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: const [
                              Icon(Icons.flag, color: Color(0xFFF45F67)),
                              SizedBox(width: 10),
                              Text('Report'),
                            ],
                          ),
                        ),
                      ];
                    }
                  },
                ),
            ],
          ),

          /// =========== Repost Caption (the text user wrote when reposting) ===========
          if (widget.feedItem.content.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            // If expanded, show full text; otherwise, show truncated text
            _isRepostCaptionExpanded
                ? Text(widget.feedItem.content)
                : Text(
                    widget.feedItem.content,
                    overflow: TextOverflow.ellipsis,
                  ),
            // If more than 100 chars, show the toggle
            if (widget.feedItem.content.length > 100)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isRepostCaptionExpanded = !_isRepostCaptionExpanded;
                  });
                },
                child: Text(
                  _isRepostCaptionExpanded ? 'Show Less' : 'Show More',
                  style: const TextStyle(color: Color(0xFFF45F67)),
                ),
              ),
          ],
          const SizedBox(height: 8.0),

          /// =========== Original Post Card ==============
          _buildOriginalPost(context),
        ],
      ),
    );
  }

  Widget _buildOriginalPost(BuildContext context) {
    final post = widget.feedItem.post;
    final author = post.author;
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
          /// =========== Original Post Header ==============
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  if (author != null) {
                    int? currentUserId = await LoginService().getUserId();
                    if (currentUserId == author.userId) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OtherUserProfilePage(
                            otherUserId: author.userId,
                          ),
                        ),
                      );
                    }
                  }
                },
                child: CircleAvatar(
                  backgroundImage: (author != null && author.profilePictureUrl.isNotEmpty)
                      ? CachedNetworkImageProvider(author.profilePictureUrl)
                      : const AssetImage('assets/images/default.png')
                          as ImageProvider,
                  radius: 18,
                ),
              ),
              const SizedBox(width: 8.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author?.fullName ?? 'Unknown User',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Text(
                    timeago.format(post.createdAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 12.0),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8.0),

          /// =========== Original Post Caption/Content with Show More/Less ===========
          if (post.content.isNotEmpty)
            _isOriginalCaptionExpanded
                ? Text(post.content)
                : Text(
                    post.content,
                    overflow: TextOverflow.ellipsis,
                  ),
          if (post.content.length > 100)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isOriginalCaptionExpanded = !_isOriginalCaptionExpanded;
                });
              },
              child: Text(
                _isOriginalCaptionExpanded ? 'Show Less' : 'Show More',
                style: const TextStyle(color: Color(0xFFF45F67)),
              ),
            ),
          const SizedBox(height: 8.0),

          /// =========== Media (Photos/Videos) ===========
          _buildMediaContent(screenWidth),
          const SizedBox(height: 8.0),

          /// =========== Post Actions (Like, Comment, Bookmark) ===========
          _buildPostActions(),
        ],
      ),
    );
  }

  Widget _buildMediaContent(double screenWidth) {
    final post = widget.feedItem.post;

    if (post.media.isEmpty) {
      return const SizedBox.shrink();
    }

    double mediaHeight = screenWidth * 0.75;
    double maxHeight = 300.0;
    if (mediaHeight > maxHeight) {
      mediaHeight = maxHeight;
    }

    return SizedBox(
      height: mediaHeight,
      width: screenWidth,
      child: PageView.builder(
        itemCount: post.media.length,
        itemBuilder: (context, index) {
          final media = post.media[index];
          if (media.mediaType == 'photo') {
            return GestureDetector(
              onTap: () {
                _viewImageFullscreen(
                  post.media.map((m) => m.mediaUrl).toList(),
                  index,
                );
              },
              child: ClipRRect(
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
              ),
            );
          } else if (media.mediaType == 'video') {
            return GestureDetector(
              onTap: () {
                _viewImageFullscreen(
                  post.media.map((m) => m.mediaUrl).toList(),
                  index,
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: VideoPost(mediaUrl: media.mediaUrl),
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildPostActions() {
    final post = widget.feedItem.post;

    return Row(
      children: [
        // Like
        IconButton(
          icon: Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: const Color(0xFFF45F67),
            size: 28,
          ),
          onPressed: _handleLike,
        ),
        Text(
          '$_likeCount',
          style: const TextStyle(color: Color(0xFFF45F67)),
        ),
        const SizedBox(width: 16.0),

        // Comment
        IconButton(
          icon: const Icon(
            Icons.comment,
            color: Color(0xFFF45F67),
            size: 28,
          ),
          onPressed: () => _viewComments(post.postId),
        ),
        Text(
          '${post.commentCount}',
          style: const TextStyle(color: Color(0xFFF45F67)),
        ),
        const Spacer(),

        // Bookmark
        ScaleTransition(
          scale: _bookmarkAnimationController,
          child: IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: const Color(0xFFF45F67),
              size: 28,
            ),
            onPressed: _handleBookmark,
          ),
        ),
      ],
    );
  }
}
