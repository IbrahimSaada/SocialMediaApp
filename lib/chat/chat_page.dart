// chat_page.dart

import 'package:flutter/material.dart';
import 'package:cook/services/chat_service.dart';
import 'package:cook/models/message_model.dart';
import 'package:cook/services/signalr_service.dart';
import 'message_input.dart';
import 'message_bubble.dart';
import 'chat_app_bar.dart';

class ChatPage extends StatefulWidget {
  final int chatId;
  final int currentUserId;
  final int recipientUserId;
  final String contactName;
  final String profileImageUrl;
  final bool isOnline;
  final String lastSeen;

  ChatPage({
    required this.chatId,
    required this.currentUserId,
    required this.recipientUserId,
    required this.contactName,
    required this.profileImageUrl,
    required this.isOnline,
    required this.lastSeen,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final SignalRService _signalRService = SignalRService();
  List<Message> messages = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initSignalR();
  }

  Future<void> _initSignalR() async {
    try {
      await _signalRService.initSignalR();

      // Register event handlers
      _signalRService.hubConnection.on('ReceiveMessage', _handleReceiveMessage);
      _signalRService.hubConnection.on('MessageSent', _handleMessageSent);

      // Fetch messages via SignalR after connection is established
      await _fetchMessages();
    } catch (e) {
      print('Error initializing SignalR: $e');
    }
  }

  Future<void> _fetchMessages() async {
    try {
      print('Invoking FetchMessages for chat ${widget.chatId}');
      var result = await _signalRService.hubConnection.invoke('FetchMessages', args: [widget.chatId]);

      print('FetchMessages result: $result');

      List<dynamic> messagesData = result as List<dynamic>;
      List<Message> fetchedMessages = [];
      for (var messageData in messagesData) {
        try {
          Map<String, dynamic> messageMap = Map<String, dynamic>.from(messageData);
          Message message = Message.fromJson(messageMap);
          fetchedMessages.add(message);
        } catch (e) {
          print('Error parsing message: $e');
          print('Message data: $messageData');
        }
      }

      print('Fetched ${fetchedMessages.length} messages');

      setState(() {
        messages = fetchedMessages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      print('Error fetching messages via SignalR: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleReceiveMessage(List<Object?>? arguments) {
    print('ReceiveMessage event received: $arguments');
    if (arguments != null && arguments.isNotEmpty) {
      final messageData = Map<String, dynamic>.from(arguments[0] as Map);

      // Convert date strings to DateTime objects
      if (messageData['createdAt'] is String) {
        messageData['createdAt'] = DateTime.parse(messageData['createdAt']);
      }
      if (messageData['readAt'] != null && messageData['readAt'] is String) {
        messageData['readAt'] = DateTime.parse(messageData['readAt']);
      }

      final message = Message.fromJson(messageData);

      print('Parsed Message in ReceiveMessage: $message');

      if (message.chatId == widget.chatId) {
        setState(() {
          messages.add(message);
          print('Message added to list: ${message.messageContent}');
        });
        _scrollToBottom();
      } else {
        print('Received message for a different chat: ${message.chatId}');
      }
    }
  }

  void _handleMessageSent(List<Object?>? arguments) {
    print('MessageSent event received: $arguments');
    if (arguments != null && arguments.isNotEmpty) {
      final Map<String, dynamic> messageData = Map<String, dynamic>.from(arguments[0] as Map);

      // Convert DateTime strings to DateTime objects if necessary
      if (messageData['createdAt'] is String) {
        messageData['createdAt'] = DateTime.parse(messageData['createdAt']);
      }
      if (messageData['readAt'] != null && messageData['readAt'] is String) {
        messageData['readAt'] = DateTime.parse(messageData['readAt']);
      }

      final message = Message.fromJson(messageData);

      print('Parsed Message in MessageSent: $message');

      if (message.chatId == widget.chatId) {
        setState(() {
          messages.add(message);
          print('Message added to list: ${message.messageContent}');
          print('Total messages in list: ${messages.length}');
        });
        _scrollToBottom();
      } else {
        print('MessageSent event for different chat');
      }
    }
  }

  // Handle sending a message
  void _handleSendMessage(String messageContent) async {
    try {
      await _signalRService.hubConnection.invoke('SendMessage', args: [
        widget.recipientUserId,
        messageContent,
        'text', // Message type
        null, // Media URLs if any
      ]);
      print('Message sent successfully');
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  // Scroll to the last message
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    // Do not stop the SignalR connection here to keep it active
    // _signalRService.hubConnection.stop();

    // Unregister event handlers to prevent memory leaks
    _signalRService.hubConnection.off('ReceiveMessage', method: _handleReceiveMessage);
    _signalRService.hubConnection.off('MessageSent', method: _handleMessageSent);

    super.dispose();
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(
        username: widget.contactName,
        profileImageUrl: widget.profileImageUrl,
        status: widget.isOnline ? 'Online' : 'Offline',
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
                      final isSender = message.senderId == widget.currentUserId;
                      final showDate = _isNewDay(index);

                      print('Building message at index $index: ${message.messageContent}');

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
                              isSeen: false,
                              onEdit: (newText) {
                                // Empty function or implement later
                              },
                              onDeleteForAll: () {
                                // Empty function or implement later
                              },
                              onDeleteForMe: () {
                                // Empty function or implement later
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          MessageInput(
            onSendMessage: _handleSendMessage,
            onTyping: () {
              // Implement typing indicator if needed
            },
          ),
        ],
      ),
    );
  }
}
