import 'package:flutter/material.dart';
import 'message_input.dart';  // Import the MessageInput widget
import 'message_bubble.dart';  // Import the MessageBubble widget
import 'chat_app_bar.dart';  // Import the ChatAppBar widget

class ChatPage extends StatelessWidget {
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

  void _handleSendMessage(String message) {
    print('Message sent: $message');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(
        username: contactName,
        profileImageUrl: profileImageUrl,
        isOnline: isOnline,
        lastSeen: lastSeen,
      ),  // Use your separated ChatAppBar
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: 20,  // Example message count
              itemBuilder: (context, index) {
                bool isSender = index % 2 == 0;  // Example logic for sender/receiver
                return MessageBubble(
                  isSender: isSender,
                  message: isSender
                      ? 'This is a message from me.'
                      : 'This is a message from the contact.',
                  timestamp: DateTime.now(),
                );
              },
            ),
          ),
          MessageInput(onSendMessage: _handleSendMessage),  // Input for sending messages
        ],
      ),
    );
  }
}
