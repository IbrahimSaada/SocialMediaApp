// chat_page.dart

import 'package:flutter/material.dart';
import 'package:cook/services/chat_service.dart';
import 'package:cook/models/message_model.dart';
import 'package:cook/services/signalr_service.dart';
import 'message_input.dart';
import 'message_bubble.dart';
import 'chat_app_bar.dart';
import 'dart:async';

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

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final ChatService _chatService = ChatService();
  final SignalRService _signalRService = SignalRService();
  List<Message> messages = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  bool _isRecipientTyping = false;
  Timer? _typingTimer;
  String _status = '';

  int _currentPage = 1;
  final int _pageSize = 20;
  bool _isFetchingMore = false;
  bool _hasMoreMessages = true;
  bool _shouldScrollToBottom = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _status = widget.isOnline ? 'Online' : 'Offline';
    _initSignalR();

_scrollController.addListener(() {
  if (_scrollController.position.atEdge &&
      _scrollController.position.pixels == _scrollController.position.minScrollExtent &&
      !_isLoading &&
      _hasMoreMessages &&
      !_isFetchingMore) {
    _fetchMessages(loadMore: true);
  }
});

  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _signalRService.hubConnection.off('ReceiveMessage', method: _handleReceiveMessage);
    _signalRService.hubConnection.off('MessageSent', method: _handleMessageSent);
    _signalRService.hubConnection.off('MessageEdited', method: _handleMessageEdited);
    _signalRService.hubConnection.off('MessageUnsent', method: _handleMessageUnsent);
    _signalRService.hubConnection.off('UserTyping', method: _handleUserTyping);
    _signalRService.hubConnection.off('MessagesRead', method: _handleMessagesRead);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
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

      // Fetch messages via SignalR
      await _fetchMessages();

      // Mark messages as read when the chat is opened
      _signalRService.markMessagesAsRead(widget.chatId);
    } catch (e) {
      print('Error initializing SignalR: $e');
    }
  }

Future<void> _fetchMessages({bool loadMore = false}) async {
  if (_isFetchingMore) return;
  _isFetchingMore = true;

  try {
    if (!loadMore) {
      _currentPage = 1;
      _hasMoreMessages = true;
    }

    var result = await _signalRService.hubConnection.invoke('FetchMessages',
        args: [widget.chatId, _currentPage, _pageSize]);

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

    // Reverse fetched messages if needed
    fetchedMessages = fetchedMessages.reversed.toList();

    if (loadMore) {
      double prevScrollHeight = _scrollController.position.extentAfter;
      double prevScrollOffset = _scrollController.offset;

      setState(() {
        messages.insertAll(0, fetchedMessages); // Insert at the beginning
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _isLoading = false;
        _currentPage++;
        if (fetchedMessages.length < _pageSize) {
          _hasMoreMessages = false;
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        double newScrollHeight = _scrollController.position.extentAfter;
        double scrollOffsetDelta = newScrollHeight - prevScrollHeight;
        _scrollController.jumpTo(prevScrollOffset + scrollOffsetDelta);
      });
    } else {
      setState(() {
        messages = fetchedMessages;
        _isLoading = false;
        _currentPage++;
        if (fetchedMessages.length < _pageSize) {
          _hasMoreMessages = false;
        }
      });

      // Scroll to the bottom (latest message) on initial load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _shouldScrollToBottom = true;
        _scrollToBottom();
      });
    }
  } catch (e) {
    print('Error fetching messages via SignalR: $e');
    setState(() {
      _isLoading = false;
    });
  } finally {
    _isFetchingMore = false;
  }
}



  void _handleReceiveMessage(List<Object?>? arguments) {
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

      if (message.chatId == widget.chatId) {
        setState(() {
          messages.add(message); // Add new message
          // Sort messages by createdAt
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          _isRecipientTyping = false;
          _status = widget.isOnline ? 'Online' : 'Offline';
        });

        _scrollToBottom();
      }
    }
    _signalRService.markMessagesAsRead(widget.chatId);
  }

  void _handleMessageSent(List<Object?>? arguments) {
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

      if (message.chatId == widget.chatId) {
        setState(() {
          messages.add(message); // Add new message
          // Sort messages by createdAt
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        });
        _scrollToBottom();
      }
    }
  }

  void _handleUserTyping(List<Object?>? arguments) {
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

  void _handleMessageEdited(List<Object?>? arguments) {
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

      if (editedMessage.chatId == widget.chatId) {
        // Find the message in the messages list and update it
        setState(() {
          int index = messages.indexWhere((msg) => msg.messageId == editedMessage.messageId);
          if (index != -1) {
            messages[index] = editedMessage;
          }
        });
      }
    }
  }

  void _handleMessageUnsent(List<Object?>? arguments) {
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
        }
      });
    }
  }

  void _handleMessagesRead(List<Object?>? arguments) {
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

void _handleSendMessage(String messageContent) async {
  try {
    await _signalRService.hubConnection.invoke('SendMessage', args: [
      widget.recipientUserId,
      messageContent,
      'text', // Message type
      null, // Media items if any
    ]);

    // Set the flag and scroll to the bottom
    setState(() {
      _shouldScrollToBottom = true;
    });
    _scrollToBottom();

  } catch (e) {
    print('Error sending message: $e');
  }
}



void _handleEditMessage(int messageId, String newContent) async {
  try {
    await _signalRService.editMessage(messageId, newContent);

    // Update the message locally
    setState(() {
      int index = messages.indexWhere((msg) => msg.messageId == messageId);
      if (index != -1) {
        messages[index] = messages[index].copyWith(
          messageContent: newContent,
          isEdited: true,
        );
      }
    });

    // Do not call _scrollToBottom() here
  } catch (e) {
    print('Error editing message: $e');
  }
}


  void _handleDeleteForAll(int messageId) async {
    try {
      await _signalRService.unsendMessage(messageId);
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  void _handleTyping() {
    _signalRService.sendTypingNotification(widget.recipientUserId);
  }

  void _handleTypingStopped() {
    // Optionally implement if you need to notify when typing has stopped
  }

  // Scroll to the last message
void _scrollToBottom() {
  if (_shouldScrollToBottom) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
      // Reset the flag after scrolling
      _shouldScrollToBottom = false;
    });
  }
}


  // Determine if a new day has started
  bool _isNewDay(int index) {
    if (index == 0) return true;
    DateTime currentMessageDate = messages[index].createdAt;
    DateTime previousMessageDate = messages[index - 1].createdAt;
    return currentMessageDate.day != previousMessageDate.day ||
        currentMessageDate.month != previousMessageDate.month ||
        currentMessageDate.year != previousMessageDate.year;
  }

  // Format date for message separator
  String _formatDate(DateTime date) {
    // Custom date formatting logic, adjust as needed
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(
        username: widget.contactName,
        profileImageUrl: widget.profileImageUrl,
        status: _isRecipientTyping ? 'Typing...' : _status,
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: false, // Messages from top (oldest) to bottom (newest)
                        itemCount: messages.length + (_hasMoreMessages ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_hasMoreMessages && index == 0) {
                            // Show loading spinner at the top when more messages are available
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final actualIndex = _hasMoreMessages ? index - 1 : index;
                          if (actualIndex < 0 || actualIndex >= messages.length) {
                            return SizedBox.shrink();
                          }

                          final message = messages[actualIndex];
                          final isSender = message.senderId == widget.currentUserId;
                          final showDate = _isNewDay(actualIndex);

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
                                  messageType: message.messageType,
                                  onEdit: (newText) {
                                    _handleEditMessage(message.messageId, newText);
                                  },
                                  onDeleteForAll: () {
                                    _handleDeleteForAll(message.messageId);
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
                onTyping: () => _signalRService.sendTypingNotification(widget.recipientUserId),
                onTypingStopped: () {}, // Optional typing stopped handler
              ),
            ],
          ),
        ),
      ),
    );
  }
}
