// widgets/video_post.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:visibility_detector/visibility_detector.dart';

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
    _videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl))
          ..initialize().then((_) {
            setState(() {});
            _chewieController = ChewieController(
              videoPlayerController: _videoPlayerController,
              aspectRatio: _videoPlayerController.value.aspectRatio,
              autoPlay: false,
              looping: true,
            );
          });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
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
