import 'package:flutter/material.dart';
import 'package:myapp/services/userpost_service.dart';
import 'package:myapp/models/post_model.dart';
import 'package:myapp/models/LikeRequest_model.dart';
import 'package:myapp/models/bookmarkrequest_model.dart';
import 'package:myapp/home/comment.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:myapp/services/Post_Service.dart';
import 'package:myapp/maintenance/expiredtoken.dart';
import 'package:myapp/services/SessionExpiredException.dart';

/// Displays the list of saved (bookmarked) posts for a given user.
/// Provides:
///   - Pagination for saved posts
///   - Like/Unlike (optimistic update)
///   - Bookmark/Unbookmark (optimistic update)
///   - Navigation to CommentPage
///   - Session expiration handling

class SavedPostsPage extends StatefulWidget {
  final int userId;

  const SavedPostsPage({Key? key, required this.userId}) : super(key: key);

  @override
  _SavedPostsPageState createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends State<SavedPostsPage> {
  final ScrollController _scrollController = ScrollController();
  final UserpostService _userpostService = UserpostService();

  // List of all bookmarked posts loaded so far
  List<Post> bookmarkedPosts = [];

  // Pagination state
  bool isPaginating = false;
  int currentPage = 1;
  final int pageSize = 10;
  bool hasMorePosts = true;

  // Loading (initial fetch) state
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchBookmarkedPosts();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  /// When the user scrolls to the bottom, try to load more posts (if any).
  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
        !isPaginating &&
        hasMorePosts) {
      _fetchBookmarkedPosts();
    }
  }

  /// Fetch a page of bookmarked posts from the server.
  Future<void> _fetchBookmarkedPosts() async {
    if (isPaginating || !hasMorePosts) return;

    setState(() {
      isPaginating = true;
    });

    try {
      final newBookmarks = await _userpostService.fetchBookmarkedPosts(
        widget.userId,
        currentPage,
        pageSize,
      );

      setState(() {
        bookmarkedPosts.addAll(newBookmarks);

        // If fewer than pageSize results were returned, no more posts are available
        if (newBookmarks.length < pageSize) {
          hasMorePosts = false;
        }
        currentPage++;
      });
    } on SessionExpiredException {
      // Handle session/token expiration
      handleSessionExpired(context);
    } catch (e) {
      debugPrint("Error fetching bookmarked posts: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while fetching bookmarked posts.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isPaginating = false;
        isLoading = false;
      });
    }
  }

  /// Helper: Replaces the oldPost with newPost in the bookmarkedPosts list.
  void _updatePostInList(Post oldPost, Post newPost) {
    final index = bookmarkedPosts.indexWhere((p) => p.postId == oldPost.postId);
    if (index != -1) {
      setState(() {
        bookmarkedPosts[index] = newPost;
      });
    }
  }

  /// Toggle like/unlike by creating a new Post instance with updated fields.
  Future<void> _toggleLike(Post post) async {
    try {
      final request = LikeRequest(userId: widget.userId, postId: post.postId);

      // Create a new Post with toggled isLiked and adjusted likeCount
      final newLikeState = !post.isLiked;
      final newLikeCount = newLikeState ? post.likeCount + 1 : post.likeCount - 1;

      final updatedPost = Post(
        postId: post.postId,
        caption: post.caption,
        commentCount: post.commentCount,
        createdAt: post.localCreatedAt.toUtc(),
        isPublic: post.isPublic,
        likeCount: newLikeCount,
        userId: post.userId,
        fullName: post.fullName,
        profilePic: post.profilePic,
        media: post.media,
        isLiked: newLikeState,
        isBookmarked: post.isBookmarked,
      );

      // Optimistically update in the UI
      _updatePostInList(post, updatedPost);

      // Perform the actual API call
      if (newLikeState) {
        await PostService.likePost(request);
      } else {
        await PostService.unlikePost(request);
      }
    } catch (e) {
      debugPrint("Error toggling like: $e");
      // Revert changes on error:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update like status.'),
          backgroundColor: Colors.red,
        ),
      );
      // Optionally, re-fetch or re-update the list from the server
      // or just leave it out if you prefer not to revert
    }
  }

  /// Toggle bookmark/unbookmark by creating a new Post instance with updated isBookmarked.
  Future<void> _toggleBookmark(Post post) async {
    try {
      final request = BookmarkRequest(userId: widget.userId, postId: post.postId);

      final newBookmarkState = !post.isBookmarked;
      // Keep other fields the same; only change isBookmarked
      final updatedPost = Post(
        postId: post.postId,
        caption: post.caption,
        commentCount: post.commentCount,
        createdAt: post.localCreatedAt.toUtc(),
        isPublic: post.isPublic,
        likeCount: post.likeCount,
        userId: post.userId,
        fullName: post.fullName,
        profilePic: post.profilePic,
        media: post.media,
        isLiked: post.isLiked,
        isBookmarked: newBookmarkState,
      );

      // Optimistic UI update
      _updatePostInList(post, updatedPost);

      // API call
      if (newBookmarkState) {
        await PostService.bookmarkPost(request);
      } else {
        await PostService.unbookmarkPost(request);
      }
    } catch (e) {
      debugPrint("Error toggling bookmark: $e");
      // Revert changes on error:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update bookmark status.'),
          backgroundColor: Colors.red,
        ),
      );
      // Optionally reload or revert the change if desired
    }
  }

  /// Builds a single post card for each bookmarked post.
  Widget _buildPostCard(Post post) {
    const primaryColor = Color(0xFFF45F67);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + name + created time
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(post.profilePic),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(post.localCreatedAt),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Caption
            if (post.caption.isNotEmpty)
              Text(
                post.caption,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            if (post.caption.isNotEmpty) const SizedBox(height: 8),

            // Single image from media (if any). If you have multiple images,
            // you can extend this to a PageView or a Carousel
            if (post.media.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post.media.first.mediaUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error),
                ),
              ),
            if (post.media.isNotEmpty) const SizedBox(height: 8),

            // Post actions: Like, Comment, Bookmark
            Row(
              children: [
                // Like button
                IconButton(
                  icon: Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: post.isLiked ? primaryColor : Colors.grey,
                  ),
                  onPressed: () => _toggleLike(post),
                ),
                Text('${post.likeCount}'),

                const SizedBox(width: 16),

                // Comment button
                IconButton(
                  icon: const Icon(Icons.comment, color: Colors.grey),
                  onPressed: () {
                    // Navigate to your existing comment page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommentPage(postId: post.postId),
                      ),
                    );
                  },
                ),
                Text('${post.commentCount}'),

                const Spacer(),

                // Bookmark button
                IconButton(
                  icon: Icon(
                    post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: post.isBookmarked ? primaryColor : Colors.grey,
                  ),
                  onPressed: () => _toggleBookmark(post),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Main UI
  /// - Shows a loader while fetching the first page
  /// - Shows "No bookmarked posts yet" if empty
  /// - Otherwise, a ListView of posts with optional bottom-loading indicator
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved Posts',
          style: TextStyle(color: Color(0xFFF45F67)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFF45F67)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookmarkedPosts.isEmpty
              ? const Center(
                  child: Text(
                    'No bookmarked posts yet.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: bookmarkedPosts.length + (isPaginating ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == bookmarkedPosts.length) {
                      // Show a bottom loader while fetching more data
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final post = bookmarkedPosts[index];
                    return _buildPostCard(post);
                  },
                ),
    );
  }
}
