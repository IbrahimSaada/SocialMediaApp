import 'package:flutter/material.dart';
import 'message_input.dart';
import 'message_bubble.dart';
import 'chat_app_bar.dart';
import 'dart:async';  // For typing timer

class ChatPage extends StatefulWidget {
  final String contactName;
  final String profileImageUrl;
  final bool isOnline;
  final String lastSeen;

  ChatPage({
    required this.contactName,
    required this.profileImageUrl,
    required this.isOnline,
    required this.lastSeen,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> messages = [
    {
      'message': 'Hello! How are you?',
      'isSender': true,
      'timestamp': DateTime.now().subtract(Duration(days: 3, hours: 2)),
    },
    {
      'message': 'I am good, how about you?',
      'isSender': false,
      'timestamp': DateTime.now().subtract(Duration(days: 3, hours: 1)),
    },
    {
      'message': 'Doing well, thanks!',
      'isSender': true,
      'timestamp': DateTime.now().subtract(Duration(days: 2, hours: 5)),
    },
    {
      'message': 'Great to hear!',
      'isSender': false,
      'timestamp': DateTime.now().subtract(Duration(days: 2, hours: 2)),
    },
    {
      'message': 'Thanks! Catch up soon!',
      'isSender': true,
      'timestamp': DateTime.now().subtract(Duration(days: 1, minutes: 15)),
    },
    {
      'message': 'Sure! Bye!',
      'isSender': false,
      'timestamp': DateTime.now().subtract(Duration(days: 1, minutes: 10)),
    },
  ];

  bool isSeen = true;
  String currentStatus = "Active now";  // Initial status
  Timer? _typingTimer;
  final ScrollController _scrollController = ScrollController();  // For scrolling to last message

  // Handle sending a message
  void _handleSendMessage(String message) {
    setState(() {
      messages.add({
        'message': message,
        'isSender': true,
        'timestamp': DateTime.now(),
      });
    });

    // Scroll to the bottom when a message is sent
    _scrollToBottom();
  }

  // Scroll to the last message
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // Handle typing status
  void _handleTyping() {
    setState(() {
      currentStatus = "typing...";
    });

    _typingTimer?.cancel();

    _typingTimer = Timer(Duration(seconds: 3), () {
      setState(() {
        currentStatus = "Active now";
      });
    });
  }

  // Format date for message separator
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Determine if a new day has started
  bool _isNewDay(int index) {
    if (index == 0) return true;
    DateTime currentMessageDate = messages[index]['timestamp'];
    DateTime previousMessageDate = messages[index - 1]['timestamp'];
    return currentMessageDate.day != previousMessageDate.day;
  }

  // Handle editing a message
  void _handleEditMessage(int index, String newText) {
    setState(() {
      messages[index]['message'] = newText;
    });
  }

  // Handle deleting a message for all users
  void _handleDeleteForAll(int index) {
    setState(() {
      messages[index]['message'] = 'This message has been deleted.';
    });
  }

  // Handle deleting a message for the user only
  void _handleDeleteForMe(int index) {
    setState(() {
      messages.removeAt(index);
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();  // Cancel typing timer if active
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollToBottom();  // Scroll to the last message when entering the chat
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(
        username: widget.contactName,
        profileImageUrl: widget.profileImageUrl,
        status: currentStatus,  // Display current status (typing or active)
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,  // Attach the scroll controller
              reverse: false,
              itemCount: messages.length,  // Total number of messages
              itemBuilder: (context, index) {
                bool isSender = messages[index]['isSender'];
                String message = messages[index]['message'];
                DateTime timestamp = messages[index]['timestamp'];

                // Check if we need to show a date separator
                bool showDate = _isNewDay(index);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,  // Ensure date separator is centered
                  children: [
                    if (showDate)  // Display date separator in the center if it's a new day
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Text(
                            _formatDate(timestamp),
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    Align(
                      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,  // Align messages like before
                      child: MessageBubble(
                        isSender: isSender,
                        message: message,
                        timestamp: timestamp,
                        isSeen: isSender && index == messages.length - 1 && isSeen,
                        onEdit: (newText) => _handleEditMessage(index, newText),
                        onDeleteForAll: () => _handleDeleteForAll(index),
                        onDeleteForMe: () => _handleDeleteForMe(index),
                        
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          MessageInput(onSendMessage: _handleSendMessage, onTyping: _handleTyping),  // Handle typing and sending messages
        ],
      ),
    );
  }
}
