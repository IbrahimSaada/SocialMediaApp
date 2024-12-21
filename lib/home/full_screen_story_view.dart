// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '***REMOVED***/models/storyview_response_model.dart';
import '***REMOVED***/models/story_model.dart';
import '***REMOVED***/services/LoginService.dart';
import '***REMOVED***/models/storyview_request_model.dart';
import '***REMOVED***/services/storyview_Service.dart';
import 'package:shimmer/shimmer.dart';
import '***REMOVED***/services/StoryService.dart';
import '***REMOVED***/models/ReportRequest_model.dart';
import '***REMOVED***/services/GenerateReportService.dart';
import '***REMOVED***/maintenance/expiredtoken.dart';

class FullScreenStoryView extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;
  final VoidCallback? onStoriesChanged;

  const FullScreenStoryView({required this.stories, required this.initialIndex,this.onStoriesChanged});

  @override
  _FullScreenStoryViewState createState() => _FullScreenStoryViewState();
}

class _FullScreenStoryViewState extends State<FullScreenStoryView>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentStoryIndex = 0;
  int _currentMediaIndex = 0;
  int? _loggedInUserId;
  bool _isPaused = false;
  bool _hasNavigatedToHomePage = false;
  int? _lastViewedStoryId;
  List<StoryViewer> viewersList = [];

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentStoryIndex);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );

    _fetchLoggedInUserId();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startStoryTimer();
      _viewStory(widget.stories[_currentStoryIndex].storyId);
    });

    _pageController.addListener(_handlePageChange);

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isPaused) {
        _nextMediaOrStory();
      }
    });
  }

  void _handlePageChange() {
    int pageIndex = _pageController.page?.round() ?? 0;
    if (pageIndex != _currentStoryIndex) {
      setState(() {
        _currentStoryIndex = pageIndex;
        _currentMediaIndex = 0;
        _resetStoryTimer();
        _startStoryTimer();
      });
      _viewStory(widget.stories[_currentStoryIndex].storyId);
    }
  }

  Future<void> _fetchLoggedInUserId() async {
    try {
      final userId = await LoginService().getUserId();
      setState(() {
        _loggedInUserId = userId;
      });
    } catch (e) {
      print('Failed to get logged in user ID: $e');
    }
  }

  Future<bool> _checkSession(BuildContext context) async {
    final userId = await LoginService().getUserId();
    if (userId == null) {
      handleSessionExpired(context);
      return false;
    }
    return true;
  }

  Future<void> _viewStory(int storyId) async {
    if (_loggedInUserId != null && storyId != _lastViewedStoryId) {
      StoryViewRequest request = StoryViewRequest(
        storyId: storyId,
        viewerId: _loggedInUserId!,
      );
      StoryViewResponse? response =
          await StoryServiceRequest().recordStoryView(request);

      if (response != null) {
        _lastViewedStoryId = storyId;
      } else {
        print("Failed to record story view.");
      }
    }
  }

Future<void> _fetchStoryViewers(int storyId) async {
  try {
    // Retrieve the paginated response
    final paginatedViewers = await StoryServiceRequest().getStoryViewers(storyId);

    if (paginatedViewers != null) {
      setState(() {
        // Extract the actual list of StoryViewer objects
        viewersList = paginatedViewers.data;
      });
    }
  } catch (e) {
    print('Failed to fetch story viewers: $e');
  }
}


  void _startStoryTimer() {
    _resetStoryTimer();
    if (!_isPaused) {
      _animationController.forward();
    }
  }

  void _resetStoryTimer() {
    _animationController.reset();
    _isPaused = false;
  }

  void _pauseStory() {
    setState(() {
      _isPaused = true;
      _animationController.stop();
    });
  }

  void _resumeStory() {
    setState(() {
      _isPaused = false;
      _animationController.forward(from: _animationController.value);
    });
  }

  void _nextMediaOrStory() async {
    if (_hasNavigatedToHomePage) return;
    if (!await _checkSession(context)) return;

    final currentStory = widget.stories[_currentStoryIndex];
    if (_currentMediaIndex < currentStory.media.length - 1) {
      setState(() {
        _currentMediaIndex++;
        _startStoryTimer();
      });
    } else {
      _nextStory();
    }
  }

  void _nextStory() async {
    if (_hasNavigatedToHomePage) return;
    if (!await _checkSession(context)) return;

    if (_currentStoryIndex < widget.stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
        _currentMediaIndex = 0;
        _startStoryTimer();
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _viewStory(widget.stories[_currentStoryIndex].storyId);
    } else {
      _hasNavigatedToHomePage = true;
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _previousMedia() async {
    if (!await _checkSession(context)) return;

    if (_currentMediaIndex > 0) {
      setState(() {
        _currentMediaIndex--;
        _startStoryTimer();
      });
    } else if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
        _currentMediaIndex = widget.stories[_currentStoryIndex].media.length - 1;
        _startStoryTimer();
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _viewStory(widget.stories[_currentStoryIndex].storyId);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showViewersBottomSheet() async {
    _pauseStory(); // pause while showing viewers
    await _fetchStoryViewers(widget.stories[_currentStoryIndex].storyId);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: 300,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Viewed by",
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: viewersList.isEmpty
                    ? const Center(
                        child: Text(
                          "No views",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: viewersList.length,
                        itemBuilder: (context, index) {
                          final viewer = viewersList[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(viewer.profilePic),
                              radius: 20,
                            ),
                            title: Text(
                              viewer.fullname,
                              style: const TextStyle(color: Colors.black, fontSize: 14),
                            ),
                            subtitle: Text(
                              _formatTime(viewer.localViewedAt),
                              style: const TextStyle(
                                color: Colors.deepOrange,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );

    _resumeStory(); // resume after closing
  }

void _deleteStory(int storyId) async {
  _pauseStory();

  bool confirmDelete = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 16,
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 5,
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.delete_outline,
                color: Color(0xFFD32F2F),
                size: 40,
              ),
              const SizedBox(height: 20),
              const Text(
                'Confirm Deletion',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B3F72),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Are you sure you want to delete this story media? '
                'This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      backgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      backgroundColor: Color(0xFFD32F2F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  // If user cancels deletion
  if (!confirmDelete) {
    _resumeStory();
    return;
  }

  // Session check
  if (!await _checkSession(context)) {
    _resumeStory();
    return;
  }

  try {
    final userId = _loggedInUserId;
    if (userId == null) {
      _showSnackbar("User not found or not logged in.");
      _resumeStory();
      return;
    }

    // Identify the current story & media we want to delete
    final currentStory = widget.stories[_currentStoryIndex];
    final mediaId = currentStory.media[_currentMediaIndex].mediaId;

    // Call the backend to delete this single media item
    bool isDeleted = await StoryService().deleteStoryMedia(mediaId, userId);

    if (isDeleted) {
      // Remove the single media from our local list
      setState(() {
        currentStory.media.removeAt(_currentMediaIndex);
      });

      // If the story now has zero media left, remove the entire story
    if (currentStory.media.isEmpty) {
      setState(() {
        widget.stories.removeAt(_currentStoryIndex);
      });

      // If we have zero stories left, go home
      if (widget.stories.isEmpty) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        widget.onStoriesChanged?.call(); // refresh the home list
        return;
      }

      // If not empty, we're still in this user's story list
      // but want to update the home list to remove the entire box
      widget.onStoriesChanged?.call();
    }

      // If we have no stories left, go home
      if (widget.stories.isEmpty) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }

      // Otherwise, if the current index is now out of bounds (e.g. last story was removed),
      // shift it to the last valid story
      if (_currentStoryIndex >= widget.stories.length) {
        _currentStoryIndex = widget.stories.length - 1;
      }

      // If the current story still has media but we removed the last media index, shift to the new last media
      if (currentStory.media.isNotEmpty &&
          _currentMediaIndex >= currentStory.media.length) {
        _currentMediaIndex = currentStory.media.length - 1;
      }

      // Reset the timer & jump to our updated story
      _pageController.jumpToPage(_currentStoryIndex);
      _viewStory(widget.stories[_currentStoryIndex].storyId);
      _startStoryTimer();
    } else {
      _showSnackbar("Failed to delete story media.");
    }
  } catch (e) {
    _showSnackbar("Error occurred while deleting story media: $e");
  }

  // Resume the story after all operations
  _resumeStory();
}

  void _submitReport(String reportReason, int reportedUserId, int contentId) async {
    if (!await _checkSession(context)) return;

    try {
      final userId = await LoginService().getUserId();
      if (userId == null) {
        _showSnackbar("You need to be logged in to report.");
        return;
      }

      final reportRequest = ReportRequest(
        reportedBy: userId,
        reportedUser: reportedUserId,
        contentType: 'Stories',
        contentId: contentId,
        reportReason: reportReason,
        resolutionDetails: '',
      );

      await ReportService().createReport(reportRequest);
      _showSnackbar("Report submitted successfully.");
    } catch (e) {
      _showSnackbar("Failed to submit report: $e");
    }
  }

  void _showReportOptions(int reportedUserId, int contentId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF4B3F72),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  'Report Story',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.flag, color: Color(0xFFD4AF37)),
                title: const Text(
                  'Spam',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  if (await _checkSession(context)) {
                    _submitReport('Spam', reportedUserId, contentId);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Color(0xFFD4AF37)),
                title: const Text(
                  'Inappropriate',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  if (await _checkSession(context)) {
                    _submitReport('Inappropriate', reportedUserId, contentId);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatTime(DateTime dateTime) {
    Duration difference = DateTime.now().difference(dateTime);
    if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }

  Widget _buildMedia(Story story, int mediaIndex) {
    final mediaItem = story.media[mediaIndex];
    return CachedNetworkImage(
      imageUrl: mediaItem.mediaUrl,
      imageBuilder: (context, imageProvider) => Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (context, url, error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.error, color: Colors.white),
            Text(
              'Failed to load media',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children:
          widget.stories[_currentStoryIndex].media.asMap().entries.map((entry) {
        int mediaIndex = entry.key;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: (mediaIndex < _currentMediaIndex)
                      ? 1.0
                      : (mediaIndex == _currentMediaIndex
                          ? _animationController.value
                          : 0.0),
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentStoryIndex];
    final isOwner = (story.userId == _loggedInUserId);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isLastStory = _currentStoryIndex == widget.stories.length - 1;
          final isLastMedia =
              _currentMediaIndex == widget.stories[_currentStoryIndex].media.length - 1;

          if (details.globalPosition.dx < screenWidth / 3) {
            _previousMedia();
          } else if (details.globalPosition.dx > 2 * screenWidth / 3) {
            // If last story & last media => exit
            if (isLastStory && isLastMedia) {
              _hasNavigatedToHomePage = true;
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else {
              _nextMediaOrStory();
            }
          }
        },
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.stories.length,
          itemBuilder: (context, index) {
            final story = widget.stories[index];

            return Stack(
              children: [
                _buildMedia(story, _currentMediaIndex),
                Positioned(
                  top: 40.0,
                  left: 10.0,
                  right: 10.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressIndicator(),
                      const SizedBox(height: 10.0),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(story.profilePicUrl),
                              radius: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {},
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  story.fullName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _formatTime(story.media[_currentMediaIndex].localCreatedAt),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (!isOwner)
                            IconButton(
                              icon: const Icon(Icons.more_vert, color: Colors.white),
                              onPressed: () =>
                                  _showReportOptions(story.userId, story.storyId),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  Positioned(
                    bottom: 100.0,
                    right: 20.0,
                    child: Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.white),
                          onPressed: () => _showViewersBottomSheet(),
                          tooltip: 'Viewers',
                        ),
                        const SizedBox(height: 15),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          onPressed: () =>
                              _deleteStory(widget.stories[_currentStoryIndex].storyId),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
