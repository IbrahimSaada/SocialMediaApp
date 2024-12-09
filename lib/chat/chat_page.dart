import 'package:flutter/material.dart';
import 'package:cook/services/chat_service.dart';
import 'package:cook/models/message_model.dart';
import 'package:cook/services/signalr_service.dart';
import 'package:cook/chat/message_input.dart';
import 'package:cook/chat/message_bubble.dart';
import 'package:cook/chat/chat_app_bar.dart';
import 'dart:async';
import 'dart:convert';
import 'package:cook/profile/otheruserprofilepage.dart';
import 'package:cook/services/crypto/key_exchange_service.dart';
import 'package:cook/services/crypto/encryption_service.dart';
import 'package:cook/services/crypto/key_manager.dart' show UserKeyPair;
import 'package:cryptography/cryptography.dart';

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
  SessionKeys? _sessionKeys;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _status = widget.isOnline ? 'Online' : 'Offline';
    _initE2EE().then((_) {
      _initSignalR();
    });

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

  Future<void> _initE2EE() async {
    print('Initializing E2EE...');
    final myKeyPair = await _loadMyUserKeyPair();
    print('My private key length: ${myKeyPair.privateKey.length}, public key length: ${myKeyPair.publicKey.length}');

    final recipientPublicKey = await _fetchRecipientPublicKeyFromServer(widget.recipientUserId);
    print('Recipient public key length: ${recipientPublicKey.length}');

    final keyExchangeService = KeyExchangeService();
    final sharedSecret = await keyExchangeService.deriveSharedSecret(
      ourPrivateKey: myKeyPair.privateKey,
      theirPublicKey: recipientPublicKey,
    );

    print('Derived shared secret: $sharedSecret');
    print('Derived shared secret length: ${sharedSecret.length}');

    if (sharedSecret.isEmpty) {
      print('Shared secret is empty! Cannot derive session keys.');
      return;
    }

    final sessionKeys = await keyExchangeService.deriveSessionKeys(sharedSecret);

    print('Session keys derived. EncryptionKey length: ${sessionKeys.encryptionKey.length}, macKey length: ${sessionKeys.macKey.length}');

    setState(() {
      _sessionKeys = sessionKeys;
    });
  }

  Future<void> _initSignalR() async {
    try {
      print('Initializing SignalR...');
      await _signalRService.initSignalR();

      _signalRService.hubConnection.on('ReceiveMessage', _handleReceiveMessage);
      _signalRService.hubConnection.on('MessageSent', _handleMessageSent);
      _signalRService.hubConnection.on('MessageEdited', _handleMessageEdited);
      _signalRService.hubConnection.on('MessageUnsent', _handleMessageUnsent);
      _signalRService.hubConnection.on('UserTyping', _handleUserTyping);
      _signalRService.hubConnection.on('MessagesRead', _handleMessagesRead);

      await _fetchMessages();
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

      print('Fetching messages, page=$_currentPage, pageSize=$_pageSize');
      var result = await _signalRService.hubConnection.invoke('FetchMessages',
          args: [widget.chatId, _currentPage, _pageSize]);

      List<dynamic> messagesData = result as List<dynamic>;
      List<Message> fetchedMessages = [];
      for (var messageData in messagesData) {
        try {
          Map<String, dynamic> messageMap = Map<String, dynamic>.from(messageData);
          var message = Message.fromJson(messageMap);

          if (_sessionKeys != null && message.messageContent.isNotEmpty) {
            try {
              final encryptionService = EncryptionService();
              final ciphertext = base64Decode(message.messageContent);
              final decrypted = await encryptionService.decryptMessage(
                encryptionKey: _sessionKeys!.encryptionKey,
                ciphertext: ciphertext,
              );
              final decryptedText = utf8.decode(decrypted);
              message = message.copyWith(messageContent: decryptedText);
            } catch (e) {
              print('Error decrypting fetched message: $e');
            }
          }

          fetchedMessages.add(message);
        } catch (e) {
          print('Error parsing message: $e');
          print('Message data: $messageData');
        }
      }

      fetchedMessages = fetchedMessages.reversed.toList();

      setState(() {
        if (loadMore) {
          print('Inserting fetched messages at the beginning...');
          double prevScrollHeight = _scrollController.position.extentAfter;
          double prevScrollOffset = _scrollController.offset;
          messages.insertAll(0, fetchedMessages);
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          _isLoading = false;
          _currentPage++;
          if (fetchedMessages.length < _pageSize) {
            _hasMoreMessages = false;
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            double newScrollHeight = _scrollController.position.extentAfter;
            double scrollOffsetDelta = newScrollHeight - prevScrollHeight;
            _scrollController.jumpTo(prevScrollOffset + scrollOffsetDelta);
          });
        } else {
          messages = fetchedMessages;
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          _isLoading = false;
          _currentPage++;
          if (fetchedMessages.length < _pageSize) {
            _hasMoreMessages = false;
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _shouldScrollToBottom = true;
            _scrollToBottom();
          });
        }
      });
    } catch (e) {
      print('Error fetching messages via SignalR: $e');
      setState(() {
        _isLoading = false;
      });
    } finally {
      _isFetchingMore = false;
    }
  }

  void _handleReceiveMessage(List<Object?>? arguments) async {
    if (arguments != null && arguments.isNotEmpty) {
      final messageData = Map<String, dynamic>.from(arguments[0] as Map);

      if (messageData['createdAt'] is String) {
        messageData['createdAt'] = DateTime.parse(messageData['createdAt']);
      }
      if (messageData['readAt'] != null && messageData['readAt'] is String) {
        messageData['readAt'] = DateTime.parse(messageData['readAt']);
      }

      var message = Message.fromJson(messageData);

      if (message.chatId == widget.chatId) {
        if (_sessionKeys != null && message.messageContent.isNotEmpty) {
          try {
            // Decrypt message content
            final ciphertext = base64Decode(message.messageContent);
            final encryptionService = EncryptionService();
            final decryptedBytes = await encryptionService.decryptMessage(
              encryptionKey: _sessionKeys!.encryptionKey,
              ciphertext: ciphertext,
            );
            final decryptedText = utf8.decode(decryptedBytes);
            message = message.copyWith(messageContent: decryptedText);
          } catch (e) {
            print('Error decrypting message: $e');
            message = message.copyWith(messageContent: 'Could not decrypt this message.');
          }
        }

        setState(() {
          messages.add(message);
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        });

        _shouldScrollToBottom = true;
        _scrollToBottom();
      }
    }
    _signalRService.markMessagesAsRead(widget.chatId);
  }

  void _handleMessageSent(List<Object?>? arguments) async {
    if (arguments != null && arguments.isNotEmpty) {
      final Map<String, dynamic> messageData = Map<String, dynamic>.from(arguments[0] as Map);

      if (messageData['createdAt'] is String) {
        messageData['createdAt'] = DateTime.parse(messageData['createdAt']);
      }
      if (messageData['readAt'] != null && messageData['readAt'] is String) {
        messageData['readAt'] = DateTime.parse(messageData['readAt']);
      }

      var message = Message.fromJson(messageData);

      if (message.chatId == widget.chatId) {
        if (_sessionKeys != null && message.messageContent.isNotEmpty) {
          try {
            final encryptionService = EncryptionService();
            final ciphertext = base64Decode(message.messageContent);
            final decrypted = await encryptionService.decryptMessage(
              encryptionKey: _sessionKeys!.encryptionKey,
              ciphertext: ciphertext,
            );
            final decryptedText = utf8.decode(decrypted);
            message = message.copyWith(messageContent: decryptedText);
          } catch (e) {
            print('Error decrypting received sent message: $e');
          }
        }

        setState(() {
          messages.add(message);
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        });
        _shouldScrollToBottom = true;
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

  Future<void> _handleMessageEdited(List<Object?>? arguments) async {
    if (arguments != null && arguments.isNotEmpty) {
      final messageData = Map<String, dynamic>.from(arguments[0] as Map);

      if (messageData['createdAt'] is String) {
        messageData['createdAt'] = DateTime.parse(messageData['createdAt']);
      }
      if (messageData['readAt'] != null && messageData['readAt'] is String) {
        messageData['readAt'] = DateTime.parse(messageData['readAt']);
      }

      var editedMessage = Message.fromJson(messageData);

      if (_sessionKeys != null && editedMessage.messageContent.isNotEmpty) {
        try {
          final encryptionService = EncryptionService();
          final ciphertext = base64Decode(editedMessage.messageContent);
          final decrypted = await encryptionService.decryptMessage(
            encryptionKey: _sessionKeys!.encryptionKey,
            ciphertext: ciphertext,
          );
          final decryptedText = utf8.decode(decrypted);
          editedMessage = editedMessage.copyWith(messageContent: decryptedText);
        } catch (e) {
          print('Error decrypting edited message: $e');
        }
      }

      if (editedMessage.chatId == widget.chatId) {
        setState(() {
          int index = messages.indexWhere((msg) => msg.messageId == editedMessage.messageId);
          if (index != -1) {
            messages[index] = editedMessage;
          }
        });
      }
    }
    FocusScope.of(context).unfocus();
  }

  void _handleMessageUnsent(List<Object?>? arguments) {
    if (arguments != null && arguments.isNotEmpty) {
      int messageId = arguments[0] as int;

      setState(() {
        int index = messages.indexWhere((msg) => msg.messageId == messageId);
        if (index != -1) {
          messages[index] = messages[index].copyWith(
            isUnsent: true,
            messageContent: 'This message was deleted',
          );
        }
      });

      FocusScope.of(context).unfocus();
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
      if (_sessionKeys == null) {
        print('No session keys available. Cannot encrypt message.');
        return;
      }

      final encryptionService = EncryptionService();
      final plaintext = utf8.encode(messageContent);
      final ciphertext = await encryptionService.encryptMessage(
        encryptionKey: _sessionKeys!.encryptionKey,
        plaintext: plaintext,
      );

      final encodedCiphertext = base64Encode(ciphertext);
      print('Encrypted message to send (Base64): $encodedCiphertext');

      await _signalRService.sendMessage(
        widget.recipientUserId,
        encodedCiphertext,
        'text',
        null,
      );

      setState(() {
        _shouldScrollToBottom = true;
      });
      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  // Updated to encrypt edited messages before sending
  void _handleEditMessage(int messageId, String newContent) async {
    try {
      if (_sessionKeys == null) {
        print('No session keys available. Cannot encrypt edited message.');
        return;
      }

      // Encrypt the edited message
      final encryptionService = EncryptionService();
      final plaintext = utf8.encode(newContent);
      final ciphertext = await encryptionService.encryptMessage(
        encryptionKey: _sessionKeys!.encryptionKey,
        plaintext: plaintext,
      );
      final encodedCiphertext = base64Encode(ciphertext);

      await _signalRService.editMessage(messageId, encodedCiphertext);

      setState(() {
        int index = messages.indexWhere((msg) => msg.messageId == messageId);
        if (index != -1) {
          // Local update: message is now edited but encrypted on server.
          // The actual decrypted version will come from the 'MessageEdited' event.
          messages[index] = messages[index].copyWith(
            messageContent: newContent,
            isEdited: true,
          );
        }
      });

      FocusScope.of(context).unfocus();
    } catch (e) {
      print('Error editing message: $e');
    }
  }

  void _handleDeleteForAll(int messageId) async {
    try {
      await _signalRService.unsendMessage(messageId);
      FocusScope.of(context).unfocus();
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  void _handleTyping() {
    _signalRService.sendTypingNotification(widget.recipientUserId);
  }

  void _handleTypingStopped() {
    // Optional
  }

  void _scrollToBottom() {
    if (_shouldScrollToBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          try {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          } catch (e) {
            print('ScrollToBottom Error: $e');
          }
        }
        _shouldScrollToBottom = false;
      });
    }
  }

  bool _isNewDay(int index) {
    if (index == 0) return true;
    DateTime currentMessageDate = messages[index].createdAt;
    DateTime previousMessageDate = messages[index - 1].createdAt;
    return currentMessageDate.day != previousMessageDate.day ||
        currentMessageDate.month != previousMessageDate.month ||
        currentMessageDate.year != previousMessageDate.year;
  }

  String _formatDate(DateTime date) {
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

  Future<UserKeyPair> _loadMyUserKeyPair() async {
    print('Generating user key pair with a fixed seed for stable keys...');
    final seed = List<int>.filled(32, 1);
    final algo = X25519();
    final kp = await algo.newKeyPairFromSeed(seed);
    final privateKey = await kp.extractPrivateKeyBytes();
    final publicKey = (await kp.extractPublicKey()).bytes;
    print('Generated user key pair (stable): privateKey length=${privateKey.length}, publicKey length=${publicKey.length}');
    return UserKeyPair(privateKey: privateKey, publicKey: publicKey);
  }

  Future<List<int>> _fetchRecipientPublicKeyFromServer(int recipientUserId) async {
    print('Fetching recipient public key (mock, stable) for userId=$recipientUserId');
    final seed = List<int>.filled(32, 2);
    final algo = X25519();
    final kp = await algo.newKeyPairFromSeed(seed);
    final publicKey = (await kp.extractPublicKey()).bytes;
    print('Mock recipient public key length=${publicKey.length}');
    return publicKey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(
        username: widget.contactName,
        profileImageUrl: widget.profileImageUrl,
        status: _isRecipientTyping ? 'Typing...' : _status,
        onProfileTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtherUserProfilePage(otherUserId: widget.recipientUserId),
            ),
          );
        },
      ),
      body: GestureDetector(
        onTap: () {
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
                        reverse: false,
                        itemCount: messages.length + (_hasMoreMessages ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_hasMoreMessages && index == 0) {
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
                onTypingStopped: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
