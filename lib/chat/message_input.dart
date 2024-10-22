import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSendMessage;

  MessageInput({required this.onSendMessage});

  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;

  // Listen for changes in the text field
  void _onTextChanged(String value) {
    setState(() {
      _isTyping = value.isNotEmpty;  // Show send button only if user types something
    });
  }

  // Clear the input and send the message
  void _sendMessage() {
    if (_isTyping) {
      widget.onSendMessage(_controller.text);
      _controller.clear();
      setState(() {
        _isTyping = false;  // Reset typing state
      });
    }
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
                border: Border.all(color: Color(0xFFF45F67), width: 2),  // Primary color border
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.camera_alt, color: Color(0xFFF45F67)),  // Camera icon stays
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
                        border: InputBorder.none,  // No border since the outer Container has it
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 200),
                    child: !_isTyping
                        ? IconButton(
                            key: ValueKey('gallery'),
                            icon: Icon(Icons.photo, color: Color(0xFFF45F67)),  // Gallery icon
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
                    icon: Icon(Icons.send, color: Color(0xFFF45F67)),  // Send button
                    onPressed: _sendMessage,
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
