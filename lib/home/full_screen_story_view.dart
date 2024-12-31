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

  const FullScreenStoryView({
    required this.stories,
    required this.initialIndex,
    this.onStoriesChanged,
  });

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

    /// Start the timer and record the first story view once the frame is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startStoryTimer();
      if (_currentStoryIndex < widget.stories.length) {
        _viewStory(widget.stories[_currentStoryIndex].storyId);
      }
    });

    /// Listen to the PageController for story swipes
    _pageController.addListener(_handlePageChange);

    /// When the 7-second timer ends (and isn't paused), go to next media or story
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isPaused) {
        _nextMediaOrStory();
      }
    });
  }

  void _handlePageChange() {
    final pageIndex = _pageController.page?.round() ?? 0;
    if (pageIndex != _currentStoryIndex) {
      setState(() {
        _currentStoryIndex = pageIndex;
        _currentMediaIndex = 0;
        _resetStoryTimer();
        _startStoryTimer();
      });
      if (_currentStoryIndex < widget.stories.length) {
        _viewStory(widget.stories[_currentStoryIndex].storyId);
      }
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
      final request = StoryViewRequest(storyId: storyId, viewerId: _loggedInUserId!);
      final response = await StoryServiceRequest().recordStoryView(request);

      if (response != null) {
        _lastViewedStoryId = storyId;
      } else {
        print("Failed to record story view.");
      }
    }
  }

  Future<void> _fetchStoryViewers(int storyId) async {
    try {
      final paginatedViewers =
          await StoryServiceRequest().getStoryViewers(storyId);
      if (paginatedViewers != null) {
        setState(() {
          viewersList = paginatedViewers.data;
        });
      }
    } catch (e) {
      print('Failed to fetch story viewers: $e');
    }
  }

  /// Timer (7s) for each media
  void _startStoryTimer() {
    _resetStoryTimer();
    if (!_isPaused) {
      _animationController.forward();
    }
  }

  /// Reset the timer to zero (and unpause if needed)
  void _resetStoryTimer() {
    _animationController.reset();
    _isPaused = false;
  }

  /// Called on long-press. Pauses the animation
  void _pauseStory() {
    setState(() {
      _isPaused = true;
      _animationController.stop();
    });
  }

  /// Resume from where we left off
  void _resumeStory() {
    setState(() {
      _isPaused = false;
      _animationController.forward(from: _animationController.value);
    });
  }

  /// Moves to next media in the same story, or if last media, to next story
  void _nextMediaOrStory() async {
    if (_hasNavigatedToHomePage) return;
    if (!await _checkSession(context)) return;

    // If user removed some stories in the background
    if (_currentStoryIndex >= widget.stories.length) {
      _navigateHome();
      return;
    }

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

  /// Moves to the next story after finishing the current story's last media
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
      if (_currentStoryIndex < widget.stories.length) {
        _viewStory(widget.stories[_currentStoryIndex].storyId);
      }
    } else {
      _navigateHome();
    }
  }

  /// Return to the first page in Navigator
  void _navigateHome() {
    if (!_hasNavigatedToHomePage) {
      _hasNavigatedToHomePage = true;
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  /// If tapped the left side, go to previous media (or previous story if this is the first media)
  void _previousMedia() async {
    if (!await _checkSession(context)) return;

    if (_currentStoryIndex >= widget.stories.length) {
      _navigateHome();
      return;
    }

    if (_currentMediaIndex > 0) {
      setState(() {
        _currentMediaIndex--;
        _startStoryTimer();
      });
    } else if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      if (_currentStoryIndex < widget.stories.length) {
        final newStory = widget.stories[_currentStoryIndex];
        _currentMediaIndex =
            newStory.media.isNotEmpty ? newStory.media.length - 1 : 0;
        _startStoryTimer();
        _pageController.previousPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _viewStory(newStory.storyId);
      } else {
        Navigator.of(context).pop();
      }
    } else {
      // first story => pop
      Navigator.of(context).pop();
    }
  }

  /// Show who viewed the current story
  Future<void> _showViewersBottomSheet() async {
    _pauseStory(); // pause while showing viewers
    if (_currentStoryIndex < widget.stories.length) {
      await _fetchStoryViewers(widget.stories[_currentStoryIndex].storyId);
    }

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

  /// Delete the current media from the story
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

    if (!confirmDelete) {
      _resumeStory();
      return;
    }

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

      // Safeguard in case stories were removed
      if (_currentStoryIndex >= widget.stories.length) {
        _navigateHome();
        return;
      }

      final currentStory = widget.stories[_currentStoryIndex];

      // Also check if mediaIndex is valid
      if (_currentMediaIndex >= currentStory.media.length) {
        _currentMediaIndex = currentStory.media.length - 1;
        if (_currentMediaIndex < 0) {
          // No media left
          widget.stories.removeAt(_currentStoryIndex);
          if (widget.stories.isEmpty) {
            _navigateHome();
            return;
          }
          if (_currentStoryIndex >= widget.stories.length) {
            _currentStoryIndex = widget.stories.length - 1;
          }
          _pageController.jumpToPage(_currentStoryIndex);
          _resumeStory();
          return;
        }
      }

      final mediaId = currentStory.media[_currentMediaIndex].mediaId;
      final isDeleted = await StoryService().deleteStoryMedia(mediaId, userId);

      if (isDeleted) {
        setState(() {
          currentStory.media.removeAt(_currentMediaIndex);
        });

        // If the story has zero media, remove the story entirely
        if (currentStory.media.isEmpty) {
          setState(() {
            widget.stories.removeAt(_currentStoryIndex);
          });
          widget.onStoriesChanged?.call();

          if (widget.stories.isEmpty) {
            _navigateHome();
            return;
          }
          if (_currentStoryIndex >= widget.stories.length) {
            _currentStoryIndex = widget.stories.length - 1;
          }
          _pageController.jumpToPage(_currentStoryIndex);
        } else {
          // If media index is now out of range
          if (_currentMediaIndex >= currentStory.media.length) {
            _currentMediaIndex = currentStory.media.length - 1;
          }
        }

        widget.onStoriesChanged?.call();
        if (_currentStoryIndex < widget.stories.length) {
          _viewStory(widget.stories[_currentStoryIndex].storyId);
        }

        _startStoryTimer();
      } else {
        _showSnackbar("Failed to delete story media.");
      }
    } catch (e) {
      _showSnackbar("Error occurred while deleting story media: $e");
    }

    _resumeStory();
  }

  /// Submit a report for the current story to your server
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
        contentType: 'stories',
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

  /// Let user pick a reason to report the story
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Format how long ago the user viewed a story
  String _formatTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }

  /// Show the story media. Using BoxFit.contain so the entire image can be viewed.
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
            fit: BoxFit.contain,
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
            Text('Failed to load media', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  /// The progress bars at the top (for each media item in a story)
  Widget _buildProgressIndicator() {
    final currentStory = widget.stories[_currentStoryIndex];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: currentStory.media.asMap().entries.map((entry) {
        final mediaIndex = entry.key;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                double value = 0.0;
                if (mediaIndex < _currentMediaIndex) {
                  value = 1.0; // fully loaded
                } else if (mediaIndex == _currentMediaIndex) {
                  value = _animationController.value;
                }
                return LinearProgressIndicator(
                  value: value,
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
    // If stories are empty or the index is invalid, exit to home
    if (_currentStoryIndex >= widget.stories.length) {
      if (!_hasNavigatedToHomePage) {
        _hasNavigatedToHomePage = true;
        Future.microtask(() {
          Navigator.of(context).popUntil((route) => route.isFirst);
        });
      }
      return Container(color: Colors.black);
    }

    final story = widget.stories[_currentStoryIndex];
    // Make sure our currentMediaIndex is valid
    if (_currentMediaIndex >= story.media.length) {
      _currentMediaIndex =
          story.media.isNotEmpty ? story.media.length - 1 : 0;
      if (_currentMediaIndex < 0) {
        // No media => remove story or pop
        widget.stories.removeAt(_currentStoryIndex);
        if (widget.stories.isEmpty) {
          if (!_hasNavigatedToHomePage) {
            _hasNavigatedToHomePage = true;
            Future.microtask(() {
              Navigator.of(context).popUntil((route) => route.isFirst);
            });
          }
          return Container(color: Colors.black);
        }
      }
    }

    final isOwner = (story.userId == _loggedInUserId);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isLastStory = _currentStoryIndex == widget.stories.length - 1;
          final isLastMedia =
              _currentMediaIndex ==
              widget.stories[_currentStoryIndex].media.length - 1;

          // Tap left side => previous media
          if (details.globalPosition.dx < screenWidth / 3) {
            _previousMedia();
          }
          // Tap right side => next media
          else if (details.globalPosition.dx > 2 * screenWidth / 3) {
            // If this is the last story & last media => go home
            if (isLastStory && isLastMedia) {
              _navigateHome();
            } else {
              _nextMediaOrStory();
            }
          }
        },
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),
        // Now we allow horizontal swipes to move between stories
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.stories.length,
          // We rely on the existing _handlePageChange to detect swipe
          itemBuilder: (context, index) {
            final current = widget.stories[index];
            return Stack(
              children: [
                if (_currentMediaIndex < current.media.length)
                  _buildMedia(current, _currentMediaIndex),
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
                          CircleAvatar(
                            backgroundImage: NetworkImage(current.profilePicUrl),
                            radius: 20,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                current.fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              if (_currentMediaIndex < current.media.length)
                                Text(
                                  _formatTime(
                                    current.media[_currentMediaIndex].localCreatedAt,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          if (!isOwner)
                            IconButton(
                              icon: const Icon(Icons.more_vert, color: Colors.white),
                              onPressed: () => _showReportOptions(
                                current.userId,
                                current.storyId,
                              ),
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
                          onPressed: _showViewersBottomSheet,
                          tooltip: 'Viewers',
                        ),
                        const SizedBox(height: 15),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          onPressed: () => _deleteStory(
                            widget.stories[_currentStoryIndex].storyId,
                          ),
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
