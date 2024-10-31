// message_bubble.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '/models/media_item.dart'; // Import MediaItem

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
  final Function onDeleteForMe;
  final String messageType;
  final List<MediaItem> mediaItems; // Updated to use MediaItem

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
    required this.onDeleteForMe,
    required this.messageType,
    required this.mediaItems,
  });

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isEditing = false;
  late TextEditingController _editingController;
  VideoPlayerController? _videoPlayerController;
  final double _mediaSize = 200.0;

  @override
  void initState() {
    super.initState();
    _editingController = TextEditingController(text: widget.message);
  }

  @override
  void dispose() {
    _editingController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDeleted = widget.isUnsent;

    return Column(
      crossAxisAlignment: widget.isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: isDeleted ? null : () => _showMessageOptions(context),
          child: Container(
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
                : widget.messageType == 'media'
                    ? _buildMediaContent()
                    : _buildMessageContent(isDeleted),
          ),
        ),
        if (!isDeleted) _buildTimestampAndEditedLabel(),
      ],
    );
  }

  Widget _buildMediaContent() {
    if (widget.isUnsent || widget.mediaItems.isEmpty) {
      return _buildMessageContent(true);
    }

    // Assuming only one media item per message
    MediaItem mediaItem = widget.mediaItems.first;

    if (mediaItem.mediaType == 'photo') {
      return _buildImageBubble(mediaItem.mediaUrl);
    } else if (mediaItem.mediaType == 'video') {
      return _buildVideoBubble(mediaItem.mediaUrl);
    } else {
      return Text('Unsupported media type');
    }
  }

  Widget _buildImageBubble(String imageUrl) {
    return GestureDetector(
      onTap: () => _openFullScreenImage(imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          height: _mediaSize,
          width: _mediaSize,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: _mediaSize,
            width: _mediaSize,
            color: Colors.grey[200],
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoBubble(String videoUrl) {
    return GestureDetector(
      onTap: () => _openFullScreenVideo(videoUrl),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: _mediaSize,
            width: _mediaSize,
            color: Colors.black12,
            child: Icon(Icons.videocam, color: Colors.grey, size: 50),
          ),
          Icon(Icons.play_circle_outline, color: Colors.white, size: 50),
        ],
      ),
    );
  }

  void _openFullScreenVideo(String videoUrl) async {
    final cachedFile = await DefaultCacheManager().getSingleFile(videoUrl);
    _videoPlayerController = VideoPlayerController.file(cachedFile);

    await _videoPlayerController!.initialize();
    final chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Chewie(controller: chewieController),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () {
                    chewieController.dispose();
                    _videoPlayerController?.dispose();
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
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
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: widget.isSender ? Color(0xFFF45F67) : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _editingController,
        autofocus: true,
        style: TextStyle(
          fontSize: 14,
          color: widget.isSender ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          border: InputBorder.none,
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

  Widget _buildTimestampAndEditedLabel() {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0, left: 16.0, right: 16.0),
      child: Row(
        mainAxisAlignment: widget.isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
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
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              children: [
                if (widget.isSender && widget.messageType == 'text' && !widget.isUnsent)
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.blue),
                    title: const Text('Edit'),
                    onTap: () {
                      setState(() => _isEditing = true);
                      Navigator.pop(context);
                    },
                  ),
                if (widget.isSender && !widget.isUnsent)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Delete for everyone'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onDeleteForAll();
                    },
                  ),
                if (!widget.isSender && !widget.isUnsent)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Delete for me'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onDeleteForMe();
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

  void _openFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Stack(
              children: [
                InteractiveViewer(
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String _formatFullTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}, ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
