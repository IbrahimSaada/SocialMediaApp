import 'package:flutter/material.dart';
import '***REMOVED***/models/feed/post_info.dart';
import '***REMOVED***/models/feed/user_info.dart';
import '***REMOVED***/services/loginservice.dart';
import '***REMOVED***/services/post_service.dart';
import '***REMOVED***/maintenance/expiredtoken.dart';
import '***REMOVED***/home/video_post.dart';
import '***REMOVED***/home/share.dart';
import '***REMOVED***/home/comment.dart';
import '***REMOVED***/profile/otheruserprofilepage.dart';
import '***REMOVED***/profile/profile_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shimmer/shimmer.dart';
import '***REMOVED***/models/LikeRequest_model.dart';
import '***REMOVED***/models/bookmarkrequest_model.dart';
import '***REMOVED***/models/user_like.dart';
import '***REMOVED***/home/post_bottom_likes_sheet.dart';
import '***REMOVED***/services/SessionExpiredException.dart';
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

class PostCard extends StatefulWidget {
  final PostInfo postInfo;
  final UserInfo author;
  final bool isLiked;
  final bool isBookmarked;
  final DateTime createdAt;
  final String content;

  // Called if something in the post changes that requires a refresh
  final VoidCallback? onRefreshNeeded;

  // Notifies a parent widget that the post's like state changed.
  final Function(int postId, bool isLiked, int likeCount)? onPostStateChange; // NEW

  // Holds global states for posts (e.g., if many cards share the same data).
  final Map<int, Map<String, dynamic>> globalPostStates; // NEW

  const PostCard({
    Key? key,
    required this.postInfo,
    required this.author,
    required this.isLiked,
    required this.isBookmarked,
    required this.createdAt,
    required this.content,
    this.onRefreshNeeded,
    required this.onPostStateChange,  // NEW
    required this.globalPostStates,    // NEW
  }) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isExpanded = false; // Tracks whether the caption is expanded
  late bool _isLiked;
  late bool _isBookmarked;
  late AnimationController _animationController;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();

    // If there's a global state for this post, use it. Otherwise, use the local data
    if (widget.globalPostStates.containsKey(widget.postInfo.postId)) {
      _isLiked = widget.globalPostStates[widget.postInfo.postId]!["isLiked"];
      widget.postInfo.likeCount =
          widget.globalPostStates[widget.postInfo.postId]!["likeCount"];
    } else {
      _isLiked = widget.isLiked;
    }

    // Ensure local states are set if above logic doesn't override them
    _isLiked = widget.isLiked;
    _isBookmarked = widget.isBookmarked;

    _fetchCurrentUserId();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.8,
      upperBound: 1.2,
    );
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If global states have changed, update local state
    if (widget.globalPostStates.containsKey(widget.postInfo.postId)) {
      setState(() {
        _isLiked = widget.globalPostStates[widget.postInfo.postId]!["isLiked"];
        widget.postInfo.likeCount =
            widget.globalPostStates[widget.postInfo.postId]!["likeCount"];
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentUserId() async {
    _currentUserId = await LoginService().getUserId();
  }

  Future<void> _toggleBookmark() async {
    try {
      bool isLoggedIn = await LoginService().isLoggedIn();

      if (!isLoggedIn) {
        throw SessionExpiredException();
      }

      final userId = await LoginService().getUserId();
      if (userId == null) {
        throw SessionExpiredException();
      }

      await _animationController.forward();

      if (_isBookmarked) {
        await PostService.unbookmarkPost(
          BookmarkRequest(userId: userId, postId: widget.postInfo.postId),
        );
        await _animationController.reverse();
      } else {
        await PostService.bookmarkPost(
          BookmarkRequest(userId: userId, postId: widget.postInfo.postId),
        );
      }

      setState(() {
        _isBookmarked = !_isBookmarked;
      });
    } on SessionExpiredException {
      if (context.mounted) {
        handleSessionExpired(context);
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.startsWith('Exception: BLOCKED:') ||
          errStr.toLowerCase().contains('blocked')) {
        String reason = errStr.startsWith('Exception: BLOCKED:')
            ? errStr.replaceFirst('Exception: BLOCKED:', '')
            : errStr;
        showBlockSnackbar(context, reason);
      } else {
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

    try {
      if (_isLiked) {
        await PostService.unlikePost(
          LikeRequest(userId: userId, postId: widget.postInfo.postId),
        );
        setState(() {
          _isLiked = false;
          widget.postInfo.likeCount -= 1;
        });
      } else {
        await PostService.likePost(
          LikeRequest(userId: userId, postId: widget.postInfo.postId),
        );
        setState(() {
          _isLiked = true;
          widget.postInfo.likeCount += 1;
        });
      }

      // Notify parent of state change
      if (widget.onPostStateChange != null) {
        widget.onPostStateChange!(
          widget.postInfo.postId,
          _isLiked,
          widget.postInfo.likeCount,
        );
      }
    } on SessionExpiredException {
      if (context.mounted) {
        handleSessionExpired(context);
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.startsWith('Exception: BLOCKED:') ||
          errStr.toLowerCase().contains('blocked')) {
        String reason = errStr.startsWith('Exception: BLOCKED:')
            ? errStr.replaceFirst('Exception: BLOCKED:', '')
            : errStr;
        showBlockSnackbar(context, reason);
      } else {
        print('Failed to like/unlike post: $e');
      }
    }
  }

  Future<void> _showShareBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ShareBottomSheet(postId: widget.postInfo.postId);
      },
      isScrollControlled: true,
    );

    if (result == true && widget.onRefreshNeeded != null) {
      widget.onRefreshNeeded!();
    }
  }

  Future<void> _deletePost() async {
    try {
      final userId = await LoginService().getUserId();
      if (userId == null) {
        throw SessionExpiredException();
      }
      // Implement post deletion functionality here.
      // Example: await PostService.deletePost(widget.postInfo.postId);
      // Then refresh if needed:
      if (widget.onRefreshNeeded != null) {
        widget.onRefreshNeeded!();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully')),
      );
    } on SessionExpiredException {
      if (context.mounted) {
        handleSessionExpired(context);
      }
    } catch (e) {
      print('Failed to delete post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete post')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.postInfo;
    final user = widget.author;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// =========== Header (Profile Pic, Name, Time, More Menu) ===========
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      int? currentUserId = await LoginService().getUserId();
                      if (currentUserId == user.userId) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OtherUserProfilePage(
                              otherUserId: user.userId,
                            ),
                          ),
                        );
                      }
                    },
                    child: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(user.profilePictureUrl),
                      onBackgroundImageError: (_, __) {},
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  GestureDetector(
                    onTap: () async {
                      int? currentUserId = await LoginService().getUserId();
                      if (currentUserId == user.userId) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OtherUserProfilePage(
                              otherUserId: user.userId,
                            ),
                          ),
                        );
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          timeago.format(widget.createdAt),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (_currentUserId != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Color(0xFFF45F67)),
                      onSelected: (value) async {
                        if (value == 'report') {
                          // Report post
                          showReportDialog(
                            context: context,
                            reportedUser: user.userId,
                            contentId: post.postId,
                          );
                        } else if (value == 'delete') {
                          // Delete post
                          _deletePost();
                        }
                      },
                      itemBuilder: (context) {
                        if (_currentUserId == user.userId) {
                          // Owner: Can delete post
                          return [
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: const [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 10),
                                  Text('Delete Post'),
                                ],
                              ),
                            ),
                          ];
                        } else {
                          // Not owner: Can report post
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

              const SizedBox(height: 12.0),

              /// =========== Caption with Show More / Show Less ===========
              if (widget.content.isNotEmpty)
                _isExpanded
                    ? Text(widget.content)
                    : Text(
                        widget.content,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
              if (widget.content.length > 100)
                GestureDetector(
                  onTap: _toggleExpansion,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        _isExpanded ? 'Show Less' : 'Show More',
                        style: const TextStyle(
                          color: Color(0xFFF45F67), // <== Updated color
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16.0),

              /// =========== Media Carousel ===========
              if (post.media.isNotEmpty)
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: PageView.builder(
                    itemCount: post.media.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final media = post.media[index];
                      return GestureDetector(
                        onDoubleTap: () {
                          _viewImageFullscreen(
                            post.media.map((m) => m.mediaUrl).toList(),
                            index,
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: media.mediaType == 'photo'
                              ? CachedNetworkImage(
                                  imageUrl: media.mediaUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      color: Colors.white,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                )
                              : VideoPost(mediaUrl: media.mediaUrl),
                        ),
                      );
                    },
                  ),
                ),
              if (post.media.length > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(post.media.length, (index) {
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

              /// =========== Post Actions (Like, Comment, Share, Bookmark) ===========
              Row(
                children: [
                  // Like
                  IconButton(
                    icon: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: Color(0xFFF45F67),
                    ),
                    onPressed: _handleLike,
                  ),
                  GestureDetector(
                    onTap: () async {
                      try {
                        final likes = await PostService.fetchPostLikes(widget.postInfo.postId);
                        if (context.mounted) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (BuildContext context) {
                              return PostLikesBottomSheet(
                                postId: widget.postInfo.postId,
                                initialLikes: likes,
                              );
                            },
                          );
                        }
                      } on SessionExpiredException {
                        if (context.mounted) {
                          handleSessionExpired(context);
                        }
                      } catch (e) {
                        final errStr = e.toString();
                        if (errStr.startsWith('Exception: BLOCKED:') ||
                            errStr.toLowerCase().contains('blocked')) {
                          String reason = errStr.startsWith('Exception: BLOCKED:')
                              ? errStr.replaceFirst('Exception: BLOCKED:', '')
                              : errStr;
                          showBlockSnackbar(context, reason);
                        } else {
                          print('Failed to fetch post likes: $e');
                        }
                      }
                    },
                    child: Text(
                      '${post.likeCount}',
                      style: const TextStyle(color: Color(0xFFF45F67)),
                    ),
                  ),

                  const SizedBox(width: 16.0),

                  // Comment
                  IconButton(
                    icon: const Icon(Icons.comment, color: Color(0xFFF45F67)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommentPage(postId: post.postId),
                        ),
                      );
                    },
                  ),
                  Text(
                    '${post.commentCount}',
                    style: const TextStyle(color: Color(0xFFF45F67)),
                  ),

                  // Share
                  IconButton(
                    icon: const Icon(Icons.share, color: Color(0xFFF45F67)),
                    onPressed: () {
                      _showShareBottomSheet(context);
                    },
                  ),

                  const Spacer(),

                  // Bookmark
                  ScaleTransition(
                    scale: _animationController,
                    child: IconButton(
                      icon: Icon(
                        _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: Color(0xFFF45F67),
                        size: 28,
                      ),
                      onPressed: _toggleBookmark,
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
