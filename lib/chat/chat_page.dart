// chat_page.dart

import 'package:flutter/material.dart';
import 'package:cook/services/chat_service.dart';
import 'package:cook/models/message_model.dart';
import 'package:cook/services/signalr_service.dart';
import 'package:cook/services/s3_upload_service.dart';
import 'package:image_picker/image_picker.dart';
import 'message_input.dart';
import 'message_bubble.dart';
import 'chat_app_bar.dart';
import 'dart:async';
import 'dart:io';

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
  final S3UploadService _s3UploadService = S3UploadService(); // Added for media upload
  List<Message> messages = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  bool _isRecipientTyping = false;
  Timer? _typingTimer;
  String _status = '';
  bool _isUploadingMedia = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _status = widget.isOnline ? 'Online' : 'Offline';
    _initSignalR();
  }

  Future<void> _initSignalR() async {
    try {
      await _signalRService.initSignalR();

      // Register event handlers
      _signalRService.hubConnection.on('ReceiveMessage', _handleReceiveMessage);
      _signalRService.hubConnection.on('MessageSent', _handleMessageSent);
      _signalRService.hubConnection.on('MessageEdited', _handleMessageEdited);
      _signalRService.hubConnection.on('MessageUnsent', _handleMessageUnsent);
      _signalRService.hubConnection.on('UserTyping', _handleUserTyping);
      _signalRService.hubConnection.on('MessagesRead', _handleMessagesRead);

      // Fetch messages via SignalR after connection is established
      await _fetchMessages();

      // Mark messages as read when the chat is opened
      _signalRService.markMessagesAsRead(widget.chatId);
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
          _isRecipientTyping = false;
          _status = widget.isOnline ? 'Online' : 'Offline';
        });
        _scrollToBottom();
      } else {
        print('Received message for a different chat: ${message.chatId}');
      }
    }
    _signalRService.markMessagesAsRead(widget.chatId);
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

  void _handleUserTyping(List<Object?>? arguments) {
    print('UserTyping event received: $arguments');
    if (arguments != null && arguments.isNotEmpty) {
      int senderId = arguments[0] as int;
      if (senderId == widget.recipientUserId) {
        setState(() {
          _isRecipientTyping = true;
          _status = 'Typing...';
        });
        _resetTypingTimer();
      }
    }
  }

  void _resetTypingTimer() {
    _typingTimer?.cancel();
    _typingTimer = Timer(Duration(seconds: 3), () {
      setState(() {
        _isRecipientTyping = false;
        _status = widget.isOnline ? 'Online' : 'Offline';
      });
    });
  }

  // Handle 'MessageEdited' event from backend
  void _handleMessageEdited(List<Object?>? arguments) {
    print('MessageEdited event received: $arguments');
    if (arguments != null && arguments.isNotEmpty) {
      final messageData = Map<String, dynamic>.from(arguments[0] as Map);

      // Convert date strings to DateTime objects
      if (messageData['createdAt'] is String) {
        messageData['createdAt'] = DateTime.parse(messageData['createdAt']);
      }
      if (messageData['readAt'] != null && messageData['readAt'] is String) {
        messageData['readAt'] = DateTime.parse(messageData['readAt']);
      }

      final editedMessage = Message.fromJson(messageData);

      print('Parsed edited Message: $editedMessage');

      if (editedMessage.chatId == widget.chatId) {
        // Find the message in the messages list and update it
        setState(() {
          int index = messages.indexWhere((msg) => msg.messageId == editedMessage.messageId);
          if (index != -1) {
            messages[index] = editedMessage;
            print('Message updated in list: ${editedMessage.messageContent}');
          }
        });
      } else {
        print('Edited message belongs to a different chat: ${editedMessage.chatId}');
      }
    }
  }

  // Handle 'MessageUnsent' event from backend
  void _handleMessageUnsent(List<Object?>? arguments) {
    print('MessageUnsent event received: $arguments');
    if (arguments != null && arguments.isNotEmpty) {
      int messageId = arguments[0] as int;

      setState(() {
        int index = messages.indexWhere((msg) => msg.messageId == messageId);
        if (index != -1) {
          // Mark the message as unsent
          messages[index] = messages[index].copyWith(
            isUnsent: true,
            messageContent: 'This message was deleted',
          );
          print('Message marked as unsent: $messageId');
        }
      });
    }
  }

  void _handleMessagesRead(List<Object?>? arguments) {
    print('MessagesRead event received: $arguments');
    if (arguments != null && arguments.length >= 2) {
      int chatId = arguments[0] as int;
      int readerUserId = arguments[1] as int;

      if (chatId == widget.chatId && readerUserId == widget.recipientUserId) {
        setState(() {
          messages = messages.map((message) {
            if (message.senderId == widget.currentUserId && message.readAt == null) {
              return message.copyWith(readAt: DateTime.now());
            }
            return message;
          }).toList();
        });
      }
    }
  }

  // Handle sending a text message
  void _handleSendMessage(String messageContent) async {
    try {
      await _signalRService.hubConnection.invoke('SendMessage', args: [
        widget.recipientUserId,
        messageContent,
        'text', // Message type
        null, // Media URLs if any
      ]);
      print('Text message sent successfully');
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  // Handle editing a message
  void _handleEditMessage(int messageId, String newContent) async {
    try {
      await _signalRService.editMessage(messageId, newContent);
      print('Edit message request sent');
    } catch (e) {
      print('Error editing message: $e');
    }
  }

  // Handle deleting a message for all
  void _handleDeleteForAll(int messageId) async {
    try {
      await _signalRService.unsendMessage(messageId);
      print('Delete for all request sent');
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

Future<void> _handleSendMediaMessage(File mediaFile, String mediaType) async {
  setState(() {
    _isUploadingMedia = true;
    _uploadProgress = 0.0;
  });

  try {
    final fileName = mediaFile.path.split('/').last;
    final presignedUrls = await _s3UploadService.getPresignedUrls([fileName]);

    final mediaUrl = await _s3UploadService.uploadFile(
      presignedUrls[0],
      XFile(mediaFile.path), // Convert to XFile for compatibility
      onProgress: (progress) {
        setState(() {
          _uploadProgress = progress;
        });
      },
    );

    await _signalRService.hubConnection.invoke('SendMessage', args: [
      widget.recipientUserId,
      mediaUrl,
      mediaType,
      null,
    ]);

    print('$mediaType message sent successfully with URL: $mediaUrl');
    _scrollToBottom();  // <-- Scroll to the bottom after sending media
  } catch (e) {
    print('Error sending media message: $e');
  } finally {
    setState(() {
      _isUploadingMedia = false;
    });
  }
}


  // Handle typing event
  void _handleTyping() {
    _signalRService.sendTypingNotification(widget.recipientUserId);
  }

  void _handleTypingStopped() {
    // Optionally implement if you need to notify when typing has stopped
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
    _signalRService.hubConnection.off('ReceiveMessage', method: _handleReceiveMessage);
    _signalRService.hubConnection.off('MessageSent', method: _handleMessageSent);
    _signalRService.hubConnection.off('MessageEdited', method: _handleMessageEdited);
    _signalRService.hubConnection.off('MessageUnsent', method: _handleMessageUnsent);
    _signalRService.hubConnection.off('UserTyping', method: _handleUserTyping);
    _signalRService.hubConnection.off('MessagesRead', method: _handleMessagesRead);
    _scrollController.dispose();
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
        status: _status,
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
                              readAt: message.readAt,
                              message: message.isUnsent
                                  ? 'This message was deleted'
                                  : message.messageContent,
                              timestamp: message.createdAt,
                              isSeen: message.readAt != null,
                              isEdited: message.isEdited,
                              isUnsent: message.isUnsent,
                              messageType: message.messageType, // Specify message type here
                              onEdit: (newText) {
                                _handleEditMessage(message.messageId, newText);
                              },
                              onDeleteForAll: () {
                                _handleDeleteForAll(message.messageId);
                              },
                              onDeleteForMe: () {
                                // Implement 'Delete for Me' if needed
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
         if (_isUploadingMedia)
  Center(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircularProgressIndicator(
        value: _uploadProgress / 100,
        color: Theme.of(context).primaryColor,
      ),
    ),
  ),

          MessageInput(
            onSendMessage: _handleSendMessage,
            onTyping: () => _signalRService.sendTypingNotification(widget.recipientUserId),
            onTypingStopped: () {}, // Optional typing stopped handler
            onSendMediaMessage: (file, type) => _handleSendMediaMessage(File(file.path), type), // Updated to accept File
          ),
        ],
      ),
    );
  }
}
