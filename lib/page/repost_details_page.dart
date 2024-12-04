// repost_details_page.dart

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
import '../models/LikeRequest_model.dart';
import '../models/bookmarkrequest_model.dart';
import '../services/post_service.dart';
import '../home/full_screen_image_page.dart';

class RepostDetailsPage extends StatefulWidget {
  final int postId;
  final bool isMultipleShares;

  const RepostDetailsPage(
      {Key? key, required this.postId, this.isMultipleShares = false})
      : super(key: key);

  @override
  _RepostDetailsPageState createState() => _RepostDetailsPageState();
}

class _RepostDetailsPageState extends State<RepostDetailsPage>
    with TickerProviderStateMixin {
  late Future<List<RepostDetailsModel>> _futureRepostDetails;
  late Map<int, bool> _isLikedMap;
  late Map<int, int> _likeCountMap;
  late Map<int, bool> _isBookmarkedMap;
  late Map<int, AnimationController> _bookmarkAnimationControllers;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _futureRepostDetails = _fetchRepostDetails();
    _bookmarkAnimationControllers = {};
    _isLikedMap = {};
    _likeCountMap = {};
    _isBookmarkedMap = {};
    _fetchCurrentUserId();
  }

  @override
  void dispose() {
    _bookmarkAnimationControllers.values
        .forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _fetchCurrentUserId() async {
    _currentUserId = await LoginService().getUserId();
  }

  Future<List<RepostDetailsModel>> _fetchRepostDetails() async {
    int? userId = await LoginService().getUserId();
    if (userId == null) {
      // Handle user not logged in
      throw Exception('User not logged in');
    }

    List<RepostDetailsModel> repostDetailsList;

    if (widget.isMultipleShares) {
      // Fetch all reposts for the post
      repostDetailsList = await RepostDetailsService().fetchRepostsForPost(
        postId: widget.postId,
        userId: userId,
      );
    } else {
      // Fetch a single repost (the latest one)
      RepostDetailsModel repostDetails =
          await RepostDetailsService().fetchLatestRepost(
        postId: widget.postId,
        userId: userId,
      );
      repostDetailsList = [repostDetails];
    }

    // Initialize the like and bookmark maps
    for (var repost in repostDetailsList) {
      _isLikedMap[repost.itemId] = repost.isLiked;
      _likeCountMap[repost.itemId] = repost.post.likeCount;
      _isBookmarkedMap[repost.itemId] = repost.isBookmarked;

      _bookmarkAnimationControllers[repost.itemId] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
        lowerBound: 0.8,
        upperBound: 1.2,
      );
    }

    return repostDetailsList;
  }

  Future<void> _handleLike(int postId, int userId, int itemId) async {
    try {
      if (_isLikedMap[itemId]!) {
        await PostService.unlikePost(
          LikeRequest(userId: userId, postId: postId),
        );
        setState(() {
          _isLikedMap[itemId] = false;
          _likeCountMap[itemId] = _likeCountMap[itemId]! - 1;
        });
      } else {
        await PostService.likePost(
          LikeRequest(userId: userId, postId: postId),
        );
        setState(() {
          _isLikedMap[itemId] = true;
          _likeCountMap[itemId] = _likeCountMap[itemId]! + 1;
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

  Future<void> _handleBookmark(int postId, int itemId) async {
    try {
      bool isLoggedIn = await LoginService().isLoggedIn();

      if (!isLoggedIn) {
        throw Exception('Session expired');
      }

      final userId = await LoginService().getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      await _bookmarkAnimationControllers[itemId]!.forward();

      if (_isBookmarkedMap[itemId]!) {
        await PostService.unbookmarkPost(
          BookmarkRequest(userId: userId, postId: postId),
        );
        await _bookmarkAnimationControllers[itemId]!.reverse();
      } else {
        await PostService.bookmarkPost(
          BookmarkRequest(userId: userId, postId: postId),
        );
      }

      setState(() {
        _isBookmarkedMap[itemId] = !_isBookmarkedMap[itemId]!;
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

  void _showPostOptions(
      BuildContext context, RepostDetailsModel repostDetails, int itemId) {
    // Implement options similar to RepostDetailsPage
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
    return FutureBuilder<List<RepostDetailsModel>>(
      future: _futureRepostDetails,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final repostDetailsList = snapshot.data!;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Shared Post Details',
                  style: TextStyle(color: Colors.black)),
              backgroundColor: Colors.white,
              iconTheme: const IconThemeData(color: Color(0xFFF45F67)),
              elevation: 0,
            ),
            body: ListView.builder(
              itemCount: repostDetailsList.length,
              itemBuilder: (context, index) {
                final repostDetails = repostDetailsList[index];
                final sharer = repostDetails.user;
                final post = repostDetails.post;
                final author = post.author;
                final itemId = repostDetails.itemId;

                bool _isLiked = _isLikedMap[itemId] ?? false;
                int _likeCount = _likeCountMap[itemId] ?? 0;
                bool _isBookmarked = _isBookmarkedMap[itemId] ?? false;
                AnimationController _bookmarkAnimationController =
                    _bookmarkAnimationControllers[itemId]!;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 0.0, vertical: 8.0),
                  child: Container(
                    width: MediaQuery.of(context).size.width, // Full width
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(15.0), // Softer rounded corners
                      color: Colors.white, // White background for the PostCard
                      border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1), // Thin grey border
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
                                  int? currentUserId =
                                      await LoginService().getUserId();
                                  if (currentUserId == sharer.userId) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ProfilePage()),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            OtherUserProfilePage(
                                          otherUserId: sharer.userId,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: CircleAvatar(
                                  backgroundImage:
                                      sharer.profilePictureUrl.isNotEmpty
                                          ? CachedNetworkImageProvider(
                                              sharer.profilePictureUrl)
                                          : AssetImage(
                                                  'assets/images/default.png')
                                              as ImageProvider,
                                  radius: 18,
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    int? currentUserId =
                                        await LoginService().getUserId();
                                    if (currentUserId == sharer.userId) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                ProfilePage()),
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              OtherUserProfilePage(
                                            otherUserId: sharer.userId,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 12.0),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.more_vert,
                                    color: Color(0xFFF45F67)),
                                onPressed: () {
                                  _showPostOptions(
                                      context, repostDetails, itemId);
                                },
                              ),
                            ],
                          ),
                          // Repost Content (Comment)
                          if (repostDetails.content.isNotEmpty) ...[
                            const SizedBox(height: 8.0),
                            Text(
                              repostDetails.content,
                              style: const TextStyle(
                                  fontSize: 16.0, color: Colors.black87),
                            ),
                          ],
                          // Original Post Content
                          const SizedBox(height: 8.0),
                          _buildOriginalPost(
                              context,
                              repostDetails,
                              _isLiked,
                              _likeCount,
                              _isBookmarked,
                              _bookmarkAnimationController,
                              itemId),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Shared Post Details'),
            ),
            body: const Center(
                child: Text('Failed to load shared post details')),
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

  Widget _buildOriginalPost(
      BuildContext context,
      RepostDetailsModel repostDetails,
      bool _isLiked,
      int _likeCount,
      bool _isBookmarked,
      AnimationController _bookmarkAnimationController,
      int itemId) {
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
                  backgroundImage: author != null &&
                          author.profilePictureUrl.isNotEmpty
                      ? CachedNetworkImageProvider(author.profilePictureUrl)
                      : AssetImage('assets/images/default.png')
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
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
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
          _buildPostActions(post, _isLiked, _likeCount, _isBookmarked,
              _bookmarkAnimationController, itemId),
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
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error),
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

  Widget _buildPostActions(
      PostInfo post,
      bool _isLiked,
      int _likeCount,
      bool _isBookmarked,
      AnimationController _bookmarkAnimationController,
      int itemId) {
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
              _handleLike(post.postId, userId, itemId);
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
              _handleBookmark(post.postId, itemId);
            },
          ),
        ),
      ],
    );
  }
}
