import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '***REMOVED***/models/storyview_response_model.dart';
//import 'package:timeago/timeago.dart' as timeago;
import '***REMOVED***/models/story_model.dart';
import '***REMOVED***/services/LoginService.dart';
import '***REMOVED***/models/storyview_request_model.dart';
import '***REMOVED***/services/storyview_Service.dart';
import 'package:shimmer/shimmer.dart'; // Import shimmer effect for visual appeal
import '***REMOVED***/services/StoryService.dart';
import '***REMOVED***/models/ReportRequest_model.dart';
import '***REMOVED***/services/GenerateReportService.dart';
import '***REMOVED***/maintenance/expiredtoken.dart';

class FullScreenStoryView extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;

  FullScreenStoryView({required this.stories, required this.initialIndex});

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
  bool _isViewersListVisible = false; // To manage visibility of the viewers list

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentStoryIndex);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 7),
    );

    _fetchLoggedInUserId();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startStoryTimer();
      _viewStory(widget.stories[_currentStoryIndex].storyId); // View the initial story
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
        _resetStoryTimer(); // Reset story timer for each new story
        _startStoryTimer(); // Automatically start the timer
      });
      _viewStory(widget.stories[_currentStoryIndex].storyId);
    }
  }
void _submitReport(String reportReason, int reportedUserId, int contentId) async {
  if (!await _checkSession(context)) return; // Check session before proceeding

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



Future<bool> _checkSession(BuildContext context) async {
  final userId = await LoginService().getUserId();
  if (userId == null) {
    handleSessionExpired(context); // Show session expired dialog
    return false; // Return false if the session is expired
  }
  return true; // Return true if the session is still valid
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
        print(response.message); // Handle the response message, if needed
        _lastViewedStoryId = storyId; // Update the last viewed story ID

        // If the logged-in user is the story owner, fetch the viewers
        if (widget.stories[_currentStoryIndex].userId == _loggedInUserId) {
          await _fetchStoryViewers(storyId);
        }
      } else {
        print("Failed to record story view.");
      }
    }
  }

  Future<void> _fetchStoryViewers(int storyId) async {
    try {
      List<StoryViewer>? viewers =
          await StoryServiceRequest().getStoryViewers(storyId);

      if (viewers != null) {
        setState(() {
          viewersList = viewers;
        });
      }
    } catch (e) {
      print('Failed to fetch story viewers: $e');
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

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startStoryTimer() {
    _resetStoryTimer(); // Ensure the timer is reset before starting
    if (!_isPaused) {
      _animationController.forward(); // Automatically start the story
    }
  }

  void _resetStoryTimer() {
    _animationController.reset(); // Reset the animation controller
    _isPaused = false; // Ensure paused state is reset
  }

  void _nextMediaOrStory() async {
  if (_hasNavigatedToHomePage) return;

  // Check if the session is still valid
  if (!await _checkSession(context)) return;

  final currentStory = widget.stories[_currentStoryIndex];
  if (_currentMediaIndex < currentStory.media.length - 1) {
    setState(() {
      _currentMediaIndex++;
      _startStoryTimer(); // Automatically start the timer for the new media
    });
  } else {
    _nextStory(); // Navigate to the next story
  }
}


  void _nextStory() async {
  if (_hasNavigatedToHomePage) return;

  // Hide viewers list when navigating to the next story
  setState(() {
    _isViewersListVisible = false; // Reset viewers list visibility
  });

  // Check if the session is still valid
  if (!await _checkSession(context)) return;

  if (_currentStoryIndex < widget.stories.length - 1) {
    setState(() {
      _currentStoryIndex++;
      _currentMediaIndex = 0;
      _startStoryTimer(); // Automatically start the timer for the new story
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    _viewStory(widget.stories[_currentStoryIndex].storyId); // Log the story view
  } else {
    _hasNavigatedToHomePage = true;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}


  void _previousMedia() async {
  // Check if the session is still valid
  if (!await _checkSession(context)) return;

  if (_currentMediaIndex > 0) {
    setState(() {
      _currentMediaIndex--;
      _startStoryTimer(); // Automatically start the timer for the previous media
    });
  } else if (_currentStoryIndex > 0) {
    setState(() {
      _currentStoryIndex--;
      _currentMediaIndex = widget.stories[_currentStoryIndex].media.length - 1;
      _startStoryTimer(); // Automatically start the timer for the previous story
    });
    _pageController.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  } else {
    Navigator.of(context).pop();
  }
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

  void _toggleViewersList() async {
  if (!await _checkSession(context)) return; // Check session before proceeding
  
  setState(() {
    _isViewersListVisible = !_isViewersListVisible;
    if (_isViewersListVisible) {
      _pauseStory(); // Pause the story when showing the viewers list
    } else {
      _startStoryTimer(); // Automatically start the timer when closing the viewers list
    }
  });

  // Fetch viewers immediately when the list is visible and hasn't been loaded yet
  if (_isViewersListVisible && viewersList.isEmpty) {
    await _fetchStoryViewers(widget.stories[_currentStoryIndex].storyId);
  }
}


void _deleteStory(int storyId) async {
  if (!await _checkSession(context)) return; // Check session before proceeding
  
  try {
    final mediaId = widget.stories[_currentStoryIndex].media[_currentMediaIndex].mediaId;
    final userId = _loggedInUserId;

    if (userId != null) {
      bool isDeleted = await StoryService().deleteStoryMedia(mediaId, userId);

      if (isDeleted) {
        setState(() {
          widget.stories.removeWhere((story) => story.storyId == storyId);
        });

        if (widget.stories.isEmpty) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          _nextStory();
        }
      } else {
        _showSnackbar("Failed to delete story.");
      }
    }
  } catch (e) {
    _showSnackbar("Error occurred while deleting story: $e");
  }
}


 void _showReportOptions(int reportedUserId, int contentId) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Color(0xFF4B3F72), // Set background color
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.0),
            topRight: Radius.circular(25.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, -5), // Shadow for the box
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
                margin: EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFD4AF37), // Bronze color for the divider
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Text(
                'Report Story',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Text color
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.flag, color: Color(0xFFD4AF37)), // Bronze icon
              title: Text(
                'Spam',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                _submitReport('Spam', reportedUserId, contentId); // Submit the report for 'Spam'
              },
            ),
            ListTile(
              leading: Icon(Icons.block, color: Color(0xFFD4AF37)),
              title: Text(
                'Inappropriate',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                _submitReport('Inappropriate', reportedUserId, contentId); // Submit for 'Inappropriate'
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

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.white,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 10,
                  color: Colors.grey,
                ),
                SizedBox(height: 5),
                Container(
                  width: 50,
                  height: 10,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewersListBox(List<StoryViewer> viewers) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        height: _isViewersListVisible
            ? 300
            : 0, // Show viewers list if visible, increased height
        decoration: BoxDecoration(
          color: Colors.white, // Set background color to white
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
            ),
          ],
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Viewed by",
              style: TextStyle(
                color: Colors.deepOrange, // Reddish orangey color
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: viewers.isEmpty
                  ? ListView.builder(
                      itemCount: 5, // Example placeholder count
                      itemBuilder: (context, index) =>
                          _buildShimmerPlaceholder(),
                    )
                  : ListView.builder(
                      itemCount: viewers.length,
                      itemBuilder: (context, index) {
                        final viewer = viewers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(viewer.profilePic),
                            radius: 20,
                          ),
                          title: Text(
                            viewer.fullname,
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                          subtitle: Text(
                          _formatTime(viewer.localViewedAt), // Real-time, short format time
                            style: TextStyle(
                                color: Colors.deepOrange, fontSize: 12),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
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
      placeholder: (context, url) => Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (context, url, error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;

          final isLastStory = _currentStoryIndex == widget.stories.length - 1;
          final isLastMedia = _currentMediaIndex ==
              widget.stories[_currentStoryIndex].media.length - 1;

          // Navigate to previous media/story if tap is on the left 33% of the screen
          if (details.globalPosition.dx < screenWidth / 3) {
            _previousMedia();
          }
          // Navigate to next media/story if tap is on the right 33% of the screen
          else if (details.globalPosition.dx > 2 * screenWidth / 3) {
            if (isLastStory && isLastMedia) {
              _hasNavigatedToHomePage = true;
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else {
              _nextMediaOrStory();
            }
          }
        },
        onLongPressStart: (_) => _pauseStory(), // Pause story on long press anywhere
        onLongPressEnd: (_) => _resumeStory(), // Resume story on release
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.stories.length,
          itemBuilder: (context, index) {
            final story = widget.stories[index];

            // Hide viewers list if the story is not the user's
            if (story.userId != _loggedInUserId) {
              _isViewersListVisible = false;
            }

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
                      SizedBox(height: 10.0),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              // Do nothing on tap (prevent next/previous navigation)
                            },
                            child: CircleAvatar(
                              backgroundImage:
                                  NetworkImage(story.profilePicUrl),
                              radius: 20,
                            ),
                          ),
                          SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              // Do nothing on tap (prevent next/previous navigation)
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  story.fullName,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  _formatTime(story.media[_currentMediaIndex].localCreatedAt),
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Spacer(),
                          if (story.userId == _loggedInUserId) ...[
                            ElevatedButton(
                              onPressed: _toggleViewersList, // Viewers list toggle
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange, // Reddish orangey button color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16), // Smaller size
                              ),
                              child: Text(
                                'View',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14, // Smaller font size for button
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () => _deleteStory(widget.stories[index].storyId), // Delete action
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                              ),
                              child: Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ] else ...[
IconButton(
  icon: Icon(Icons.more_vert, color: Colors.white),
  onPressed: () => _showReportOptions(story.userId, story.storyId), // Pass the IDs
),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (_isViewersListVisible)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildViewersListBox(viewersList),
                  ), // Show viewers list if visible
              ],
            );
          },
        ),
      ),
    );
  }
}
