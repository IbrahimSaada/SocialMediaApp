// pages/repost_details_page.dart

import 'package:flutter/material.dart';
import '../models/repost_details_model.dart';
import '../services/repost_details_service.dart';
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

class RepostDetailsPage extends StatefulWidget {
  final int sharePostId;

  const RepostDetailsPage({Key? key, required this.sharePostId}) : super(key: key);

  @override
  _RepostDetailsPageState createState() => _RepostDetailsPageState();
}

class _RepostDetailsPageState extends State<RepostDetailsPage> with TickerProviderStateMixin {
  late Future<RepostDetailsModel> _futureRepostDetails;
  late bool _isLiked;
  late int _likeCount;
  late bool _isBookmarked;
  late AnimationController _bookmarkAnimationController;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _futureRepostDetails = _fetchRepostDetails();
    _bookmarkAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.8,
      upperBound: 1.2,
    );
    _fetchCurrentUserId();
  }

  @override
  void dispose() {
    _bookmarkAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentUserId() async {
    _currentUserId = await LoginService().getUserId();
  }

  Future<RepostDetailsModel> _fetchRepostDetails() async {
    int? userId = await LoginService().getUserId();
    if (userId == null) {
      // Handle user not logged in
      throw Exception('User not logged in');
    }
    RepostDetailsModel repostDetails = await RepostDetailsService().fetchRepostDetails(
      sharePostId: widget.sharePostId,
      userId: userId,
    );
    _isLiked = repostDetails.isLiked;
    _isBookmarked = repostDetails.isBookmarked;
    _likeCount = repostDetails.post.likeCount;
    return repostDetails;
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

  Future<void> _handleLike(int postId, int userId) async {
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

  Future<void> _handleBookmark(int postId) async {
    try {
      bool isLoggedIn = await LoginService().isLoggedIn();

      if (!isLoggedIn) {
        throw Exception('Session expired');
      }

      final userId = await LoginService().getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      await _bookmarkAnimationController.forward();

      if (_isBookmarked) {
        await PostService.unbookmarkPost(
          BookmarkRequest(userId: userId, postId: postId),
        );
        await _bookmarkAnimationController.reverse();
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

  void _showPostOptions(BuildContext context, RepostDetailsModel repostDetails) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // Rounded corners
          ),
          backgroundColor: Colors.white, // Background color for the dialog
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0), // Padding for the content
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Choose an Action",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                    color: Color(0xFFF45F67), // Primary color for the title
                  ),
                ),
                const SizedBox(height: 16.0),
                Divider(color: Colors.grey[300], thickness: 1.0), // Divider for separation
                const SizedBox(height: 12.0),
                if (_currentUserId == repostDetails.user.userId) ...[
                  ListTile(
                    leading: Icon(Icons.delete, color: Colors.red[400]),
                    title: Text(
                      'Delete Repost',
                      style: TextStyle(color: Colors.red[400]),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // Implement delete functionality here
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
                      // Implement report functionality
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
    return FutureBuilder<RepostDetailsModel>(
      future: _futureRepostDetails,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final repostDetails = snapshot.data!;
          final sharer = repostDetails.user;
          final post = repostDetails.post;
          final author = post.author;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Shared Post Details', style: TextStyle(color: Colors.black)),
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
                        // Sharer Information Row with Options Icon
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
                                    : AssetImage('assets/images/default.png') as ImageProvider,
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
                                      timeago.format(repostDetails.createdAt),
                                      style: const TextStyle(color: Colors.grey, fontSize: 12.0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.more_vert, color: Color(0xFFF45F67)),
                              onPressed: () {
                                _showPostOptions(context, repostDetails);
                              },
                            ),
                          ],
                        ),
                        // Repost Content (Comment)
                        if (repostDetails.content.isNotEmpty) ...[
                          const SizedBox(height: 8.0),
                          Text(
                            repostDetails.content,
                            style: const TextStyle(fontSize: 16.0, color: Colors.black87),
                          ),
                        ],
                        // Original Post Content
                        const SizedBox(height: 8.0),
                        _buildOriginalPost(context, repostDetails),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Shared Post Details'),
            ),
            body: const Center(child: Text('Failed to load shared post details')),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Shared Post Details'),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }

  Widget _buildOriginalPost(BuildContext context, RepostDetailsModel repostDetails) {
    final post = repostDetails.post;
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
          // Original Author Information Row
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
                  backgroundImage: author != null && author.profilePictureUrl.isNotEmpty
                      ? CachedNetworkImageProvider(author.profilePictureUrl)
                      : AssetImage('assets/images/default.png') as ImageProvider,
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
          if (post.content.isNotEmpty)
            Text(
              post.content,
              style: const TextStyle(fontSize: 16.0),
            ),
          const SizedBox(height: 8.0),
          _buildMediaContent(screenWidth, post),
          const SizedBox(height: 8.0),
          _buildPostActions(post),
        ],
      ),
    );
  }

  Widget _buildMediaContent(double screenWidth, PostInfo post) {
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

  Widget _buildPostActions(PostInfo post) {
    return Row(
      children: [
        // Like Button
        IconButton(
          icon: Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: Color(0xFFF45F67),
            size: 28,
          ),
          onPressed: () async {
            int? userId = await LoginService().getUserId();
            if (userId != null) {
              _handleLike(post.postId, userId);
            }
          },
        ),
        Text(
          '$_likeCount',
          style: TextStyle(color: Color(0xFFF45F67)),
        ),
        const SizedBox(width: 16.0),

        // Comment Button
        IconButton(
          icon: Icon(
            Icons.comment,
            color: Color(0xFFF45F67),
            size: 28,
          ),
          onPressed: () => _viewComments(post.postId),
        ),
        Text(
          '${post.commentCount}',
          style: TextStyle(color: Color(0xFFF45F67)),
        ),
        const SizedBox(width: 16.0),

        const Spacer(),

        // Bookmark Button
        ScaleTransition(
          scale: _bookmarkAnimationController,
          child: IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: Color(0xFFF45F67),
              size: 28,
            ),
            onPressed: () {
              _handleBookmark(post.postId);
            },
          ),
        ),
      ],
    );
  }
}
