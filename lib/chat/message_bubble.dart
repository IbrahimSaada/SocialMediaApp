import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final bool isSender;
  final String message;
  final DateTime timestamp;

  const MessageBubble({
    required this.isSender,
    required this.message,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        _showMessageOptions(context);  // Trigger the long-press options (delete/forward)
      },
      child: AnimatedScale(
        scale: 1.0, // Default scale
        duration: Duration(milliseconds: 100),
        child: Align(
          alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSender ? Color(0xFFF45F67) : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isSender ? 12 : 0),
                topRight: Radius.circular(isSender ? 0 : 12),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: Offset(2, 2),  // Subtle shadow for the message bubble
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: isSender ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(
                    color: isSender ? Colors.white70 : Colors.black54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Function to format the timestamp
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // Function to show message options (delete/forward)
  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete Message'),
              onTap: () {
                // Handle delete message action
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.forward, color: Colors.blue),
              title: Text('Forward Message'),
              onTap: () {
                // Handle forward message action
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
