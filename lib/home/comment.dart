// comment.dart

import 'package:flutter/material.dart';
import 'package:cook/models/comment_model.dart';
import 'package:cook/models/comment_request_model.dart';
import 'package:cook/services/commentservice.dart';
import 'package:cook/services/LoginService.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cook/services/GenerateReportService.dart';
import 'package:cook/models/ReportRequest_model.dart';
import 'package:cook/maintenance/expiredtoken.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cook/profile/otheruserprofilepage.dart';
import 'package:cook/profile/profile_page.dart';
import '../services/SessionExpiredException.dart';
import 'package:cook/models/paginated_comment_response.dart';

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

class CommentPage extends StatefulWidget {
  final int postId;

  const CommentPage({super.key, required this.postId});

  @override
  _CommentPageState createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();

  List<Comment> _comments = [];

  /// `_isLoading` controls the **initial** page load (show shimmer).
  bool _isLoading = false;

  /// `_isLoadingMore` controls whether we’re fetching the **next** page
  /// (shows a small bottom loader, not a full shimmer).
  bool _isLoadingMore = false;

  bool _isPosting = false;
  bool _showScrollToBottom = false;
  Comment? _replyingTo;
  int? _currentUserId;

  // For pagination
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalPages = 1; // We'll keep track of total pages from backend

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // Scroll to bottom after focusing (e.g. to show the text field).
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });

    _scrollController.addListener(_scrollListener);

    _fetchCurrentUserId();
    _fetchComments(page: _currentPage, pageSize: _pageSize, append: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  /// If user scrolls near the bottom, load more if more pages are available.
  void _scrollListener() {
    // How close we are to the bottom before loading more:
    const double threshold = 200.0;
    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    // If within `threshold` pixels of the bottom, load next page if possible.
    if (currentScroll >= (maxScroll - threshold)) {
      if (!_isLoadingMore && !_isLoading && _currentPage < _totalPages) {
        _currentPage++;
        _fetchComments(page: _currentPage, pageSize: _pageSize, append: true);
      }
    }

    // Show or hide the "scroll to bottom" FAB
    if (position.atEdge) {
      // Reached top or bottom
      setState(() {
        _showScrollToBottom = false;
      });
    } else {
      setState(() {
        _showScrollToBottom = true;
      });
    }
  }

  Future<void> _fetchCurrentUserId() async {
    _currentUserId = await LoginService().getUserId();
  }

  /// Fetch (and optionally append) comments from the backend.
  /// `append: false` => initial or "replace" load
  /// `append: true`  => load next page & add to existing list
  Future<void> _fetchComments({
    int page = 1,
    int pageSize = 10,
    bool append = false,
  }) async {
    // If this is an "append" load (next page), show small loader at bottom.
    // Otherwise, show the shimmer for initial load.
    if (append) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() => _isLoading = true);
    }

    try {
      final paginated = await CommentService.fetchComments(
        widget.postId,
        pageNumber: page,
        pageSize: pageSize,
      );

      setState(() {
        if (append) {
          _comments.addAll(paginated.comments);
        } else {
          _comments = paginated.comments;
        }
        _currentPage = paginated.currentPage;
        _pageSize = paginated.pageSize;
        _totalPages = paginated.totalPages;
      });
    } on SessionExpiredException {
      if (context.mounted) {
        handleSessionExpired(context);
      }
    } catch (e) {
      print('Failed to load comments: $e');
    } finally {
      if (append) {
        setState(() => _isLoadingMore = false);
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.isEmpty || _isPosting) return;

    setState(() {
      _isPosting = true;
    });

    try {
      final userId = await LoginService().getUserId();
      if (userId == null) {
        setState(() {
          _isPosting = false;
        });
        return;
      }

      final newCommentText = _commentController.text;
      final commentRequest = CommentRequest(
        postId: widget.postId,
        userId: userId,
        text: newCommentText,
        parentCommentId: _replyingTo?.commentId,
      );

      await CommentService.postComment(commentRequest);

      _commentController.clear();
      _replyingTo = null;

      // Reload from page 1 after posting
      _currentPage = 1;
      await _fetchComments(page: _currentPage, pageSize: _pageSize, append: false);
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
        print('Failed to post comment: $e');
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
      _isPosting = true;
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

      // Refresh current page after edit
      await _fetchComments(page: _currentPage, pageSize: _pageSize, append: false);
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
        print('Failed to edit comment: $e');
      }
    } finally {
      setState(() {
        _isPosting = false;
      });
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    try {
      await CommentService.deleteComment(
        widget.postId,
        comment.commentId,
        _currentUserId!,
      );
      // Refresh current page after delete
      await _fetchComments(page: _currentPage, pageSize: _pageSize, append: false);
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
        print('Failed to delete comment: $e');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment reported successfully')),
      );
    } catch (e) {
      if (e.toString().contains("Session expired")) {
        if (context.mounted) {
          handleSessionExpired(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to report comment')),
        );
      }
    }
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
                child: _buildMenuItem(Icons.visibility_off, 'Inappropriate Content'),
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
        _reportComment(comment, value);
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
              children: comment.replies
                  .expand((reply) => _flattenReplies(reply, comment.fullName))
                  .toList(),
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
            parentFullName: parentFullName,
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
      flatReplies.addAll(
        reply.replies.expand((nestedReply) {
          return _flattenReplies(nestedReply, reply.fullName);
        }).toList(),
      );
    }

    return flatReplies;
  }

  Widget _buildComment({
    required Comment comment,
    required Function() onReplyPressed,
    String? parentFullName,
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
              int? currentUserId = await LoginService().getUserId();
              if (currentUserId == comment.userId) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfilePage()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OtherUserProfilePage(otherUserId: comment.userId),
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
          Expanded(
            child: GestureDetector(
              onTap: () async {
                int? currentUserId = await LoginService().getUserId();
                if (currentUserId == comment.userId) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProfilePage()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OtherUserProfilePage(
                        otherUserId: comment.userId,
                      ),
                    ),
                  );
                }
              },
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
                  if (parentFullName != null)
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

  /// Builds the shimmer placeholders for the initial load.
  Widget _buildShimmerComment() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 20.0,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    margin: const EdgeInsets.only(bottom: 6.0),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.2,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    margin: const EdgeInsets.only(bottom: 10.0),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    margin: const EdgeInsets.only(bottom: 6.0),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    margin: const EdgeInsets.only(bottom: 6.0),
                  ),
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

  /// A simple loader shown at the bottom when loading more pages
  Widget _buildLoadMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Center(child: CircularProgressIndicator()),
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
                children: [
                  // If we're loading the very first page, show the shimmer placeholders
                  if (_isLoading)
                    ...List.generate(10, (index) => _buildShimmerComment())
                  else
                    // Otherwise show the actual list of comments
                    ..._comments.map((comment) => _buildParentComment(comment)).toList(),

                  // If we're fetching next pages, show a small loader at the bottom
                  if (_isLoadingMore) _buildLoadMoreIndicator(),
                ],
              ),
            ),
          ),
          if (_showScrollToBottom)
            Positioned(
              bottom: 100.0,
              right: 16.0,
              child: FloatingActionButton(
                backgroundColor: const Color(0xFFF45F67),
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
                      // If the comment being edited is by the same user, treat it as edit
                      if (_replyingTo != null && _replyingTo!.userId == _currentUserId) {
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
}
