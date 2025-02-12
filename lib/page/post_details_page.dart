// pages/post_details_page.dart

import 'package:flutter/material.dart';
import '../models/post_details_model.dart';
import '../services/post_details_service.dart';
import '../services/loginservice.dart';
import '../maintenance/expiredtoken.dart';
import '../home/video_post.dart';
import '../home/comment.dart';
import '../profile/otheruserprofilepage.dart';
import '../profile/profile_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shimmer/shimmer.dart';
import '../models/LikeRequest_model.dart';
import '../models/bookmarkrequest_model.dart';
import '../services/post_service.dart';
import '../home/full_screen_image_page.dart';

class PostDetailsPage extends StatefulWidget {
  final int postId;

  const PostDetailsPage({Key? key, required this.postId}) : super(key: key);

  @override
  _PostDetailsPageState createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> with SingleTickerProviderStateMixin {
  late Future<PostDetailsModel> _futurePostDetails;
  late bool _isLiked;
  late bool _isBookmarked;
  int? _currentUserId;
  late AnimationController _animationController;
  bool _isExpanded = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _futurePostDetails = _fetchPostDetails();
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

  Future<PostDetailsModel> _fetchPostDetails() async {
    int? userId = await LoginService().getUserId();
    if (userId == null) {
      // Handle user not logged in
      throw Exception('User not logged in');
    }
    PostDetailsModel postDetails = await PostDetailsService().fetchPostDetails(
      postId: widget.postId,
      userId: userId,
    );
    _isLiked = postDetails.isLiked;
    _isBookmarked = postDetails.isBookmarked;
    return postDetails;
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Future<void> _toggleBookmark(int postId) async {
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
          BookmarkRequest(userId: userId, postId: postId),
        );
        await _animationController.reverse();
      } else {
        await PostService.bookmarkPost(
          BookmarkRequest(userId: userId, postId: postId),
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

  Future<void> _handleLike(int postId, int userId) async {
    try {
      if (_isLiked) {
        await PostService.unlikePost(
          LikeRequest(userId: userId, postId: postId),
        );
        setState(() {
          _isLiked = false;
          // Update like count if needed
        });
      } else {
        await PostService.likePost(
          LikeRequest(userId: userId, postId: postId),
        );
        setState(() {
          _isLiked = true;
          // Update like count if needed
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PostDetailsModel>(
      future: _futurePostDetails,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final postDetails = snapshot.data!;
          final post = postDetails.post;
          final user = postDetails.user;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Post Details', style: TextStyle(color: Colors.black)),
              backgroundColor: Colors.white,
              iconTheme: const IconThemeData(color: Color(0xFFF45F67)),
              elevation: 0,
            ),
            body: SingleChildScrollView(
              child: Padding(
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
                                onBackgroundImageError: (_, __) {
                                  // Optionally handle the error
                                },
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
                                    timeago.format(postDetails.createdAt),
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
                        if (postDetails.content.isNotEmpty)
                          _isExpanded
                              ? Text(postDetails.content)
                              : Text(
                                  postDetails.content,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                        if (postDetails.content.length > 100)
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
                                            errorWidget: (context, url, error) => const Icon(Icons.error),
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
                              onPressed: () async {
                                int? userId = await LoginService().getUserId();
                                if (userId != null) {
                                  _handleLike(post.postId, userId);
                                }
                              },
                            ),
                            Text('${post.likeCount}', style: TextStyle(color: Color(0xFFF45F67))),
                            const SizedBox(width: 16.0),
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
                            Text('${post.commentCount}', style: TextStyle(color: Color(0xFFF45F67))),
                            IconButton(
                              icon: const Icon(Icons.share, color: Color(0xFFF45F67)),
                              onPressed: () {
                                // Implement share functionality
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
                                onPressed: () {
                                  _toggleBookmark(post.postId);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          print('Error in snapshot: ${snapshot.error}');
          return Scaffold(
            appBar: AppBar(
              title: const Text('Post Details'),
            ),
            body: const Center(child: Text('Failed to load post details')),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Post Details'),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
