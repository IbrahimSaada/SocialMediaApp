// post_card.dart

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
import 'full_screen_image_page.dart';

// Add this import for the PostLikesBottomSheet and UserLike:
import '../models/user_like.dart';
import '../home/post_bottom_likes_sheet.dart';

class PostCard extends StatefulWidget {
  final PostInfo postInfo;
  final UserInfo author;
  final bool isLiked;
  final bool isBookmarked;
  final DateTime createdAt;
  final String content;

  const PostCard({
    Key? key,
    required this.postInfo,
    required this.author,
    required this.isLiked,
    required this.isBookmarked,
    required this.createdAt,
    required this.content,
  }) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isExpanded = false;
  late bool _isLiked;
  late bool _isBookmarked;
  late AnimationController _animationController;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
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
        throw Exception('Session expired');
      }

      final userId = await LoginService().getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
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
    } catch (e) {
      if (e.toString().contains('Session expired')) {
        if (context.mounted) {
          handleSessionExpired(context);
        }
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
    } catch (e) {
      if (e.toString().contains('Session expired')) {
        if (context.mounted) {
          handleSessionExpired(context);
        }
      } else {
        print('Failed to like/unlike post: $e');
      }
    }
  }

  void _showShareBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ShareBottomSheet(postId: widget.postInfo.postId);
      },
      isScrollControlled: true,
    );
  }

  Future<void> _showLikesBottomSheet() async {
    try {
      List<UserLike> likes = await PostService.fetchPostLikes(widget.postInfo.postId);
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
    } catch (e) {
      if (e.toString().contains('Session expired')) {
        if (context.mounted) {
          handleSessionExpired(context);
        }
      } else {
        print('Failed to fetch post likes: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.postInfo;
    final user = widget.author;

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
                  if (_currentUserId != user.userId)
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
                          // Implement report functionality
                        } else if (value == 'block') {
                          // Implement block functionality
                        }
                      },
                      child: Icon(Icons.more_vert, color: Color(0xFFF45F67)),
                    ),
                ],
              ),
              const SizedBox(height: 12.0),
              // Caption text
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
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16.0),
              // Post media (images or videos)
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
                                  errorWidget: (context, url, error) => Icon(Icons.error),
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
                  GestureDetector(
                    onTap: _showLikesBottomSheet,
                    child: Text('${post.likeCount}', style: TextStyle(color: Color(0xFFF45F67))),
                  ),
                  const SizedBox(width: 16.0),
                  IconButton(
                    icon: Icon(Icons.comment, color: Color(0xFFF45F67)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommentPage(postId: post.postId),
                        ),
                      );
                    },
                  ),
                  Text('${post.commentCount}', style: TextStyle(color: Color(0xFFF45F67))),
                  IconButton(
                    icon: Icon(Icons.share, color: Color(0xFFF45F67)),
                    onPressed: () {
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
