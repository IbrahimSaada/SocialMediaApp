import 'package:flutter/material.dart';
import '***REMOVED***/models/comment_model.dart';
import '***REMOVED***/services/commentservice.dart';
import '***REMOVED***/models/comment_request_model.dart';
import '***REMOVED***/services/LoginService.dart';
import 'package:timeago/timeago.dart' as timeago;
import '***REMOVED***/services/GenerateReportService.dart';
import '***REMOVED***/models/ReportRequest_model.dart';
import '***REMOVED***/maintenance/expiredtoken.dart';
import 'package:shimmer/shimmer.dart'; // Import shimmer package
import '***REMOVED***/profile/otheruserprofilepage.dart';
import '***REMOVED***/profile/profile_page.dart';

class CommentPage extends StatefulWidget {
  final int postId;

  const CommentPage({super.key, required this.postId});

  @override
  // ignore: library_private_types_in_public_api
  _CommentPageState createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoading = true; // Loading state
  bool _isPosting = false; // Posting state
  bool _showScrollToBottom =
      false; // State for showing the scroll-to-bottom arrow
  Comment? _replyingTo;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });
    _scrollController
        .addListener(_scrollListener); // Attach the scroll listener
    _fetchComments();
    _fetchCurrentUserId();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _reportComment(Comment comment, String reportReason) async {
    final userId = await LoginService().getUserId();
    if (userId == null) return;

    final reportRequest = ReportRequest(
      reportedBy: userId,
      reportedUser: comment.userId,
      contentType: 'Comment',
      contentId: comment.commentId,
      reportReason: reportReason,
      resolutionDetails: '',
    );

    try {
      final reportService = ReportService();
      await reportService.createReport(reportRequest);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment reported successfully')),
      );
  } catch (e) {
    if (e.toString().contains("Session expired")) {
      // ignore: use_build_context_synchronously
      handleSessionExpired(context);  // Trigger session expired dialog if the token is expired
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to report comment')),
      );
    }
  }
}

  // Scroll listener to toggle the scroll-to-bottom button
  void _scrollListener() {
    if (_scrollController.position.atEdge) {
      if (_scrollController.position.pixels == 0) {
        // At the top
        setState(() {
          _showScrollToBottom = false;
        });
      } else {
        // At the bottom
        setState(() {
          _showScrollToBottom = false;
        });
      }
    } else {
      setState(() {
        _showScrollToBottom = true;
      });
    }
  }

  Future<void> _fetchCurrentUserId() async {
    _currentUserId = await LoginService().getUserId();
  }

  Future<void> _fetchComments() async {
    setState(() {
      _isLoading = true; // Set loading state to true before fetching comments
    });
    try {
      List<Comment> comments =
          await CommentService.fetchComments(widget.postId);
      setState(() {
        _comments = comments;
        _isLoading = false; // Set loading state to false after fetching
      });
  } catch (e) {
    // ignore: avoid_print
    print('Failed to load comments: $e');
    if (e.toString().contains("Session expired")) {
      // ignore: use_build_context_synchronously
      handleSessionExpired(context); // Trigger session expired dialog
      setState(() {
        _isLoading =
            true; // Keep the loading state true if there's an error to keep showing shimmer
      });
    }
  }
  
  }

  Future<void> _postComment() async {
    if (_commentController.text.isEmpty || _isPosting) return;

    setState(() {
      _isPosting = true; // Set posting state to true to disable button
    });

    try {
      final userId = await LoginService().getUserId();
      final newCommentText = _commentController.text;

      final commentRequest = CommentRequest(
        postId: widget.postId,
        userId: userId!,
        text: newCommentText,
        parentCommentId: _replyingTo?.commentId,
      );

      await CommentService.postComment(commentRequest);

      _commentController.clear();
      _replyingTo = null;

      await _fetchComments();
  } catch (e) {
    // ignore: avoid_print
    print('Failed to post comment: $e');
    if (e.toString().contains("Session expired")) {
      // ignore: use_build_context_synchronously
      handleSessionExpired(context); // Trigger session expired dialog
    }
  } finally {
    setState(() {
      _isPosting = false;
    });
  }
}

  Future<void> _editComment(Comment comment) async {
    if (_commentController.text.isEmpty || _isPosting) return;

    setState(() {
      _isPosting = true; // Set posting state to true to disable button
    });

    try {
      final commentRequest = CommentRequest(
        postId: widget.postId,
        userId: _currentUserId!,
        text: _commentController.text,
      );

      await CommentService.editComment(commentRequest, comment.commentId);

      _commentController.clear();
      _replyingTo = null;

      await _fetchComments();
  } catch (e) {
    // ignore: avoid_print
    print('Failed to edit comment: $e');
    if (e.toString().contains("Session expired")) {
      // ignore: use_build_context_synchronously
      handleSessionExpired(context); // Trigger session expired dialog
    }
  } finally {
      setState(() {
        _isPosting = false; // Reset posting state
      });
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    try {
      await CommentService.deleteComment(
          widget.postId, comment.commentId, _currentUserId!);

      await _fetchComments();
  } catch (e) {
    // ignore: avoid_print
    print('Failed to delete comment: $e');
    if (e.toString().contains("Session expired")) {
      // ignore: use_build_context_synchronously
      handleSessionExpired(context); // Trigger session expired dialog
    }
  }
}

  void _onReplyPressed(Comment comment) {
    setState(() {
      _replyingTo = comment;
    });
    FocusScope.of(context).requestFocus(_focusNode);
  }

  void _onEditComment(Comment comment) {
    _commentController.text = comment.text;
    _replyingTo = comment;
    FocusScope.of(context).requestFocus(_focusNode);
  }

  void _onDeleteComment(Comment comment) {
    _deleteComment(comment);
  }

  void _showCommentOptions(
      BuildContext context, TapDownDetails details, Comment comment) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: _currentUserId == comment.userId
          ? [
              PopupMenuItem(
                value: 'edit',
                child: _buildMenuItem(Icons.edit, 'Edit'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: _buildMenuItem(Icons.delete, 'Delete'),
              ),
              PopupMenuItem(
                value: 'reply',
                child: _buildMenuItem(Icons.reply, 'Reply'),
              ),
            ]
          : [
              PopupMenuItem(
                value: 'spam',
                child: _buildMenuItem(Icons.report_problem, 'Spam'),
              ),
              PopupMenuItem(
                value: 'inappropriate',
                child: _buildMenuItem(
                    Icons.visibility_off, 'Inappropriate Content'),
              ),
              PopupMenuItem(
                value: 'misinformation',
                child: _buildMenuItem(Icons.info, 'Misinformation'),
              ),
              PopupMenuItem(
                value: 'harassment',
                child: _buildMenuItem(Icons.flag, 'Harassment or Bullying'),
              ),
            ],
      color: Colors.white,
    ).then((value) {
      if (value == 'edit') {
        _onEditComment(comment);
      } else if (value == 'delete') {
        _onDeleteComment(comment);
      } else if (value == 'reply') {
        _onReplyPressed(comment);
      } else if (value != null) {
        _reportComment(comment, value); // Use value to determine report reason
      }
    });
  }

  Widget _buildMenuItem(IconData icon, String text) {
    return ListTile(
      leading: Icon(icon, color: Colors.redAccent),
      title: Text(
        text,
        style: const TextStyle(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFFF45F67)),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => _focusNode.unfocus(),
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _isLoading
                    ? List.generate(
                        10,
                        (index) =>
                            _buildShimmerComment()) // Display enough shimmers to fill the page
                    : _comments
                        .map((comment) => _buildParentComment(comment))
                        .toList(),
              ),
            ),
          ),
          if (_showScrollToBottom)
            Positioned(
              bottom: 100.0,
              right: 16.0,
              child: FloatingActionButton(
                backgroundColor: Color(0xFFF45F67),
                child: const Icon(Icons.arrow_downward, color: Colors.white),
                onPressed: () {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 8.0,
          left: 16.0,
          right: 16.0,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: _replyingTo == null
                      ? 'Add a comment...'
                      : 'Reply to ${_replyingTo!.fullName}...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: const BorderSide(color: Color(0xFFF45F67)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: const BorderSide(color: Color(0xFFF45F67)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: const BorderSide(color: Color(0xFFF45F67)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFFF45F67), size: 28),
              onPressed: _isPosting
                  ? null
                  : () {
                      if (_replyingTo != null &&
                          _replyingTo!.userId == _currentUserId) {
                        _editComment(_replyingTo!);
                      } else {
                        _postComment();
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentComment(Comment comment) {
    bool showReplies = comment.isRepliesVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildComment(
          comment: comment,
          onReplyPressed: () => _onReplyPressed(comment),
        ),
        const SizedBox(height: 6.0),
        Row(
          children: [
            GestureDetector(
              onTap: () => _onReplyPressed(comment),
              child: const Text(
                "Reply",
                style: TextStyle(color: Color(0xFFF45F67), fontSize: 16),
              ),
            ),
            const SizedBox(width: 12.0),
            if (comment.replies.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    showReplies = !showReplies;
                    comment.isRepliesVisible = showReplies;
                  });
                },
                child: Text(
                  showReplies ? "Hide replies" : "Show replies",
                  style: const TextStyle(color: Color(0xFFF45F67), fontSize: 16),
                ),
              ),
          ],
        ),
        if (showReplies && comment.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: comment.replies.expand((reply) {
                return _flattenReplies(
                    reply, comment.fullName); // Pass the parent's full name
              }).toList(),
            ),
          ),
        _buildDivider(),
      ],
    );
  }

  List<Widget> _flattenReplies(Comment reply, String parentFullName) {
    List<Widget> flatReplies = [];

    flatReplies.add(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildComment(
            comment: reply,
            onReplyPressed: () => _onReplyPressed(reply),
            parentFullName: parentFullName, // Pass the parent's full name
          ),
          const SizedBox(height: 6.0),
          Row(
            children: [
              GestureDetector(
                onTap: () => _onReplyPressed(reply),
                child: const Text(
                  "Reply",
                  style: TextStyle(color: Color(0xFFF45F67), fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (reply.replies.isNotEmpty) {
      flatReplies.addAll(reply.replies.expand((nestedReply) {
        return _flattenReplies(nestedReply, reply.fullName);
      }).toList());
    }

    return flatReplies;
  }

  Widget _buildComment({
  required Comment comment,
  required Function() onReplyPressed,
  String? parentFullName, // This will hold the parent's full name
}) {
  final DateTime commentTime = comment.localCreatedAt;
  final String timeDisplay = timeago.format(commentTime, locale: 'en_short');

  return GestureDetector(
    onTapDown: (details) => _showCommentOptions(context, details, comment),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () async {
            int? currentUserId = await LoginService().getUserId(); // Fetch current user's ID
            if (currentUserId == comment.userId) {
              // If it's the logged-in user, navigate to ProfilePage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(), // Navigate to ProfilePage
                ),
              );
            } else {
              // If it's another user, navigate to OtherUserProfilePage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OtherUserProfilePage(
                    otherUserId: comment.userId, // Navigate to the other user's profile
                  ),
                ),
              );
            }
          },
          child: CircleAvatar(
            backgroundImage: NetworkImage(comment.userProfilePic),
            radius: 20.0,
          ),
        ),
        const SizedBox(width: 12.0),
        GestureDetector(
          onTap: () async {
            int? currentUserId = await LoginService().getUserId(); // Fetch current user's ID
            if (currentUserId == comment.userId) {
              // If it's the logged-in user, navigate to ProfilePage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(), // Navigate to ProfilePage
                ),
              );
            } else {
              // If it's another user, navigate to OtherUserProfilePage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OtherUserProfilePage(
                    otherUserId: comment.userId, // Navigate to the other user's profile
                  ),
                ),
              );
            }
          },
          child: Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      timeDisplay,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                if (parentFullName != null) // Display the username being replied to
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Replying to $parentFullName',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                const SizedBox(height: 6.0),
                Text(
                  comment.text,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildDivider() {
    return Column(
      children: [
        const SizedBox(height: 8.0),
        Divider(
          color: Colors.grey[300],
          thickness: 1,
        ),
        const SizedBox(height: 8.0),
      ],
    );
  }

  Widget _buildShimmerComment() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 12.0), // Increased vertical padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile picture shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 20.0,
            ),
          ),
          const SizedBox(width: 16.0), // Increased spacing between shimmer elements
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Short username placeholder
                  Container(
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: 12, // Slightly taller for better visibility
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    margin: const EdgeInsets.only(
                        bottom: 6.0), // More space between lines
                  ),
                  // Time placeholder
                  Container(
                    width: MediaQuery.of(context).size.width * 0.2,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    margin: const EdgeInsets.only(
                        bottom: 10.0), // Increased bottom margin
                  ),
                  // Long caption placeholder
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    margin: const EdgeInsets.only(bottom: 6.0),
                  ),
                  // Optional second line for caption
                  Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    margin: const EdgeInsets.only(bottom: 6.0),
                  ),
                  // Additional smaller line for captions
                  Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    margin: const EdgeInsets.only(bottom: 6.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
