import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class VideoPost extends StatefulWidget {
  final String mediaUrl;

  const VideoPost({Key? key, required this.mediaUrl}) : super(key: key);

  @override
  _VideoPostState createState() => _VideoPostState();
}

class _VideoPostState extends State<VideoPost> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();  // Only call the caching-based initialization
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  // Method to initialize the video player with caching
  Future<void> _initializeVideo() async {
    try {
      // Fetch and cache the video file
      final file = await DefaultCacheManager().getSingleFile(widget.mediaUrl);
      
      // Initialize video player with the cached file
      _videoPlayerController = VideoPlayerController.file(file)
        ..initialize().then((_) {
          setState(() {});  // Update the UI when the video is ready
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController,
            aspectRatio: _videoPlayerController.value.aspectRatio,
            autoPlay: false,
            looping: true,
          );
        });
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  void _handleVisibility(double visibleFraction) {
    if (visibleFraction > 0.5 && !_isVisible) {
      _videoPlayerController.play();
      _isVisible = true;
    } else if (visibleFraction <= 0.5 && _isVisible) {
      _videoPlayerController.pause();
      _isVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.mediaUrl),
      onVisibilityChanged: (visibilityInfo) {
        _handleVisibility(visibilityInfo.visibleFraction);
      },
      child: _chewieController != null &&
              _chewieController!.videoPlayerController.value.isInitialized
          ? Chewie(controller: _chewieController!)
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
