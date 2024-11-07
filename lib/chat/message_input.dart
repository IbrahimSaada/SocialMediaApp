// message_input.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart'; // For selecting both images and videos
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function onTyping;
  final Function onTypingStopped;
  final Function(List<XFile>, String) onSendMediaMessage;

  MessageInput({
    required this.onSendMessage,
    required this.onTyping,
    required this.onTypingStopped,
    required this.onSendMediaMessage,
  });

  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;
  Timer? _typingTimer;
  final ImagePicker _picker = ImagePicker();

  void _onTextChanged(String value) {
    setState(() {
      _isTyping = value.isNotEmpty;
    });
    if (_isTyping) {
      widget.onTyping();
      _startTypingTimer();
    } else {
      widget.onTypingStopped();
    }
  }

  void _startTypingTimer() {
    _typingTimer?.cancel();
    _typingTimer = Timer(Duration(seconds: 2), () {
      widget.onTypingStopped();
    });
  }

  void _sendMessage() {
    if (_isTyping) {
      widget.onSendMessage(_controller.text);
      _controller.clear();
      setState(() {
        _isTyping = false;
      });
      widget.onTypingStopped();
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.storage.request();
  }

  Future<void> _selectMediaFromGallery() async {
    await _requestPermissions();
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.media,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      List<XFile> selectedMediaFiles = result.paths.map((path) => XFile(path!)).toList();

      if (selectedMediaFiles.length > 4) {
        selectedMediaFiles = selectedMediaFiles.sublist(0, 4);
      }

      widget.onSendMediaMessage(selectedMediaFiles, 'media');
    }
  }

  Future<void> _capturePhoto() async {
    await _requestPermissions();
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      widget.onSendMediaMessage([photo], 'photo');
    }
  }

  Future<void> _captureVideo() async {
    await _requestPermissions();
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      widget.onSendMediaMessage([video], 'video');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom), // Adjust for keyboard
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFFF45F67), width: 2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.photo, color: Color(0xFFF45F67)),
                      onPressed: () {
                        _selectMediaFromGallery();
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: _onTextChanged,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                        ),
                        minLines: 1,
                        maxLines: null,
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 200),
                      child: !_isTyping
                          ? IconButton(
                              key: ValueKey('camera'),
                              icon: Icon(Icons.camera_alt, color: Color(0xFFF45F67)),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) => SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: Icon(Icons.photo_camera),
                                          title: Text('Take a Photo'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _capturePhoto();
                                          },
                                        ),
                                        ListTile(
                                          leading: Icon(Icons.videocam),
                                          title: Text('Record a Video'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _captureVideo();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: Color(0xFFF45F67)),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
