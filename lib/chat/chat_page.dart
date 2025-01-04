// chat_page.dart

import 'package:flutter/material.dart';
import 'package:myapp/services/chat_service.dart';
import 'package:myapp/models/message_model.dart';
import 'package:myapp/services/signalr_service.dart';
import 'package:myapp/chat/message_input.dart';
import 'package:myapp/chat/message_bubble.dart';
import 'package:myapp/chat/chat_app_bar.dart';
import 'dart:async';
import 'dart:convert';
import 'package:myapp/profile/otheruserprofilepage.dart';
import 'package:myapp/services/crypto/key_exchange_service.dart';
import 'package:myapp/services/crypto/encryption_service.dart';
import 'package:myapp/services/crypto/key_manager.dart' show UserKeyPair;
import 'package:cryptography/cryptography.dart';
import '../maintenance/expiredtoken.dart';
import 'package:myapp/services/SessionExpiredException.dart';

class ChatPage extends StatefulWidget {
  final int chatId;
  final int currentUserId;
  final int recipientUserId;
  final String contactName;
  final String profileImageUrl;

  const ChatPage({
    Key? key,
    required this.chatId,
    required this.currentUserId,
    required this.recipientUserId,
    required this.contactName,
    required this.profileImageUrl,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  // Services
  final ChatService _chatService = ChatService();
  final SignalRService _signalRService = SignalRService();

  // UI & Data
  final ScrollController _scrollController = ScrollController();
  List<Message> messages = [];
  bool _isLoading = true;
  bool _isRecipientTyping = false;
  bool _isFetchingMore = false;
  bool _hasMoreMessages = true;
  bool _shouldScrollToBottom = false;

  String _status = '';
  int _currentPage = 1;
  final int _pageSize = 20;
  Timer? _typingTimer;

  // E2EE session
  SessionKeys? _sessionKeys;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 1) Initialize encryption keys
    _initE2EE().then((_) {
      // 2) Connect & init SignalR
      _initSignalR();
    });

    // 3) Set up infinite scroll to fetch older messages
    _scrollController.addListener(() {
      if (_scrollController.position.atEdge &&
          _scrollController.position.pixels ==
              _scrollController.position.minScrollExtent &&
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

    // Remove Hub listeners
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
    // Auto-scroll if keyboard closes or other changes happen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  /// (A) E2EE Initialization
  Future<void> _initE2EE() async {
    print('Initializing E2EE...');
    final myKeyPair = await _loadMyUserKeyPair();
    print(
      'My private key length: ${myKeyPair.privateKey.length}, '
      'public key length: ${myKeyPair.publicKey.length}',
    );

    final recipientPublicKey =
        await _fetchRecipientPublicKeyFromServer(widget.recipientUserId);
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
    print(
      'Session keys derived. EncryptionKey length: '
      '${sessionKeys.encryptionKey.length}, macKey length: ${sessionKeys.macKey.length}',
    );

    setState(() {
      _sessionKeys = sessionKeys;
    });
  }

  /// (B) Connect to SignalR, set up listeners
  Future<void> _initSignalR() async {
    try {
      print('Initializing SignalR...');
      await _signalRService.initSignalR();

      // Setup hub listeners
      _signalRService.hubConnection.on('ReceiveMessage', _handleReceiveMessage);
      _signalRService.hubConnection.on('MessageSent', _handleMessageSent);
      _signalRService.hubConnection.on('MessageEdited', _handleMessageEdited);
      _signalRService.hubConnection.on('MessageUnsent', _handleMessageUnsent);
      _signalRService.hubConnection.on('UserTyping', _handleUserTyping);
      _signalRService.hubConnection.on('MessagesRead', _handleMessagesRead);

      // Server "Error" event => permission or block error
      _signalRService.hubConnection.on('Error', (args) {
        if (args != null && args.isNotEmpty) {
          final errorMsg = args[0] ?? 'Unknown error occurred';
          _showPermissionErrorDialog(errorMsg);
        }
      });

      // Fetch initial messages
      await _fetchMessages();
      // Mark them as read
      _signalRService.markMessagesAsRead(widget.chatId);

    } on SessionExpiredException {
      // If session is expired up front, show your SessionExpired UI
      if (mounted) {
        handleSessionExpired(context);
      }
    } catch (e) {
      print('Error initializing SignalR: $e');
    }
  }

  void _showPermissionErrorDialog(String reason) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Message Failed'),
          content: Text(reason),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFFF45F67)),
              ),
            ),
          ],
        );
      },
    );
  }

  /// (C) Fetch messages (paging)
  Future<void> _fetchMessages({bool loadMore = false}) async {
    if (_isFetchingMore) return;
    _isFetchingMore = true;

    try {
      if (!loadMore) {
        // resetting the page
        _currentPage = 1;
        _hasMoreMessages = true;
      }

      print('Fetching messages, page=$_currentPage, pageSize=$_pageSize');
      final result = await _signalRService.hubConnection.invoke(
        'FetchMessages',
        args: [widget.chatId, _currentPage, _pageSize],
      );

      final List<dynamic> messagesData = result as List<dynamic>;
      List<Message> fetchedMessages = [];

      // 1) Convert & decrypt
      for (var messageData in messagesData) {
        try {
          final Map<String, dynamic> messageMap =
              Map<String, dynamic>.from(messageData);

          if (messageMap['createdAt'] is String) {
            messageMap['createdAt'] = _forceUtc(messageMap['createdAt']);
          }
          if (messageMap['readAt'] != null && messageMap['readAt'] is String) {
            messageMap['readAt'] = _forceUtc(messageMap['readAt']);
          }

          var message = Message.fromJson(messageMap);

          // Decrypt if we have keys
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
        }
      }

      // 2) Reverse them so older appear at the top
      fetchedMessages = fetchedMessages.reversed.toList();

      setState(() {
        if (loadMore) {
          final prevScrollHeight = _scrollController.position.extentAfter;
          final prevScrollOffset = _scrollController.offset;

          messages.insertAll(0, fetchedMessages);
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          _isLoading = false;
          _currentPage++;

          if (fetchedMessages.length < _pageSize) {
            _hasMoreMessages = false;
          }

          // Adjust scroll offset so user sees same position
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final newScrollHeight = _scrollController.position.extentAfter;
            final scrollOffsetDelta = newScrollHeight - prevScrollHeight;
            _scrollController.jumpTo(prevScrollOffset + scrollOffsetDelta);
          });
        } else {
          // initial fetch
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
    } on SessionExpiredException {
      if (mounted) {
        handleSessionExpired(context);
      }
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error fetching messages via SignalR: $e');
      if (e.toString().contains('Session expired')) {
        if (mounted) {
          handleSessionExpired(context);
        }
      }
      setState(() => _isLoading = false);
    } finally {
      _isFetchingMore = false;
    }
  }

  /// Region: Hub Event Handlers
  void _handleReceiveMessage(List<Object?>? arguments) async {
    if (arguments != null && arguments.isNotEmpty) {
      final messageData = Map<String, dynamic>.from(arguments[0] as Map);

      // fix date fields
      if (messageData['createdAt'] is String) {
        messageData['createdAt'] = _forceUtc(messageData['createdAt']);
      }
      if (messageData['readAt'] != null && messageData['readAt'] is String) {
        messageData['readAt'] = _forceUtc(messageData['readAt']);
      }

      var message = Message.fromJson(messageData);

      if (message.chatId == widget.chatId) {
        // Decrypt
        if (_sessionKeys != null && message.messageContent.isNotEmpty) {
          try {
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
            message = message.copyWith(
              messageContent: 'Could not decrypt this message.',
            );
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

    // mark read
    _signalRService.markMessagesAsRead(widget.chatId);
  }

  void _handleMessageSent(List<Object?>? arguments) async {
    if (arguments != null && arguments.isNotEmpty) {
      final messageData = Map<String, dynamic>.from(arguments[0] as Map);

      if (messageData['createdAt'] is String) {
        messageData['createdAt'] = _forceUtc(messageData['createdAt']);
      }
      if (messageData['readAt'] != null && messageData['readAt'] is String) {
        messageData['readAt'] = _forceUtc(messageData['readAt']);
      }

      var message = Message.fromJson(messageData);

      if (message.chatId == widget.chatId) {
        // decrypt if needed
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
            print('Error decrypting received message: $e');
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
      final senderId = arguments[0] as int;
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
    _typingTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _isRecipientTyping = false;
      });
    });
  }

  Future<void> _handleMessageEdited(List<Object?>? arguments) async {
    if (arguments != null && arguments.isNotEmpty) {
      final messageData = Map<String, dynamic>.from(arguments[0] as Map);

      if (messageData['createdAt'] is String) {
        messageData['createdAt'] = _forceUtc(messageData['createdAt']);
      }
      if (messageData['readAt'] != null && messageData['readAt'] is String) {
        messageData['readAt'] = _forceUtc(messageData['readAt']);
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
          final index = messages.indexWhere(
            (msg) => msg.messageId == editedMessage.messageId,
          );
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
      final messageId = arguments[0] as int;

      setState(() {
        final index = messages.indexWhere((msg) => msg.messageId == messageId);
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
      final chatId = arguments[0] as int;
      final readerUserId = arguments[1] as int;

      if (chatId == widget.chatId && readerUserId == widget.recipientUserId) {
        setState(() {
          messages = messages.map((m) {
            if (m.senderId == widget.currentUserId && m.readAt == null) {
              return m.copyWith(readAt: DateTime.now().toLocal());
            }
            return m;
          }).toList();
        });
      }
    }
  }

  // Region: UI Actions
  /// (1) Send a message
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

      setState(() => _shouldScrollToBottom = true);
      _scrollToBottom();
    } on SessionExpiredException {
      if (mounted) {
        handleSessionExpired(context);
      }
    } catch (e) {
      print('Error sending message: $e');
      if (e.toString().contains('Session expired')) {
        if (mounted) {
          handleSessionExpired(context);
        }
      }
    }
  }

  /// (2) Edit a message
  void _handleEditMessage(int messageId, String newContent) async {
    try {
      if (_sessionKeys == null) {
        print('No session keys available. Cannot encrypt edited message.');
        return;
      }

      final encryptionService = EncryptionService();
      final plaintext = utf8.encode(newContent);
      final ciphertext = await encryptionService.encryptMessage(
        encryptionKey: _sessionKeys!.encryptionKey,
        plaintext: plaintext,
      );
      final encodedCiphertext = base64Encode(ciphertext);

      await _signalRService.editMessage(messageId, encodedCiphertext);

      // Locally update the message
      setState(() {
        final index = messages.indexWhere((msg) => msg.messageId == messageId);
        if (index != -1) {
          messages[index] = messages[index].copyWith(
            messageContent: newContent,
            isEdited: true,
          );
        }
      });

      FocusScope.of(context).unfocus();
    } on SessionExpiredException {
      if (mounted) {
        handleSessionExpired(context);
      }
    } catch (e) {
      print('Error editing message: $e');
      if (e.toString().contains('Session expired')) {
        if (mounted) {
          handleSessionExpired(context);
        }
      }
    }
  }

  /// (3) Unsend (delete for everyone)
  void _handleDeleteForAll(int messageId) async {
    try {
      await _signalRService.unsendMessage(messageId);
      FocusScope.of(context).unfocus();
    } on SessionExpiredException {
      if (mounted) {
        handleSessionExpired(context);
      }
    } catch (e) {
      print('Error deleting message: $e');
      if (e.toString().contains('Session expired')) {
        if (mounted) {
          handleSessionExpired(context);
        }
      }
    }
  }

  /// Auto-scroll
  void _scrollToBottom() {
    if (_shouldScrollToBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          try {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
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
    final currentDate = messages[index].createdAt;
    final previousDate = messages[index - 1].createdAt;
    return currentDate.day != previousDate.day ||
        currentDate.month != previousDate.month ||
        currentDate.year != previousDate.year;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now().toLocal();
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

  /// Provide stable seed for demonstration
  Future<UserKeyPair> _loadMyUserKeyPair() async {
    print('Generating user key pair with a fixed seed for stable keys...');
    final seed = List<int>.filled(32, 1);
    final algo = X25519();
    final kp = await algo.newKeyPairFromSeed(seed);
    final privateKey = await kp.extractPrivateKeyBytes();
    final publicKey = (await kp.extractPublicKey()).bytes;
    print(
      'Generated user key pair (stable): privateKey length=${privateKey.length}, '
      'publicKey length=${publicKey.length}',
    );
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

  String _forceUtc(String dateStr) {
    if (!dateStr.endsWith('Z')) {
      dateStr += 'Z';
    }
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top bar
      appBar: ChatAppBar(
        username: widget.contactName,
        profileImageUrl: widget.profileImageUrl,
        status: _isRecipientTyping ? 'Typing...' : _status,
        onProfileTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => OtherUserProfilePage(
                otherUserId: widget.recipientUserId,
              ),
            ),
          );
        },
      ),
      // Body
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              // Messages
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: false,
                        itemCount: messages.length + (_hasMoreMessages ? 1 : 0),
                        itemBuilder: (ctx, index) {
                          // Show loader at top if more messages exist
                          if (_hasMoreMessages && index == 0) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final actualIndex =
                              _hasMoreMessages ? index - 1 : index;
                          if (actualIndex < 0 ||
                              actualIndex >= messages.length) {
                            return const SizedBox.shrink();
                          }

                          final message = messages[actualIndex];
                          final isSender =
                              (message.senderId == widget.currentUserId);
                          final showDate = _isNewDay(actualIndex);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Show the date if new day
                              if (showDate)
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                    child: Text(
                                      _formatDate(message.createdAt),
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                              // Actual bubble
                              Align(
                                alignment: isSender
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: MessageBubble(
                                  isSender: isSender,
                                  readAt: message.readAt,
                                  message: message.isUnsent
                                      ? 'This message was deleted'
                                      : message.messageContent,
                                  timestamp: message.createdAt,
                                  isSeen: (message.readAt != null),
                                  isEdited: message.isEdited,
                                  isUnsent: message.isUnsent,
                                  messageType: message.messageType,
                                  onEdit: (newText) => _handleEditMessage(
                                    message.messageId,
                                    newText,
                                  ),
                                  onDeleteForAll: () =>
                                      _handleDeleteForAll(message.messageId),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),

              // Bottom text input
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
