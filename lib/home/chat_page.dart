import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Import for File class
import '***REMOVED***/home/contacts_page.dart'; // Import for Contact class
import 'package:video_player/video_player.dart'; // Import package for playing videos
import 'package:permission_handler/permission_handler.dart'; // Import for permissions

class ChatPage extends StatefulWidget {
  final Contact contact;

  const ChatPage({super.key, required this.contact});

  @override
  // ignore: library_private_types_in_public_api
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Message> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  void _requestPermissions() async {
    var status = await [
      Permission.photos,
      Permission.microphone,
      Permission.storage,
    ].request();
    if (status[Permission.photos]!.isDenied ||
        status[Permission.microphone]!.isDenied ||
        status[Permission.storage]!.isDenied) {
      // ignore: avoid_print
      print('Permissions denied');
    }
  }

  void _sendMessage() {
    if (_controller.text.isEmpty) return;

    setState(() {
      messages.add(Message(
        text: _controller.text,
        sender: 'Me',
        timestamp: DateTime.now().toString(),
      ));
    });

    _controller.clear();
  }

  void _sendImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // ignore: avoid_print
      print('Selected image path: ${image.path}');
      setState(() {
        messages.add(Message(
          imageUrl: image.path,
          sender: 'Me',
          timestamp: DateTime.now().toString(),
        ));
      });
    } else {
      // ignore: avoid_print
      print('No image selected');
    }
  }

  void _sendVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      // ignore: avoid_print
      print('Selected video path: ${video.path}');
      setState(() {
        messages.add(Message(
          videoUrl: video.path,
          sender: 'Me',
          timestamp: DateTime.now().toString(),
        ));
      });
    } else {
      // ignore: avoid_print
      print('No video selected');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact.name),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return MessageCard(message: messages[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo, color: Colors.orange),
                  onPressed: _sendImage,
                ),
                IconButton(
                  icon: const Icon(Icons.videocam, color: Colors.orange),
                  onPressed: _sendVideo,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.orange),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final String? text;
  final String? imageUrl;
  final String? videoUrl;
  final String sender;
  final String timestamp;

  Message({
    this.text,
    this.imageUrl,
    this.videoUrl,
    required this.sender,
    required this.timestamp,
  });
}

class MessageCard extends StatelessWidget {
  final Message message;

  const MessageCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Align(
        alignment: message.sender == 'Me' ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: message.sender == 'Me' ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // ignore: unnecessary_null_comparison
            if (message.timestamp != null)
              Text(
                message.timestamp.split(' ')[0], // Display date only
                style: const TextStyle(fontSize: 12.0, color: Colors.orange),
              ),
            if (message.text != null)
              Container(
                decoration: BoxDecoration(
                  color: message.sender == 'Me' ? Colors.orange : Colors.grey[200],
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  message.text!,
                  style: TextStyle(
                    color: message.sender == 'Me' ? Colors.white : Colors.black,
                  ),
                ),
              ),
            if (message.imageUrl != null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 5.0),
                child: Image.file(File(message.imageUrl!)),
              ),
            if (message.videoUrl != null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 5.0),
                child: VideoPlayerWidget(videoUrl: message.videoUrl!), // Create a widget for video player
              ),
          ],
        ),
      ),
    );
  }
}

// Widget for playing video files using video_player package
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  // ignore: library_private_types_in_public_api
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoUrl));
    _initializeVideoPlayerFuture = _controller.initialize().catchError((error) {
      // ignore: avoid_print
      print("Video initialization failed: $error");
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading video: ${snapshot.error}'));
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
