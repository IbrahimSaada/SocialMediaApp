// message_list.dart

import 'package:flutter/material.dart';
import 'package:cook/models/message_model.dart';
import 'message_bubble.dart';

class MessageList extends StatelessWidget {
  final List<Message> messages;
  final int currentUserId;
  final ScrollController scrollController;
  final bool Function(int index) isNewDay;
  final Function(int messageId, String newContent) onEditMessage;
  final Function(int messageId) onDeleteForAll;

  MessageList({
    required this.messages,
    required this.currentUserId,
    required this.scrollController,
    required this.isNewDay,
    required this.onEditMessage,
    required this.onDeleteForAll,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      reverse: false, // Ensures the list is displayed in backend-provided order
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];

        if (message.isLoadingMessage) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final isSender = message.senderId == currentUserId;
        final showDate = isNewDay(index);

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
                message: message.isUnsent ? 'This message was deleted' : message.messageContent,
                timestamp: message.createdAt,
                isSeen: message.readAt != null,
                isEdited: message.isEdited,
                isUnsent: message.isUnsent,
                messageType: message.messageType,
                mediaItems: message.mediaItems,
                onEdit: (newText) {
                  onEditMessage(message.messageId, newText);
                },
                onDeleteForAll: () {
                  onDeleteForAll(message.messageId);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
