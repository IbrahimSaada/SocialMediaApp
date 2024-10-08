import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';
import '***REMOVED***/services/s3_upload_service.dart';
import '***REMOVED***/services/CreatePostService.dart';
import '***REMOVED***/services/LoginService.dart';
import '***REMOVED***/models/post_request.dart';
import '***REMOVED***/models/presigned_url.dart';
import '***REMOVED***/maintenance/expiredtoken.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  bool isPublicSelected = true;
  bool _isUploading = false;
  double _uploadProgress = 0;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  List<XFile> _mediaFiles = [];
  final S3UploadService _s3UploadService = S3UploadService();
  final LoginService _loginService = LoginService();
  late final PostService _postService;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initializePostService();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.photos,
      Permission.microphone,
    ].request();
  }

  Future<void> _initializePostService() async {
    // The _postService initialization has been simplified since we no longer need token handling
    setState(() {
      _postService = PostService();
    });
  }

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
          if (_mediaFiles.length > 10) {
            _mediaFiles = _mediaFiles.sublist(0, 10);
          }
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error picking media: $e');
    }
  }

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
          if (_mediaFiles.length > 10) {
            _mediaFiles = _mediaFiles.sublist(0, 10);
          }
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error capturing media: $e');
    }
  }

  Future<void> _post() async {
    // Check if both media and caption are empty
    if (_captionController.text.isEmpty && _mediaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a caption or media.')),
      );
      return;
    }

    // Check if media is uploaded without a caption
    if (_mediaFiles.isNotEmpty && _captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media cannot be posted without a caption.')),
      );
      return;
    }

    if (_isUploading) {
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

  try {
    // Fetch the user ID, no token handling required
    final int? userId = await _loginService.getUserId();
    if (userId == null) {
      // ignore: use_build_context_synchronously
      handleSessionExpired(context);  // Use the session expired handler here
      return;
    }

      List<Media> uploadedMedia = [];

      // Only call S3 if there are media files
      if (_mediaFiles.isNotEmpty) {
        List<String> fileNames = _mediaFiles.map((file) => file.name).toList();
        List<PresignedUrl> presignedUrls =
            await _s3UploadService.getPresignedUrls(fileNames);

        for (int i = 0; i < _mediaFiles.length; i++) {
          String objectUrl = await _s3UploadService.uploadFile(presignedUrls[i], _mediaFiles[i]);

          setState(() {
            _uploadProgress = (i + 1) / _mediaFiles.length;
          });

          String mediaType =
              _mediaFiles[i].path.endsWith('.mp4') ? 'video' : 'photo';

          uploadedMedia.add(Media(mediaUrl: objectUrl, mediaType: mediaType));
        }
      }

      // Create post request with or without media
      PostRequest postRequest = PostRequest(
        userId: userId,
        caption: _captionController.text,
        isPublic: isPublicSelected,
        media: uploadedMedia,  // Can be empty if no media
      );

      await _postService.createPost(postRequest);

      setState(() {
        _mediaFiles.clear();
      });

      // Navigate back to HomePage after post completion
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
  } catch (e) {
    // ignore: avoid_print
    print('Error creating post: $e');
    if (e.toString().contains('Failed to refresh token')) {
      // ignore: use_build_context_synchronously
      handleSessionExpired(context);  // Use the session expired handler here
    }
  } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

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

  void _showCameraOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickCameraMedia(isImage: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
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

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Select Photos'),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(isImage: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
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
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Create Post',
            style: TextStyle(color: Color(0xFFF45F67), fontSize: 22)),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _post,
            child: Text(
              'Post',
              style: TextStyle(
                color: _isUploading ? Colors.grey : Color(0xFFF45F67),
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          fit: StackFit.loose,
          children: [
            Column(
              children: [
                Container(
                  height: screenHeight * 0.1,
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                        leading: const CircleAvatar(
                          backgroundImage: AssetImage('assets/chef.jpg'),
                          radius: 24,
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Flexible(
                              child: Text(
                                'users',
                                style: TextStyle(fontSize: 20),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      isPublicSelected = true;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 8),
                                    backgroundColor: isPublicSelected
                                        ? Color(0xFFF45F67)
                                        : Colors.white,
                                    foregroundColor: isPublicSelected
                                        ? Colors.white
                                        : Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: isPublicSelected
                                            ? Color(0xFFF45F67)
                                            : Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: const Text('Public',
                                      style: TextStyle(fontSize: 16)),
                                ),
                                const SizedBox(width: 5),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      isPublicSelected = false;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 8),
                                    backgroundColor: !isPublicSelected
                                        ? Color(0xFFF45F67)
                                        : Colors.white,
                                    foregroundColor: !isPublicSelected
                                        ? Colors.white
                                        : Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: !isPublicSelected
                                            ? Color(0xFFF45F67)
                                            : Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: const Text('Private',
                                      style: TextStyle(fontSize: 16)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFFF45F67), width: 3),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _captionController,
                        decoration: const InputDecoration(
                          hintText: "What's on your mind?",
                          hintStyle:
                              TextStyle(fontSize: 22, color: Colors.grey),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 22, color: Colors.black),
                        maxLines: null,
                        expands: true,
                      ),
                    ),
                  ),
                ),
                if (_mediaFiles.isNotEmpty)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 4.0,
                          crossAxisSpacing: 4.0,
                          childAspectRatio: 1,
                        ),
                        itemCount:
                            _mediaFiles.length > 5 ? 5 : _mediaFiles.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _openFullScreenViewer(index),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child:
                                      _mediaFiles[index].path.endsWith('.mp4')
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  Container(
                                                    color: Colors.black
                                                        .withOpacity(0.5),
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
                                if (_mediaFiles.length > 5 && index == 4)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black54,
                                      child: Center(
                                        child: Text(
                                          '+${_mediaFiles.length - 5}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24),
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
                if (!keyboardVisible)
                  SizedBox(
                    height: screenHeight * 0.32,
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
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.photo, color: Colors.red, size: 36),
                                SizedBox(width: 8),
                                Text('Image/Video',
                                    style: TextStyle(fontSize: 22)),
                              ],
                            ),
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add,
                                  color: Colors.yellow, size: 36),
                              SizedBox(width: 8),
                              Text('Tag People',
                                  style: TextStyle(fontSize: 22)),
                            ],
                          ),
                          GestureDetector(
                            onTap: _showCameraOptions,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt,
                                    color: Colors.blue, size: 36),
                                SizedBox(width: 8),
                                Text('Camera', style: TextStyle(fontSize: 22)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (keyboardVisible)
                  SizedBox(
                    height: screenHeight * 0.15,
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
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.photo, color: Colors.red, size: 36),
                                SizedBox(width: 8),
                                Text('Image/Video',
                                    style: TextStyle(fontSize: 22)),
                              ],
                            ),
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add,
                                  color: Colors.yellow, size: 36),
                              SizedBox(width: 8),
                              Text('Tag People',
                                  style: TextStyle(fontSize: 22)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
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
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(Color(0xFFF45F67)),
                            strokeWidth: 8,
                          ),
                        ),
                        Text(
                          '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Color(0xFFF45F67),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
                        child: const Icon(Icons.photo, color: Colors.red, size: 36),
                      ),
                      const Icon(Icons.person_add, color: Colors.yellow, size: 36),
                      GestureDetector(
                        onTap: _showCameraOptions,
                        child: const Icon(Icons.camera_alt,
                            color: Colors.blue, size: 36),
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

class FullScreenViewer extends StatefulWidget {
  final List<XFile> mediaFiles;
  final int initialIndex;
  final Function(int) onDelete;

  const FullScreenViewer({super.key, 
    required this.mediaFiles,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  // ignore: library_private_types_in_public_api
  _FullScreenViewerState createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<FullScreenViewer> {
  late int currentIndex;
  late VideoPlayerController? _videoPlayerController;
  late ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _initializeVideoPlayer();
  }

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
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _deleteCurrentMedia() {
    widget.onDelete(currentIndex);
    if (widget.mediaFiles.length > 1) {
      setState(() {
        currentIndex = (currentIndex > 0) ? currentIndex - 1 : 0;
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
            if (widget.mediaFiles[index].path.endsWith('.mp4')) {
              return Chewie(controller: _chewieController!);
            } else {
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
