// chat_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_controller.dart';
import 'message_input.dart';
import 'message_list.dart';
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
  late ChatController _chatController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chatController = ChatController(
      chatId: widget.chatId,
      currentUserId: widget.currentUserId,
      recipientUserId: widget.recipientUserId,
      isOnline: widget.isOnline,
    );

    _scrollController.addListener(() {
      if (_scrollController.position.pixels <=
              _scrollController.position.minScrollExtent + 100 &&
          !_chatController.isLoading &&
          !_chatController.isFetchingMore &&
          _chatController.hasMoreMessages) {
        _chatController.fetchMessages(loadMore: true);
      }
    });

    // Scroll to bottom after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _chatController.disposeController();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isNewDay(int index) {
    if (index == 0) return true;
    DateTime currentMessageDate = _chatController.messages[index].createdAt;
    DateTime previousMessageDate = _chatController.messages[index - 1].createdAt;
    return currentMessageDate.day != previousMessageDate.day ||
        currentMessageDate.month != previousMessageDate.month ||
        currentMessageDate.year != previousMessageDate.year;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _chatController.messages.isNotEmpty) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatController>.value(
      value: _chatController,
      child: Scaffold(
        appBar: ChatAppBar(
          username: widget.contactName,
          profileImageUrl: widget.profileImageUrl,
          status:
              _chatController.isRecipientTyping ? 'Typing...' : _chatController.status,
        ),
        body: Column(
          children: [
            Expanded(
              child: Consumer<ChatController>(
                builder: (context, controller, child) {
                  if (controller.isLoading && controller.messages.isEmpty) {
                    return Center(child: CircularProgressIndicator());
                  } else {
                    return NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.maxScrollExtent) {
                          // Scrolled to the bottom
                          // Optionally, perform an action
                        }
                        return false;
                      },
                      child: MessageList(
                        messages: controller.messages,
                        currentUserId: widget.currentUserId,
                        scrollController: _scrollController,
                        isNewDay: _isNewDay,
                        onEditMessage: (messageId, newContent) {
                          controller.editMessage(messageId, newContent);
                        },
                        onDeleteForAll: (messageId) {
                          controller.deleteForAll(messageId);
                        },
                      ),
                    );
                  }
                },
              ),
            ),
            Consumer<ChatController>(
              builder: (context, controller, child) {
                if (controller.isUploadingMedia) {
                  return LinearProgressIndicator(value: controller.uploadProgress);
                } else {
                  return SizedBox.shrink();
                }
              },
            ),
            MessageInput(
              onSendMessage: (messageContent) {
                _chatController.sendMessage(messageContent);
                _scrollToBottom();
              },
              onTyping: () {
                _chatController.sendTypingNotification();
              },
              onTypingStopped: () {
                // Optional: Implement if needed
              },
              onSendMediaMessage: (mediaFiles, mediaType) {
                _chatController.sendMediaMessage(mediaFiles, mediaType);
                _scrollToBottom();
              },
            ),
          ],
        ),
      ),
    );
  }
}
