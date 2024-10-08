// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:cook/models/story_model.dart' as story_model;
import 'package:cook/services/s3_upload_service.dart';
import 'package:cook/models/presigned_url.dart';
import 'package:cook/services/StoryService.dart';
import 'package:cook/services/LoginService.dart';
import 'package:cook/models/story_request_model.dart';
import 'package:cook/maintenance/expiredtoken.dart';

class StoryBox extends StatefulWidget {
  final Function(List<story_model.Story>) onStoriesUpdated;

  const StoryBox({super.key, required this.onStoriesUpdated});

  @override
  _StoryBoxState createState() => _StoryBoxState();
}

class _StoryBoxState extends State<StoryBox> {
  late final ImagePicker _picker;
  final int _maxMediaCount = 10;
  final List<String> _mediaPaths = [];
  final List<String> _mimeTypes = [];

  @override
  void initState() {
    super.initState();
    _picker = ImagePicker();
  }

  void _showOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickCameraMedia();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.0),
                      border: Border.all(color: const Color(0xFFF45F67), width: 2),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF45F67),
                          Color(0xFFF45F67),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 3,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 30),
                        ),
                        Text(
                          'Take Photo',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickMedia();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.0),
                      border: Border.all(color: const Color(0xFFF45F67), width: 2),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF45F67),
                          Color(0xFFF45F67),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 3,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Icon(Icons.photo_library, color: Colors.white, size: 30),
                        ),
                        Text(
                          'Gallery (Images)',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickCameraMedia() async {
    try {
      XFile? file = await _picker.pickImage(source: ImageSource.camera);
      if (file != null) {
        _handlePickedFiles([file.path]);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture media: $e')),
      );
    }
  }

  Future<void> _pickMedia() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        if (result.files.length > _maxMediaCount) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can select a maximum of 10 media files.')),
          );
        } else {
          _handlePickedFiles(result.paths.whereType<String>().toList());
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick media: $e')),
      );
    }
  }

  void _handlePickedFiles(List<String> filePaths) {
    _mediaPaths.clear();
    _mimeTypes.clear();

    for (var filePath in filePaths) {
      String mimeType = lookupMimeType(filePath) ?? '';

      if (_isValidMimeType(mimeType)) {
        _mediaPaths.add(filePath);
        _mimeTypes.add(mimeType);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unsupported file type: $mimeType')),
        );
      }
    }

    if (_mediaPaths.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MediaPreviewScreen(
            filePaths: _mediaPaths,
            mimeTypes: _mimeTypes,
            onSendToStory: _sendToStory,
          ),
        ),
      );
    }
  }

  Future<void> _sendToStory(List<String> mediaPaths) async {
    S3UploadService s3UploadService = S3UploadService();
    StoryService storyService = StoryService();

    List<String> fileNames = mediaPaths.map((path) => path.split('/').last).toList();

    try {
      int userId = await LoginService().getUserId() ?? 0;

      List<PresignedUrl> presignedUrls = await s3UploadService.getPresignedUrls(fileNames, folderName: 'stories');

      List<MediaRequest> mediaItems = [];
      for (int i = 0; i < presignedUrls.length; i++) {
        String uploadedUrl = await s3UploadService.uploadFile(
          presignedUrls[i], XFile(mediaPaths[i])
        );

        mediaItems.add(
          MediaRequest(
            mediaUrl: uploadedUrl,
            mediaType: 'photo',
          ),
        );
      }

      StoryRequest storyRequest = StoryRequest(userId: userId, media: mediaItems);
      await storyService.createStory(storyRequest);

      List<story_model.Story> updatedStories = await storyService.fetchStories(userId);
      widget.onStoriesUpdated(updatedStories);

      Navigator.pop(context);
    } catch (e) {
      if (e.toString().contains('Session expired')) {
        Future.microtask(() => handleSessionExpired(context));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create story: $e')),
        );
      }
    }
  }

  bool _isValidMimeType(String mimeType) {
    return mimeType.startsWith('image/');
  }

@override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () {
      _showOptionsDialog(context);
    },
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF45F67), // Main color gradient start
            Color(0xFFF45F67), // Main color gradient end
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFF45F67), width: 2), // Border color update
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: Colors.white,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFFF45F67), // Circle color for the + icon
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    ),
  );
}
}

// MediaPreviewScreen after modification

class MediaPreviewScreen extends StatefulWidget {
  final List<String> filePaths;
  final List<String> mimeTypes;
  final Function(List<String>) onSendToStory;

  const MediaPreviewScreen({
    super.key,
    required this.filePaths,
    required this.mimeTypes,
    required this.onSendToStory,
  });

  @override
  _MediaPreviewScreenState createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  bool _isSending = false; // To prevent multiple sends

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Media'),
        actions: [
          TextButton(
  onPressed: _isSending ? null : () async {
    setState(() {
      _isSending = true;
    });

    // Perform session check before sending the story
    if (!await _checkSession(context)) {
      setState(() {
        _isSending = false; // Re-enable button if session expired
      });
      return;
    }

    await widget.onSendToStory(widget.filePaths); // Send media if session is valid

    Navigator.of(context).popUntil((route) => route.isFirst);
  },
  child: Text(
    _isSending ? 'CREATING...' : 'CREATE',
    style: const TextStyle(color: Color(0xFFF45F67)),
  ),
),
        ],
      ),
      body: PageView.builder(
        itemCount: widget.filePaths.length,
        itemBuilder: (context, index) {
          return Center(
            child: widget.mimeTypes[index].startsWith('image/')
                ? Image.file(File(widget.filePaths[index]))
                : Container(),
          );
        },
      ),
    );
  }

  // Session check function that calls the custom dialog
  Future<bool> _checkSession(BuildContext context) async {
    final userId = await LoginService().getUserId();
    if (userId == null) {
      handleSessionExpired(context); // Show the custom session expired dialog
      return false; // Return false if session expired
    }
    return true; // Session is valid
  }
}