// chat_controller.dart

import 'package:flutter/material.dart';
import 'package:cook/services/chat_service.dart';
import 'package:cook/models/message_model.dart';
import 'package:cook/models/media_model.dart';
import 'package:cook/services/signalr_service.dart';
import 'package:cook/services/s3_upload_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';

class ChatController extends ChangeNotifier {
  final int chatId;
  final int currentUserId;
  final int recipientUserId;
  final bool isOnline;

  final ChatService _chatService = ChatService();
  final SignalRService _signalRService = SignalRService();
  final S3UploadService _s3UploadService = S3UploadService();

  List<Message> messages = [];
  bool isLoading = true;
  bool isRecipientTyping = false;
  String status = '';
  bool isUploadingMedia = false;
  double uploadProgress = 0.0;
  List<MediaItem> uploadingMediaItems = [];

  int _currentPage = 1;
  final int _pageSize = 20;
  bool _isFetchingMore = false;
  bool _hasMoreMessages = true;

  // Add public getters
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMoreMessages => _hasMoreMessages;

  Timer? _typingTimer;

  ChatController({
    required this.chatId,
    required this.currentUserId,
    required this.recipientUserId,
    required this.isOnline,
  }) {
    status = isOnline ? 'Online' : 'Offline';
    _init();
  }

  Future<void> _init() async {
    await _initSignalR();
    await fetchMessages();
    // Mark messages as read when the chat is opened
    _signalRService.markMessagesAsRead(chatId);
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
    } catch (e) {
      print('Error initializing SignalR: $e');
    }
  }

Future<void> fetchMessages({bool loadMore = false}) async {
  if (_isFetchingMore) return; // Prevent overlapping fetches
  _isFetchingMore = true;

  try {
    if (!loadMore) {
      // Reset for initial load
      _currentPage = 1;
      _hasMoreMessages = true;
    }

    print("Fetching messages for page $_currentPage");

    // Fetch messages from the backend
    var result = await _signalRService.fetchMessages(chatId, _currentPage, _pageSize);

    if (result == null) {
      print("Error: No data returned from fetchMessages.");
      isLoading = false;
      notifyListeners();
      return;
    }

    // Convert the fetched data into a list of Message objects
    List<Message> fetchedMessages = result.map((data) => Message.fromJson(data)).toList();
    print("Fetched ${fetchedMessages.length} messages");

    // Reverse the fetched messages to have oldest messages first
    fetchedMessages = fetchedMessages.reversed.toList();

    if (loadMore) {
      messages.insertAll(0, fetchedMessages); // Add new messages at the top
    } else {
      messages = fetchedMessages; // Initial load replaces messages
    }

    isLoading = false; // Hide any initial loading spinner
    _currentPage++;
    _hasMoreMessages = fetchedMessages.length >= _pageSize; // Check if there are more messages to load
    notifyListeners();
  } catch (e) {
    print('Error fetching messages: $e');
    isLoading = false;
    notifyListeners();
  } finally {
    _isFetchingMore = false; // Allow further fetching when ready
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

      // Ensure mediaItems are parsed correctly
      if (messageData['mediaItems'] != null) {
        messageData['mediaItems'] = (messageData['mediaItems'] as List)
            .map((item) => MediaItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } else if (messageData['mediaUrls'] != null) {
        // Handle mediaUrls if mediaItems is null
        messageData['mediaItems'] = (messageData['mediaUrls'] as List)
            .map((url) => MediaItem(mediaUrl: url as String, mediaType: 'photo'))
            .toList();
      }

      final message = Message.fromJson(messageData);

      print('Parsed Message in ReceiveMessage: $message');

      if (message.chatId == chatId) {
        messages.add(message);
        print('Message added to list: ${message.messageContent}');
        isRecipientTyping = false;
        status = isOnline ? 'Online' : 'Offline';
        notifyListeners();
      } else {
        print('Received message for a different chat: ${message.chatId}');
      }
    }
    _signalRService.markMessagesAsRead(chatId);
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

      // Ensure mediaItems are parsed correctly
      if (messageData['mediaItems'] != null) {
        messageData['mediaItems'] = (messageData['mediaItems'] as List)
            .map((item) => MediaItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } else if (messageData['mediaUrls'] != null) {
        // Handle mediaUrls if mediaItems is null
        messageData['mediaItems'] = (messageData['mediaUrls'] as List)
            .map((url) => MediaItem(mediaUrl: url as String, mediaType: 'photo'))
            .toList();
      }

      final message = Message.fromJson(messageData);

      print('Parsed Message in MessageSent: $message');

      if (message.chatId == chatId) {
        // Remove the placeholder uploading message
        messages.removeWhere((msg) => msg.messageId == -1);

        messages.add(message);
        print('Message added to list: ${message.messageContent}');
        print('Total messages in list: ${messages.length}');
        notifyListeners();
      } else {
        print('MessageSent event for different chat');
      }
    }
  }

  void _handleUserTyping(List<Object?>? arguments) {
    print('UserTyping event received: $arguments');
    if (arguments != null && arguments.isNotEmpty) {
      int senderId = arguments[0] as int;
      if (senderId == recipientUserId) {
        isRecipientTyping = true;
        status = 'Typing...';
        _resetTypingTimer();
        notifyListeners();
      }
    }
  }

  void _resetTypingTimer() {
    _typingTimer?.cancel();
    _typingTimer = Timer(Duration(seconds: 3), () {
      isRecipientTyping = false;
      status = isOnline ? 'Online' : 'Offline';
      notifyListeners();
    });
  }

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

      // Ensure mediaItems are parsed correctly
      if (messageData['mediaItems'] != null) {
        messageData['mediaItems'] = (messageData['mediaItems'] as List)
            .map((item) => MediaItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } else if (messageData['mediaUrls'] != null) {
        // Handle mediaUrls if mediaItems is null
        messageData['mediaItems'] = (messageData['mediaUrls'] as List)
            .map((url) => MediaItem(mediaUrl: url as String, mediaType: 'photo'))
            .toList();
      }

      final editedMessage = Message.fromJson(messageData);

      print('Parsed edited Message: $editedMessage');

      if (editedMessage.chatId == chatId) {
        // Find the message in the messages list and update it
        int index = messages.indexWhere((msg) => msg.messageId == editedMessage.messageId);
        if (index != -1) {
          messages[index] = editedMessage;
          print('Message updated in list: ${editedMessage.messageContent}');
          notifyListeners();
        }
      } else {
        print('Edited message belongs to a different chat: ${editedMessage.chatId}');
      }
    }
  }

  void _handleMessageUnsent(List<Object?>? arguments) {
    print('MessageUnsent event received: $arguments');
    if (arguments != null && arguments.isNotEmpty) {
      int messageId = arguments[0] as int;

      int index = messages.indexWhere((msg) => msg.messageId == messageId);
      if (index != -1) {
        // Mark the message as unsent
        messages[index] = messages[index].copyWith(
          isUnsent: true,
          messageContent: 'This message was deleted',
          mediaItems: [], // Clear media items
        );
        print('Message marked as unsent: $messageId');
        notifyListeners();
      }
    }
  }

  void _handleMessagesRead(List<Object?>? arguments) {
    print('MessagesRead event received: $arguments');
    if (arguments != null && arguments.length >= 2) {
      int chatIdFromEvent = arguments[0] as int;
      int readerUserId = arguments[1] as int;

      if (chatIdFromEvent == chatId && readerUserId == recipientUserId) {
        messages = messages.map((message) {
          if (message.senderId == currentUserId && message.readAt == null) {
            return message.copyWith(readAt: DateTime.now());
          }
          return message;
        }).toList();
        notifyListeners();
      }
    }
  }

  void sendMessage(String messageContent) async {
    try {
      await _signalRService.hubConnection.invoke('SendMessage', args: [
        recipientUserId,
        messageContent,
        'text', // Message type
        null, // Media items if any
      ]);
      print('Text message sent successfully');
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> sendMediaMessage(List<XFile> mediaFiles, String mediaType) async {
    isUploadingMedia = true;
    uploadProgress = 0.0;
    notifyListeners();

    try {
      if (mediaFiles.length <= 3) {
        // Send each media file as a separate message
        for (XFile mediaFile in mediaFiles) {
          await _sendSingleMediaMessage(mediaFile);
        }
      } else {
        // If more than 3 media files, send them as a single message
        await _sendMultipleMediaMessage(mediaFiles);
      }
    } catch (e) {
      print('Error sending media message: $e');
    } finally {
      isUploadingMedia = false;
      uploadingMediaItems = [];
      notifyListeners();
    }
  }

  Future<void> _sendSingleMediaMessage(XFile mediaFile) async {
    // Placeholder message to show uploading status
    messages.add(
      Message(
        messageId: -1, // Temporary ID
        chatId: chatId,
        senderId: currentUserId,
        messageType: 'media',
        messageContent: '',
        createdAt: DateTime.now(),
        isEdited: false,
        isUnsent: false,
        mediaItems: [
          MediaItem(
            mediaUrl: '', // Placeholder URL until upload completes
            mediaType: getMediaType(mediaFile.path),
          ),
        ],
      ),
    );
    notifyListeners();

    try {
      // Presigned URL logic for uploading to S3
      final fileName = mediaFile.path.split('/').last;
      final presignedUrls = await _s3UploadService.getPresignedUrls([fileName]);

      final mediaUrl = await _s3UploadService.uploadFile(
        presignedUrls.first,
        mediaFile,
        onProgress: (progress) {
          uploadProgress = progress;
          notifyListeners();
        },
      );

      // Update the message with the actual media URL
      await _signalRService.hubConnection.invoke('SendMessage', args: [
        recipientUserId,
        '', // Empty content for media
        'media',
        [
          {
            'mediaUrl': mediaUrl,
            'mediaType': getMediaType(mediaFile.path),
          }
        ],
      ]);

      // Remove placeholder and add the actual message with media URL
      messages.removeWhere((msg) => msg.messageId == -1);
      messages.add(
        Message(
          messageId: DateTime.now().millisecondsSinceEpoch, // Temp ID, replace with server ID if available
          chatId: chatId,
          senderId: currentUserId,
          messageType: 'media',
          messageContent: '',
          createdAt: DateTime.now(),
          isEdited: false,
          isUnsent: false,
          mediaItems: [
            MediaItem(mediaUrl: mediaUrl, mediaType: getMediaType(mediaFile.path)),
          ],
        ),
      );
      notifyListeners();
    } catch (e) {
      print('Error sending single media message: $e');
      messages.removeWhere((msg) => msg.messageId == -1);
      notifyListeners();
    }
  }

  Future<void> _sendMultipleMediaMessage(List<XFile> mediaFiles) async {
    // Temporary placeholder for multiple media items
    uploadingMediaItems = mediaFiles
        .map((file) => MediaItem(mediaUrl: '', mediaType: getMediaType(file.path)))
        .toList();
    messages.add(
      Message(
        messageId: -1,
        chatId: chatId,
        senderId: currentUserId,
        messageType: 'media',
        messageContent: '',
        createdAt: DateTime.now(),
        isEdited: false,
        isUnsent: false,
        mediaItems: uploadingMediaItems,
      ),
    );
    notifyListeners();

    try {
      final fileNames = mediaFiles.map((file) => file.path.split('/').last).toList();
      final presignedUrls = await _s3UploadService.getPresignedUrls(fileNames);

      List<String> mediaUrls = [];
      for (int i = 0; i < mediaFiles.length; i++) {
        final file = mediaFiles[i];
        final url = await _s3UploadService.uploadFile(
          presignedUrls[i],
          file,
          onProgress: (progress) {
            uploadProgress = progress;
            notifyListeners();
          },
        );
        mediaUrls.add(url);
      }

      await _signalRService.hubConnection.invoke('SendMessage', args: [
        recipientUserId,
        '',
        'media',
        mediaUrls.map((url) => {'mediaUrl': url, 'mediaType': getMediaType(mediaFiles.first.path)}).toList(),
      ]);

      messages.removeWhere((msg) => msg.messageId == -1);
      messages.add(
        Message(
          messageId: DateTime.now().millisecondsSinceEpoch,
          chatId: chatId,
          senderId: currentUserId,
          messageType: 'media',
          messageContent: '',
          createdAt: DateTime.now(),
          isEdited: false,
          isUnsent: false,
          mediaItems: mediaUrls
              .map((url) => MediaItem(mediaUrl: url, mediaType: getMediaType(mediaFiles.first.path)))
              .toList(),
        ),
      );
      notifyListeners();
    } catch (e) {
      print('Error sending multiple media message: $e');
      messages.removeWhere((msg) => msg.messageId == -1);
      notifyListeners();
    }
  }

  void editMessage(int messageId, String newContent) async {
    try {
      await _signalRService.editMessage(messageId, newContent);
      print('Edit message request sent');

      // Update the message locally
      int index = messages.indexWhere((msg) => msg.messageId == messageId);
      if (index != -1) {
        messages[index] = messages[index].copyWith(
          messageContent: newContent,
          isEdited: true,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error editing message: $e');
    }
  }

  void deleteForAll(int messageId) async {
    try {
      await _signalRService.unsendMessage(messageId);
      print('Delete for all request sent');
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  void sendTypingNotification() {
    _signalRService.sendTypingNotification(recipientUserId);
  }

  void disposeController() {
    _signalRService.hubConnection.off('ReceiveMessage', method: _handleReceiveMessage);
    _signalRService.hubConnection.off('MessageSent', method: _handleMessageSent);
    _signalRService.hubConnection.off('MessageEdited', method: _handleMessageEdited);
    _signalRService.hubConnection.off('MessageUnsent', method: _handleMessageUnsent);
    _signalRService.hubConnection.off('UserTyping', method: _handleUserTyping);
    _signalRService.hubConnection.off('MessagesRead', method: _handleMessagesRead);
    _typingTimer?.cancel();
  }
}

// Helper function to get media type
String getMediaType(String filePath) {
  final extension = filePath.split('.').last.toLowerCase();
  if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
    return 'photo';
  } else if (['mp4', 'mov', 'wmv', 'avi', 'mkv', 'flv', 'webm'].contains(extension)) {
    return 'video';
  } else {
    return 'unknown';
  }
}
