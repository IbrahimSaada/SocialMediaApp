import 'package:flutter/material.dart';

class MessageBubble extends StatefulWidget {
  final bool isSender;
  final String message;
  final DateTime timestamp;
  final bool isSeen;
  final Function(String newText) onEdit;
  final Function onDeleteForAll;
  final Function onDeleteForMe;

  const MessageBubble({
    required this.isSender,
    required this.message,
    required this.timestamp,
    required this.isSeen,
    required this.onEdit,
    required this.onDeleteForAll,
    required this.onDeleteForMe,
  });

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isEditing = false;
  TextEditingController _editingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _editingController.text = widget.message;
  }

  @override
  Widget build(BuildContext context) {
    bool isDeleted = widget.message == 'This message has been deleted.';

    return Column(
      crossAxisAlignment:
          widget.isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: isDeleted
              ? null
              : () {
                  _showMessageOptions(context);
                },
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDeleted
                  ? Colors.grey[300]
                  : widget.isSender
                      ? Color(0xFFF45F67)
                      : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(widget.isSender ? 12 : 0),
                topRight: Radius.circular(widget.isSender ? 0 : 12),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: isDeleted
                ? Text(
                    widget.message,
                    style: TextStyle(
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : _isEditing
                    ? _buildEditField()
                    : Text(
                        widget.message,
                        style: TextStyle(
                          color: widget.isSender ? Colors.white : Colors.black,
                        ),
                      ),
          ),
        ),
        if (!isDeleted)
          Padding(
            padding: EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTimestamp(widget.timestamp),
                  style: TextStyle(
                    color: widget.isSender ? Colors.white70 : Colors.black54,
                    fontSize: 10,
                  ),
                ),
                if (widget.isSender && widget.isSeen)
                  Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text(
                      'Seen at ${_formatTimestamp(widget.timestamp)}',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // Updated edit design with better styling
  Widget _buildEditField() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _editingController,
        autofocus: true,
        style: TextStyle(fontSize: 14, color: Colors.black), // Improved design with smaller font
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey, width: 1),
          ),
        ),
        onSubmitted: (newText) {
          setState(() {
            _isEditing = false;
          });
          widget.onEdit(newText);
        },
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Wrap(
          children: [
            if (widget.isSender) ...[
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Edit'),
                onTap: () {
                  setState(() {
                    _isEditing = true;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete for all'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDeleteForAll();
                },
              ),
            ],
            if (!widget.isSender) ...[
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete for me'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDeleteForMe();
                },
              ),
            ],
          ],
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}