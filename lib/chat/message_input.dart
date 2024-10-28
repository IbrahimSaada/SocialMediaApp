// message_input.dart

import 'package:flutter/material.dart';
import 'dart:async';

class MessageInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function onTyping;
  final Function onTypingStopped;

  MessageInput({
    required this.onSendMessage,
    required this.onTyping,
    required this.onTypingStopped,
  });

  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;
  Timer? _typingTimer;

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

  @override
  void dispose() {
    _controller.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                      // Handle camera action
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
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 200),
                    child: !_isTyping
                        ? IconButton(
                            key: ValueKey('gallery'),
                            icon: Icon(Icons.photo, color: Color(0xFFF45F67)),
                            onPressed: () {
                              // Handle gallery action
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
    );
  }
}
