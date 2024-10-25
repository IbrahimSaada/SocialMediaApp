import 'package:flutter/material.dart';
import 'package:cook/services/chat_service.dart';
import 'package:cook/models/message_model.dart';
import 'message_input.dart';
import 'message_bubble.dart';
import 'chat_app_bar.dart';
import 'dart:async';

class ChatPage extends StatefulWidget {
  final String contactName;
  final String profileImageUrl;
  final bool isOnline;
  final String lastSeen;
  final int chatId;

  ChatPage({
    required this.contactName,
    required this.profileImageUrl,
    required this.isOnline,
    required this.lastSeen,
    required this.chatId,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  List<Message> messages = [];
  bool _isLoading = true;
  bool isSeen = true;
  String currentStatus = "Active now"; // Initial status
  Timer? _typingTimer;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    try {
      final fetchedMessages = await _chatService.fetchMessages(widget.chatId);
      setState(() {
        messages = fetchedMessages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      print('Error fetching messages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Handle sending a message
  void _handleSendMessage(String messageContent) {
    setState(() {
      messages.add(Message(
        messageId: DateTime.now().millisecondsSinceEpoch,
        chatId: widget.chatId,
        senderId: widget.chatId,
        senderUsername: widget.contactName,
        senderProfilePic: widget.profileImageUrl,
        messageType: 'text',
        messageContent: messageContent,
        createdAt: DateTime.now(),
        readAt: null,
        isEdited: false,
        isUnsent: false,
        mediaUrls: [],
      ));
    });
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
    DateTime currentMessageDate = messages[index].createdAt;
    DateTime previousMessageDate = messages[index - 1].createdAt;
    return currentMessageDate.day != previousMessageDate.day;
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(
        username: widget.contactName,
        profileImageUrl: widget.profileImageUrl,
        status: currentStatus,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isSender = message.senderId == widget.chatId;
                      final showDate = _isNewDay(index);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showDate)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(
                                  _formatDate(message.createdAt),
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          Align(
                            alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                            child: MessageBubble(
                              isSender: isSender,
                              message: message.messageContent,
                              timestamp: message.createdAt,
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
          MessageInput(onSendMessage: _handleSendMessage, onTyping: _handleTyping),
        ],
      ),
    );
  }

  // Handle editing a message (optional functionality)
  void _handleEditMessage(int index, String newText) {
    setState(() {
      messages[index] = Message(
        messageId: messages[index].messageId,
        chatId: messages[index].chatId,
        senderId: messages[index].senderId,
        senderUsername: messages[index].senderUsername,
        senderProfilePic: messages[index].senderProfilePic,
        messageType: messages[index].messageType,
        messageContent: newText,
        createdAt: messages[index].createdAt,
        readAt: messages[index].readAt,
        isEdited: true,
        isUnsent: messages[index].isUnsent,
        mediaUrls: messages[index].mediaUrls,
      );
    });
  }

  // Handle deleting a message for all users
  void _handleDeleteForAll(int index) {
    setState(() {
      messages[index] = Message(
        messageId: messages[index].messageId,
        chatId: messages[index].chatId,
        senderId: messages[index].senderId,
        senderUsername: messages[index].senderUsername,
        senderProfilePic: messages[index].senderProfilePic,
        messageType: messages[index].messageType,
        messageContent: 'This message has been deleted.',
        createdAt: messages[index].createdAt,
        readAt: messages[index].readAt,
        isEdited: messages[index].isEdited,
        isUnsent: true,
        mediaUrls: messages[index].mediaUrls,
      );
    });
  }

  // Handle deleting a message for the user only
  void _handleDeleteForMe(int index) {
    setState(() {
      messages.removeAt(index);
    });
  }
}
