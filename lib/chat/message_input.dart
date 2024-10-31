// message_input.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function onTyping;
  final Function onTypingStopped;
  final Function(XFile, String) onSendMediaMessage;

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

  // Handle text changes
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

  // Request permissions for camera and microphone
  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();
  }

  // Capture photo and send directly
  Future<void> _capturePhoto() async {
    await _requestPermissions();
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      widget.onSendMediaMessage(photo, 'photo');
    }
  }

  // Record video and send directly
  Future<void> _captureVideo() async {
    await _requestPermissions();
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      widget.onSendMediaMessage(video, 'video');
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
    return Column(
      children: [
        if (_isTyping)
          LinearProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF45F67)),
          ),
        Padding(
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
                                key: ValueKey('gallery'),
                                icon: Icon(Icons.photo, color: Color(0xFFF45F67)),
                                onPressed: () {
                                  // Handle gallery action, to be implemented
                                },
                              )
                            : SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: Duration(milliseconds: 200),
                child: _isTyping
                    ? IconButton(
                        key: ValueKey('send'),
                        icon: Icon(Icons.send, color: Color(0xFFF45F67)),
                        onPressed: _sendMessage,
                      )
                    : SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
