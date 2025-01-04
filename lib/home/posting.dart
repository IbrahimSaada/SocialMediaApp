// posting.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:myapp/services/s3_upload_service.dart';
import 'package:myapp/services/CreatePostService.dart';
import 'package:myapp/services/LoginService.dart';
import 'package:myapp/models/post_request.dart';
import 'package:myapp/models/presigned_url.dart';
import 'package:myapp/maintenance/expiredtoken.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  // Public or Private toggle
  bool isPublicSelected = true;

  // Uploading states
  bool _isUploading = false;
  double _uploadProgress = 0;

  // Media and caption
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  List<XFile> _mediaFiles = [];

  // Services
  final S3UploadService _s3UploadService = S3UploadService();
  final LoginService _loginService = LoginService();
  late final PostService _postService;

  // User info (fetched from LoginService)
  String? _userFullName;
  String? _profilePicUrl;

  // Colors, styling
  final Color primaryColor = const Color(0xFFF45F67);

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initializePostService();
    _fetchUserData(); // Get the user's full name and profile pic
  }

  // Fetch the user's full name and profile picture from secure storage
  Future<void> _fetchUserData() async {
    final userFullName = await _loginService.getFullname();
    final profilePic = await _loginService.getProfilePic();

    setState(() {
      _userFullName = userFullName;
      _profilePicUrl = profilePic;
    });
  }

  // Request necessary permissions
  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.photos,
      Permission.microphone,
    ].request();
  }

  // Initialize our PostService
  Future<void> _initializePostService() async {
    setState(() {
      _postService = PostService();
    });
  }

  // Pick images or videos from gallery
  Future<void> _pickMedia({bool isImage = true}) async {
    try {
      final List<XFile>? selectedFiles;

      if (isImage) {
        selectedFiles = await _picker.pickMultiImage(
          imageQuality: 85,
          maxHeight: 800,
          maxWidth: 800,
        );
      } else {
        final XFile? videoFile = await _picker.pickVideo(
          source: ImageSource.gallery,
        );
        if (videoFile != null) {
          selectedFiles = [videoFile];
        } else {
          selectedFiles = null;
        }
      }

      if (selectedFiles != null && selectedFiles.isNotEmpty) {
        setState(() {
          _mediaFiles.addAll(selectedFiles!);
          // Limit to 10 files max
          if (_mediaFiles.length > 10) {
            _mediaFiles = _mediaFiles.sublist(0, 10);
          }
        });
      }
    } catch (e) {
      print('Error picking media: $e');
    }
  }

  // Capture photo or video from camera
  Future<void> _pickCameraMedia({bool isImage = true}) async {
    try {
      XFile? file;

      if (isImage) {
        file = await _picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
        );
      } else {
        file = await _picker.pickVideo(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
        );
      }

      if (file != null) {
        setState(() {
          _mediaFiles.add(file!);
          // Limit to 10 files max
          if (_mediaFiles.length > 10) {
            _mediaFiles = _mediaFiles.sublist(0, 10);
          }
        });
      }
    } catch (e) {
      print('Error capturing media: $e');
    }
  }

  // Create the post
  Future<void> _post() async {
    // Validate: caption or media must be present
    if (_captionController.text.isEmpty && _mediaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a caption or media.')),
      );
      return;
    }

    // Validate: if media is present, must have a caption
    if (_mediaFiles.isNotEmpty && _captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media cannot be posted without a caption.')),
      );
      return;
    }

    // If already uploading, do not proceed
    if (_isUploading) {
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final int? userId = await _loginService.getUserId();
      if (userId == null) {
        // If no user, handle session expired
        handleSessionExpired(context);
        return;
      }

      List<Media> uploadedMedia = [];

      // If user attached any media files, we upload them to S3
      if (_mediaFiles.isNotEmpty) {
        List<String> fileNames = _mediaFiles.map((file) => file.name).toList();
        List<PresignedUrl> presignedUrls =
            await _s3UploadService.getPresignedUrls(fileNames);

        for (int i = 0; i < _mediaFiles.length; i++) {
          String objectUrl =
              await _s3UploadService.uploadFile(presignedUrls[i], _mediaFiles[i]);

          // Update progress
          setState(() {
            _uploadProgress = (i + 1) / _mediaFiles.length;
          });

          String mediaType =
              _mediaFiles[i].path.endsWith('.mp4') ? 'video' : 'photo';

          uploadedMedia.add(Media(mediaUrl: objectUrl, mediaType: mediaType));
        }
      }

      // Build request body
      PostRequest postRequest = PostRequest(
        userId: userId,
        caption: _captionController.text,
        isPublic: isPublicSelected,
        media: uploadedMedia,
      );

      // Send to API
      await _postService.createPost(postRequest);

      // Once posted, go back and signal that home should refresh
      Navigator.pop(context, true);
    } catch (e) {
      print('Error creating post: $e');
      // If token refresh fails
      if (e.toString().contains('Failed to refresh token')) {
        handleSessionExpired(context);
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Open media in full screen viewer
  void _openFullScreenViewer(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenViewer(
          mediaFiles: _mediaFiles,
          initialIndex: initialIndex,
          onDelete: (index) {
            setState(() {
              _mediaFiles.removeAt(index);
            });
          },
        ),
      ),
    );
  }

  // Camera options: photo or video
  void _showCameraOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera, color: primaryColor),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickCameraMedia(isImage: true);
              },
            ),
            ListTile(
              leading: Icon(Icons.videocam, color: primaryColor),
              title: const Text('Record Video'),
              onTap: () {
                Navigator.pop(context);
                _pickCameraMedia(isImage: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Media options: select from gallery
  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo, color: primaryColor),
              title: const Text('Select Photos'),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(isImage: true);
              },
            ),
            ListTile(
              leading: Icon(Icons.videocam, color: primaryColor),
              title: const Text('Select Videos'),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(isImage: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.close, color: primaryColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Create Post',
          style: TextStyle(color: primaryColor, fontSize: 22),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _post,
            child: Text(
              'Post',
              style: TextStyle(
                color: _isUploading ? Colors.grey : primaryColor,
                fontSize: 22,
              ),
            ),
          ),
        ],
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () {
          // Close the keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          fit: StackFit.loose,
          children: [
            Column(
              children: [
                // User info + toggle
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                    leading: CircleAvatar(
                      backgroundImage: (_profilePicUrl != null &&
                              _profilePicUrl!.isNotEmpty)
                          ? NetworkImage(_profilePicUrl!)
                          : const AssetImage('assets/chef.jpg')
                              as ImageProvider,
                      radius: 24,
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Single line, no '...' for very long names
                        Expanded(
                          child: Text(
                            _userFullName ?? 'User',
                            style: const TextStyle(
                              fontSize: 20,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            softWrap: false,
                          ),
                        ),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  isPublicSelected = true;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                backgroundColor:
                                    isPublicSelected ? primaryColor : Colors.white,
                                foregroundColor:
                                    isPublicSelected ? Colors.white : Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color:
                                        isPublicSelected ? primaryColor : Colors.black,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: const Text('Public', style: TextStyle(fontSize: 16)),
                            ),
                            const SizedBox(width: 5),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  isPublicSelected = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                backgroundColor:
                                    !isPublicSelected ? primaryColor : Colors.white,
                                foregroundColor:
                                    !isPublicSelected ? Colors.white : Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: !isPublicSelected
                                        ? primaryColor
                                        : Colors.black,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child:
                                  const Text('Private', style: TextStyle(fontSize: 16)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Caption text field
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: primaryColor, width: 3),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _captionController,
                        decoration: const InputDecoration(
                          hintText: "What's on your mind?",
                          hintStyle: TextStyle(fontSize: 22, color: Colors.grey),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 22, color: Colors.black),
                        maxLines: null,
                        expands: true,
                      ),
                    ),
                  ),
                ),

                // Thumbnails for selected media
                if (_mediaFiles.isNotEmpty)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 4.0,
                          crossAxisSpacing: 4.0,
                          childAspectRatio: 1,
                        ),
                        itemCount: _mediaFiles.length > 5 ? 5 : _mediaFiles.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _openFullScreenViewer(index),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: _mediaFiles[index].path.endsWith('.mp4')
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              // Dark overlay
                                              Container(
                                                color: Colors.black.withOpacity(0.5),
                                              ),
                                              const Center(
                                                child: Icon(
                                                  Icons.play_circle_outline,
                                                  color: Colors.white,
                                                  size: 50,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Image.file(
                                          File(_mediaFiles[index].path),
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                // If more than 5, show +X
                                if (_mediaFiles.length > 5 && index == 4)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black54,
                                      child: Center(
                                        child: Text(
                                          '+${_mediaFiles.length - 5}',
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 24),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Bottom UI (buttons for media/camera) when keyboard NOT visible
                if (!keyboardVisible)
                  SizedBox(
                    height: screenHeight * 0.2,
                    child: Card(
                      color: Colors.white,
                      margin: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              Future.delayed(const Duration(milliseconds: 300), () {
                                _showMediaOptions();
                              });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.photo, color: primaryColor, size: 36),
                                const SizedBox(width: 8),
                                const Text('Image/Video',
                                    style: TextStyle(fontSize: 22)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _showCameraOptions,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, color: primaryColor, size: 36),
                                const SizedBox(width: 8),
                                const Text('Camera', style: TextStyle(fontSize: 22)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bottom UI when keyboard IS visible (just the gallery option)
                if (keyboardVisible)
                  SizedBox(
                    height: screenHeight * 0.1,
                    child: Card(
                      color: Colors.white,
                      margin: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              Future.delayed(const Duration(milliseconds: 300), () {
                                _showMediaOptions();
                              });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.photo, color: primaryColor, size: 36),
                                const SizedBox(width: 8),
                                const Text('Image/Video',
                                    style: TextStyle(fontSize: 22)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Upload progress indicator
            if (_isUploading)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: _uploadProgress,
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                            strokeWidth: 8,
                          ),
                        ),
                        Text(
                          '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Mini media buttons over the keyboard
            if (keyboardVisible)
              Positioned(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          Future.delayed(const Duration(milliseconds: 300), () {
                            _showMediaOptions();
                          });
                        },
                        child: Icon(Icons.photo, color: primaryColor, size: 36),
                      ),
                      GestureDetector(
                        onTap: _showCameraOptions,
                        child: Icon(Icons.camera_alt, color: primaryColor, size: 36),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Full screen viewer for images/videos
class FullScreenViewer extends StatefulWidget {
  final List<XFile> mediaFiles;
  final int initialIndex;
  final Function(int) onDelete;

  const FullScreenViewer({
    super.key,
    required this.mediaFiles,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  _FullScreenViewerState createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<FullScreenViewer> {
  late int currentIndex;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  final Color primaryColor = const Color(0xFFF45F67);

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _initializeVideoPlayer();
  }

  // Initialize video player if it's a .mp4 file
  void _initializeVideoPlayer() {
    if (widget.mediaFiles[currentIndex].path.endsWith('.mp4')) {
      _videoPlayerController = VideoPlayerController.file(
        File(widget.mediaFiles[currentIndex].path),
      );
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
      );
      _videoPlayerController!.initialize().then((_) {
        setState(() {});
      });
    } else {
      _videoPlayerController?.dispose();
      _chewieController?.dispose();
      _videoPlayerController = null;
      _chewieController = null;
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  // Delete current media item
  void _deleteCurrentMedia() {
    widget.onDelete(currentIndex);
    if (widget.mediaFiles.length > 1) {
      setState(() {
        if (currentIndex > 0) {
          currentIndex--;
        } else {
          currentIndex = 0;
        }
        _initializeVideoPlayer();
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          iconSize: 36.0,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            iconSize: 36.0,
            onPressed: _deleteCurrentMedia,
          ),
        ],
      ),
      body: Center(
        child: PageView.builder(
          itemCount: widget.mediaFiles.length,
          controller: PageController(initialPage: currentIndex),
          onPageChanged: (index) {
            setState(() {
              currentIndex = index;
              _initializeVideoPlayer();
            });
          },
          itemBuilder: (context, index) {
            // If it's a video
            if (widget.mediaFiles[index].path.endsWith('.mp4')) {
              return _chewieController != null
                  ? Chewie(controller: _chewieController!)
                  : const Center(child: CircularProgressIndicator());
            } else {
              // Otherwise, it's an image
              return Image.file(
                File(widget.mediaFiles[index].path),
                fit: BoxFit.contain,
              );
            }
          },
        ),
      ),
    );
  }
}
