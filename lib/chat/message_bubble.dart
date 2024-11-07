// message_bubble.dart

import 'package:flutter/material.dart';

class MessageBubble extends StatefulWidget {
  final bool isSender;
  final String message;
  final DateTime timestamp;
  final bool isSeen;
  final bool isEdited;
  final bool isUnsent;
  final DateTime? readAt;
  final Function(String newText) onEdit;
  final Function onDeleteForAll;
  final String messageType;

  const MessageBubble({
    required this.isSender,
    required this.message,
    required this.timestamp,
    required this.isSeen,
    required this.isEdited,
    required this.isUnsent,
    required this.readAt,
    required this.onEdit,
    required this.onDeleteForAll,
    required this.messageType,
  });

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isEditing = false;
  late TextEditingController _editingController;

  @override
  void initState() {
    super.initState();
    _editingController = TextEditingController(text: widget.message);
  }

  @override
  void dispose() {
    _editingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDeleted = widget.isUnsent;

    return Column(
      crossAxisAlignment:
          widget.isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress:
              isDeleted || !widget.isSender ? null : () => _showMessageOptions(context),
          child: Container(
            constraints:
                BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDeleted
                  ? Colors.grey[300]
                  : widget.isSender
                      ? Color(0xFFF45F67)
                      : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(widget.isSender ? 12 : 0),
                topRight: Radius.circular(widget.isSender ? 0 : 12),
                bottomLeft: const Radius.circular(12),
                bottomRight: const Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 2,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            child: _isEditing
                ? _buildEditField()
                : _buildMessageContent(isDeleted),
          ),
        ),
        if (!isDeleted) _buildTimestampAndEditedLabel(),
      ],
    );
  }

  Widget _buildMessageContent(bool isDeleted) {
    return Text(
      isDeleted ? 'This message was deleted' : widget.message,
      style: TextStyle(
        color: isDeleted
            ? Colors.black54
            : widget.isSender
                ? Colors.white
                : Colors.black,
        fontSize: 16,
      ),
    );
  }

  Widget _buildEditField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isSender ? Color(0xFFF45F67) : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _editingController,
        autofocus: true,
        cursorColor: Colors.white,
        style: TextStyle(
          fontSize: 16,
          color: widget.isSender ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          hintText: 'Edit message...',
          border: InputBorder.none,
        ),
        maxLines: null,
        textInputAction: TextInputAction.done,
        onEditingComplete: () {
          String newText = _editingController.text.trim();
          if (newText.isNotEmpty) {
            widget.onEdit(newText);
            setState(() {
              _isEditing = false;
            });
          }
        },
      ),
    );
  }

  Widget _buildTimestampAndEditedLabel() {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0, left: 16.0, right: 16.0),
      child: Row(
        mainAxisAlignment:
            widget.isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Text(
            _formatTimestamp(widget.timestamp),
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
          if (widget.isEdited && !widget.isUnsent)
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                'Edited',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (widget.isSender && widget.isSeen)
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: CircleAvatar(
                radius: 8,
                backgroundColor: Color(0xFFF45F67),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    if (!widget.isSender) return;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              children: [
                if (widget.messageType == 'text' && !widget.isUnsent)
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.blue),
                    title: const Text('Edit'),
                    onTap: () {
                      setState(() => _isEditing = true);
                      Navigator.pop(context);
                    },
                  ),
                if (!widget.isUnsent)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Delete For Everyone'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onDeleteForAll();
                    },
                  ),
              ],
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sent at: ${_formatFullTimestamp(widget.timestamp)}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  if (widget.readAt != null)
                    Text(
                      'Read at: ${_formatFullTimestamp(widget.readAt!)}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hour = twoDigits(timestamp.hour);
    String minute = twoDigits(timestamp.minute);
    return '$hour:$minute';
  }

  String _formatFullTimestamp(DateTime timestamp) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String day = twoDigits(timestamp.day);
    String month = twoDigits(timestamp.month);
    String year = timestamp.year.toString();
    String hour = twoDigits(timestamp.hour);
    String minute = twoDigits(timestamp.minute);
    return '$day/$month/$year, $hour:$minute';
  }
}
