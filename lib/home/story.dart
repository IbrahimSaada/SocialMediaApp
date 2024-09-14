import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:mime/mime.dart';
import '***REMOVED***/models/story_model.dart' as story_model;
import '***REMOVED***/services/s3_upload_service.dart';
import '***REMOVED***/models/presigned_url.dart';
import '***REMOVED***/services/StoryService.dart'; // Import the story service
import '***REMOVED***/services/LoginService.dart'; // Import the login service to get user ID
import '***REMOVED***/models/story_request_model.dart'; // Import the story request model

class StoryBox extends StatefulWidget {
  final Function(List<story_model.Story>) onStoriesUpdated;

  const StoryBox({super.key, required this.onStoriesUpdated});

  @override
  // ignore: library_private_types_in_public_api
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
            borderRadius: BorderRadius.circular(15.0), // Rounded corners for the dialog
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
                      border: Border.all(color: const Color(0xFFF4A261), width: 2),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF4A261), // Soft warm orange like the AppBar
                          Color(0xFFE9C46A), // A lighter variant for a cohesive vibe
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
                      border: Border.all(color: const Color(0xFFF4A261), width: 2),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF4A261),
                          Color(0xFFE9C46A),
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
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture media: $e')),
      );
    }
  }

  Future<void> _pickMedia() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image, // Only allow image selection
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        if (result.files.length > _maxMediaCount) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('You can select a maximum of 10 media files.')),
          );
        } else {
          _handlePickedFiles(result.paths.whereType<String>().toList());
        }
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
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

    List<String> fileNames =
        mediaPaths.map((path) => path.split('/').last).toList();

    try {
      int userId = await LoginService().getUserId() ?? 0;

      List<PresignedUrl> presignedUrls = await s3UploadService
          .getPresignedUrls(fileNames, folderName: 'stories');

      List<MediaRequest> mediaItems = [];
      for (int i = 0; i < presignedUrls.length; i++) {
        String uploadedUrl = await s3UploadService.uploadFile(
            presignedUrls[i], XFile(mediaPaths[i]));
        // ignore: unused_local_variable
        String mimeType = lookupMimeType(mediaPaths[i]) ?? '';

        mediaItems.add(
          MediaRequest(
            mediaUrl: uploadedUrl,
            mediaType: 'photo',
          ),
        );
      }

      StoryRequest storyRequest =
          StoryRequest(userId: userId, media: mediaItems);

      await storyService.createStory(storyRequest);

      List<story_model.Story> updatedStories =
          await storyService.fetchStories(userId);
      widget.onStoriesUpdated(updatedStories);

      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create story: $e')),
      );
    }
  }

  bool _isValidMimeType(String mimeType) {
    return mimeType.startsWith('image/');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showOptionsDialog(context),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF4B3F72), // Deep burgundy color
              Color(0xFFF4A261), // Warm orange color
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.0), // Softer rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15), // Updated shadow
              blurRadius: 8,
              offset: const Offset(0, 4), // Shadow position
            ),
          ],
        ),
        child: Container(
          width: 110, // Increased size
          height: 110, // Increased size
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0), // Softer corners
            color: Colors.white, // Background color inside the border
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Center the plus icon and make it white with a transparent circular background
              Container(
                width: 45, // Adjust size of circular container
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1), // Transparent circle background
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 30), // Plus icon in the center
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MediaPreviewScreen extends StatelessWidget {
  final List<String> filePaths;
  final List<String> mimeTypes;
  final Function(List<String>) onSendToStory;

  const MediaPreviewScreen({super.key, 
    required this.filePaths,
    required this.mimeTypes,
    required this.onSendToStory,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Media'),
        actions: [
          TextButton(
            onPressed: () {
              onSendToStory(filePaths);
            },
            child: const Text(
              'SEND',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
      body: PageView.builder(
        itemCount: filePaths.length,
        itemBuilder: (context, index) {
          return Center(
            child: mimeTypes[index].startsWith('image/')
                ? Image.file(File(filePaths[index]))
                : Container(),
          );
        },
      ),
    );
  }
}
