import 'package:cook/services/Userprofile_service.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cook/models/sharedpost_model.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cook/services/Post_Service.dart';
import 'package:cook/models/LikeRequest_model.dart';
import 'package:cook/models/bookmarkrequest_model.dart';
import 'package:cook/services/LoginService.dart';
import 'package:cook/home/comment.dart';
import 'package:cook/home/report_dialog.dart';
import 'package:cook/services/SessionExpiredException.dart';
import 'package:cook/maintenance/expiredtoken.dart';



class SharedPostDetailsPage extends StatefulWidget {
  final List<SharedPostDetails> sharedPosts;
  final int initialIndex;
  final bool isCurrentUserProfile; // Add this flag

  SharedPostDetailsPage({
    Key? key,
    required List<SharedPostDetails> sharedPosts,
    required this.initialIndex,
    required this.isCurrentUserProfile, // Pass this flag to constructor
  })  : sharedPosts = sharedPosts
            .toList() 
            ..sort((a, b) => b.sharedAt.compareTo(a.sharedAt)),
        super(key: key);

  @override
  _SharedPostDetailsPageState createState() => _SharedPostDetailsPageState();
}

class _SharedPostDetailsPageState extends State<SharedPostDetailsPage> with TickerProviderStateMixin {
  late ScrollController _scrollController;
  final LoginService _loginService = LoginService();
  final UserProfileService _userProfileService = UserProfileService();

  // Lists to keep track of like status, like counts, and bookmark status for each post
  late List<bool> _isLikedList;
  late List<int> _likeCountList;
  late List<bool> _isBookmarkedList;
  late List<AnimationController> _bookmarkAnimationControllers;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: widget.initialIndex * 300.0,
    );

    // Initialize the lists
    _isLikedList = widget.sharedPosts.map((post) => post.isLiked).toList();
    _likeCountList = widget.sharedPosts.map((post) => post.likecount).toList();
    _isBookmarkedList = widget.sharedPosts.map((post) => post.isBookmarked).toList();

    // Initialize animation controllers for bookmarks
    _bookmarkAnimationControllers = List.generate(widget.sharedPosts.length, (_) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.8,
      upperBound: 1.2,
    ));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var controller in _bookmarkAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

Future<void> _editSharedPostComment(SharedPostDetails sharedPost, String newComment) async {
  final userId = await _loginService.getUserId();
  if (userId == null) return;

  try {
    bool success = await _userProfileService.editSharedPostComment(
      sharedPost.shareId,
      newComment,  // Pass the updated comment
      userId,
    );

    if (success) {
      setState(() {
        sharedPost.comment = newComment; // Update the UI with the new comment
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Shared post comment updated successfully!'),
        backgroundColor: Colors.green,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update shared post comment.'),
        backgroundColor: Colors.red,
      ));
    }
  } on SessionExpiredException {
    print('SessionExpired detected in _editSharedPostComment');
    // Trigger session expired UI
    handleSessionExpired(context);
  } catch (e) {
    print('Error updating shared post comment: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
        widget.sharedPosts.removeAt(index); // Remove post from list immediately
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Shared post deleted successfully!'),
        backgroundColor: Colors.green,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to delete the shared post'),
        backgroundColor: Colors.red,
      ));
    }
  }  on SessionExpiredException {
    print('SessionExpired detected in _deleteSharedPost');
    // Handle the session expiration here
    handleSessionExpired(context); // Trigger session expired dialog or navigation
  } catch (e) {
    print('Error occurred while deleting sharedpost: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('An error occurred while deleting the sharedpost'),
      backgroundColor: Colors.red,
    ));
  }
}

  // Handle like/unlike action
Future<void> _handleLike(int index) async {
  final userId = await _loginService.getUserId();

  if (userId == null) {
    return;
  }

  final sharedPost = widget.sharedPosts[index];

  try {
    if (_isLikedList[index]) {
      // Unlike the post
      await PostService.unlikePost(
        LikeRequest(userId: userId, postId: sharedPost.postId),
      );
      setState(() {
        _isLikedList[index] = false;
        _likeCountList[index] -= 1;
      });
    } else {
      // Like the post
      await PostService.likePost(
        LikeRequest(userId: userId, postId: sharedPost.postId),
      );
      setState(() {
        _isLikedList[index] = true;
        _likeCountList[index] += 1;
      });
    }
  } catch (e) {
    // Handle errors
    print('Failed to like/unlike post: $e');
  }
}


// Handle bookmark/unbookmark action
Future<void> _handleBookmark(int index) async {
  final userId = await _loginService.getUserId();

  if (userId == null) {
    return;
  }

  final sharedPost = widget.sharedPosts[index];
  await _bookmarkAnimationControllers[index].forward();

  try {
    if (_isBookmarkedList[index]) {
      // Unbookmark the post
      await PostService.unbookmarkPost(
        BookmarkRequest(userId: userId, postId: sharedPost.postId),
      );
      setState(() {
        _isBookmarkedList[index] = false;
      });
    } else {
      // Bookmark the post
      await PostService.bookmarkPost(
        BookmarkRequest(userId: userId, postId: sharedPost.postId),
      );
      setState(() {
        _isBookmarkedList[index] = true;
      });
    }
  } catch (e) {
    // Handle errors
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
      appBar:AppBar(
          centerTitle: true,
          title: Text('Shared Posts', style: TextStyle(color: Color(0xFFF45F67))),
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Color(0xFFF45F67)),
        ),
      backgroundColor: Colors.grey[100],
      body: ListView.builder(
      controller: _scrollController,
      itemCount: widget.sharedPosts.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
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
          handleEdit: (newComment) => _editSharedPostComment(sharedPost, newComment),  // Pass edit method
          handleDelete: () => _deleteSharedPost(index),  // Pass the index here
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
  bool _isEditingComment = false; // Flag for editing comment
  late TextEditingController _commentController;

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
    _isEditingComment = !_isEditingComment; // Toggle edit mode
    if (!_isEditingComment) {
      // Reset the comment if editing is canceled
      _commentController.text = widget.sharedPost.comment ?? '';
    }
  });
}

void _saveEditedComment() {
  widget.handleEdit(_commentController.text); // Update comment in the backend
  setState(() {
    _isEditingComment = false; // Exit edit mode
  });
}


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
        maxLines: 2,
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _toggleEditComment, // Cancel button action
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: _saveEditedComment, // Save button action
            child: Text(
              'Save',
              style: TextStyle(color: Color(0xFFF45F67)),
            ),
          ),
        ],
      ),
    ],
  );
}


  void _showPostOptions(BuildContext context) {
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

            // If it's the current user's profile, show Edit and Delete options
            if (widget.isCurrentUserProfile) ...[
              ListTile(
                leading: Icon(Icons.edit, color: Color(0xFFF45F67)),
                title: Text(
                  'Edit Comment',
                  style: TextStyle(color: Color(0xFFF45F67)), // Text color for Edit
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleEditComment();  // Toggle the edit mode for comment
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red[400]),
                title: Text(
                  'Delete Post',
                  style: TextStyle(color: Colors.red[400]), // Text color for Delete
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context); // Show confirmation dialog before deleting
                },
              ),
            ]
            // If it's another user's profile, show the Report option
            else ...[
              ListTile(
                leading: Icon(Icons.report, color: Colors.red[400]),
                title: Text(
                  'Report Post',
                  style: TextStyle(color: Colors.red[400]), // Text color for Report
                ),
                onTap: () {
                    Navigator.pop(context); // Close the action dialog
                    // Check if originalPostUserId is available
                    if (widget.sharedPost.originalPostUserId != null) {
                      final int userId = widget.sharedPost.originalPostUserId!;
                      // Display the report dialog
                      showReportDialog(
                        context: context,
                        reportedUser: userId,
                        contentId: widget.sharedPost.postId,
                      );
                    } else {
                      // Show a snackbar if the user ID is not available
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        backgroundColor: Colors.white,
        title: Text(
          "Confirm Deletion",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
            color: Color(0xFFF45F67),
          ),
        ),
        content: Text(
          "Are you sure you want to delete this post?",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              widget.handleDelete();  // Call the delete callback
            },
            child: Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
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
        // Reposter Information Row with Options Icon
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage: widget.sharedPost.sharerProfileUrl != null
                  ? CachedNetworkImageProvider(widget.sharedPost.sharerProfileUrl!)
                  : AssetImage('assets/images/default.png') as ImageProvider,
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
              icon: Icon(Icons.more_vert, color: Color(0xFFF45F67)),
              onPressed: () {
                _showPostOptions(context); // Open post options based on user
              },
            ),
          ],
        ),

        // Comment Editing Section with Save and Cancel buttons
        if (_isEditingComment)
          Column(
            children: [
              TextField(
                controller: _commentController,
                maxLines: 3,
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
                  ElevatedButton(
                    onPressed: _saveEditedComment, // Save the comment
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    child: Text("Save"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isEditingComment = false; // Cancel editing
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    child: Text("Cancel"),
                  ),
                ],
              ),
            ],
          )
        else if (widget.sharedPost.comment != null && widget.sharedPost.comment!.isNotEmpty) ...[
          const SizedBox(height: 8.0),
          Text(
            widget.sharedPost.comment!,
            style: const TextStyle(fontSize: 16.0, color: Colors.black87),
          ),
        ],
        
        // Original Post Content
        const SizedBox(height: 8.0),
        _buildOriginalPost(context),
      ],
    ),
  );
}

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
        // Original Author Information Row
        Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.sharedPost.originalPostUserUrl != null
                  ? CachedNetworkImageProvider(widget.sharedPost.originalPostUserUrl!)
                  : AssetImage('assets/images/default.png') as ImageProvider,
              radius: 18,
            ),
            const SizedBox(width: 8.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.sharedPost.originalPostuserfullname,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
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
        if (widget.sharedPost.postContent.isNotEmpty)
          Text(
            widget.sharedPost.postContent,
            style: const TextStyle(fontSize: 16.0),
          ),
        const SizedBox(height: 8.0),
        _buildMediaContent(screenWidth),
        const SizedBox(height: 8.0),
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
    double maxHeight = 300.0;
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
        // Like Button with Border
        IconButton(
          icon: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                color: Color(0xFFF45F67),
                size: 28,
              ),
              if (widget.isLiked)
                Icon(
                  Icons.favorite,
                  color: Color(0xFFF45F67),
                  size: 28,
                ),
            ],
          ),
          onPressed: widget.handleLike,
        ),
        Text(
          '${widget.likeCount}',
          style: TextStyle(color: Color(0xFFF45F67)),
        ),
        const SizedBox(width: 16.0),

        // Comment Button with Border
        IconButton(
          icon: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.comment,
                color: Color(0xFFF45F67),
                size: 28,
              ),
              Icon(
                Icons.comment,
                color: Colors.transparent,
                size: 28,
              ),
            ],
          ),
          onPressed: widget.viewComments,
        ),
        Text(
          '${widget.sharedPost.commentcount}',
          style: TextStyle(color: Color(0xFFF45F67)),
        ),
        const SizedBox(width: 16.0),

        const Spacer(),

        // Bookmark Button with Border
        ScaleTransition(
          scale: widget.bookmarkAnimationController,
          child: IconButton(
            icon: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.bookmark_border,
                  color: Color(0xFFF45F67),
                  size: 28,
                ),
                if (widget.isBookmarked)
                  Icon(
                    Icons.bookmark,
                    color: Color(0xFFF45F67),
                    size: 28,
                  ),
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
