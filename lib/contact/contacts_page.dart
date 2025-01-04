// contacts/contacts.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

// Models
import 'package:myapp/models/deleteuserchat.dart';
import 'package:myapp/models/contact_model.dart';
import 'package:myapp/models/mute_user_dto.dart';

// Services
import 'package:myapp/services/chat_service.dart';
import 'package:myapp/services/signalr_service.dart';
import 'package:myapp/services/crypto/key_exchange_service.dart';
import 'package:myapp/services/crypto/encryption_service.dart';
import 'package:myapp/services/crypto/key_manager.dart' show UserKeyPair;
import 'package:cryptography/cryptography.dart';

// Maintenance & Session
import '../maintenance/expiredtoken.dart';
import '../services/SessionExpiredException.dart';

// Widgets
import 'contact_tile.dart';
import '../chat/chat_page.dart';
import 'pluscontact.dart';

/// Utility to show a blocking/snackbar if the user is blocked
void showBlockSnackbar(BuildContext context, String reason) {
  String message;
  if (reason.contains('You are blocked by the post owner')) {
    message = 'User blocked you';
  } else if (reason.contains('You have blocked the post owner')) {
    message = 'You blocked the user';
  } else if (reason.toLowerCase().contains('blocked')) {
    message = 'Action not allowed due to blocking';
  } else {
    message = 'Action not allowed.';
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
      duration: const Duration(seconds: 3),
    ),
  );
}

class ContactsPage extends StatefulWidget {
  final String fullname;
  final int userId;

  const ContactsPage({Key? key, required this.fullname, required this.userId})
      : super(key: key);

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  // Services
  final ChatService _chatService = ChatService();
  final SignalRService _signalRService = SignalRService();

  // Data
  List<Contact> _chats = [];
  List<Contact> _filteredChats = [];
  Map<int, bool> _isTypingMap = {};
  Map<int, Timer?> _typingTimers = {};

  // Searching & Loading
  String _searchQuery = '';
  bool _isLoading = true;

  // E2EE session keys
  SessionKeys? _sessionKeys;

@override
void initState() {
  super.initState();
  _initE2EE().then((_) async {
    try {
      // Wrap _initSignalR() in a try/catch
      await _initSignalR(); 
      // Only if SignalR starts successfully do we call _fetchChats()
      _fetchChats();
    } on SessionExpiredException {
      // The user’s token truly couldn’t be refreshed => show your session-expired UI
      if (mounted) {
        handleSessionExpired(context);
      }
    }
  });
}


  /// Initialize SignalR with event listeners
  Future<void> _initSignalR() async {
    await _signalRService.initSignalR();

    _signalRService.setupListeners(
      onChatCreated: _onChatCreated,
      onNewChatNotification: _onNewChatNotification,
      onError: _onError,
      onReceiveMessage: _onChatUpdate,
      onMessageSent: _onChatUpdate,
      onMessageEdited: _onChatUpdate,
      onMessageUnsent: _onChatUpdate,
      onMessagesRead: _onChatUpdate,
      onUserTyping: _onUserTyping,
    );
  }

  /// E2EE initialization (deriving stable seeds for demonstration only)
  Future<void> _initE2EE() async {
    print('Initializing E2EE in ContactsPage...');
    final myKeyPair = await _loadMyUserKeyPair();
    print(
      'My private key length (ContactsPage): '
      '${myKeyPair.privateKey.length}, public key length: ${myKeyPair.publicKey.length}',
    );

    final recipientPublicKey = await _fetchRecipientPublicKeyFromServer();
    print(
      'Mock recipient public key length (ContactsPage): ${recipientPublicKey.length}',
    );

    final keyExchangeService = KeyExchangeService();
    final sharedSecret = await keyExchangeService.deriveSharedSecret(
      ourPrivateKey: myKeyPair.privateKey,
      theirPublicKey: recipientPublicKey,
    );

    print('Derived shared secret (ContactsPage): $sharedSecret');
    print('Derived shared secret length (ContactsPage): ${sharedSecret.length}');

    if (sharedSecret.isEmpty) {
      print('Shared secret is empty! Cannot derive session keys in ContactsPage.');
      return;
    }

    final sessionKeys = await keyExchangeService.deriveSessionKeys(sharedSecret);
    print(
      'Session keys derived in ContactsPage. EncryptionKey length: '
      '${sessionKeys.encryptionKey.length}, macKey length: ${sessionKeys.macKey.length}',
    );

    setState(() => _sessionKeys = sessionKeys);
  }

  /// Generate a stable user key pair from a fixed seed (demo only).
  Future<UserKeyPair> _loadMyUserKeyPair() async {
    print('Generating user key pair (ContactsPage) from stable seed...');
    final seed = List<int>.filled(32, 1);
    final algo = X25519();
    final kp = await algo.newKeyPairFromSeed(seed);
    final privateKey = await kp.extractPrivateKeyBytes();
    final publicKey = (await kp.extractPublicKey()).bytes;
    return UserKeyPair(privateKey: privateKey, publicKey: publicKey);
  }

  /// Generate stable public key for 'recipient' from a seed=2
  Future<List<int>> _fetchRecipientPublicKeyFromServer() async {
    print('Fetching mock recipient public key (ContactsPage) from stable seed=2');
    final seed = List<int>.filled(32, 2);
    final algo = X25519();
    final kp = await algo.newKeyPairFromSeed(seed);
    final publicKey = (await kp.extractPublicKey()).bytes;
    return publicKey;
  }

  /// "ChatCreated" event => re-fetch
  void _onChatCreated(dynamic chatDto) {
    print('ChatCreated event received: $chatDto');
    _fetchChats();
  }

  /// "NewChatNotification" => re-fetch
  void _onNewChatNotification(dynamic chatDto) {
    print('NewChatNotification event received: $chatDto');
    _fetchChats();
  }

  /// "Error" event => might be a block or general error
  void _onError(String errorMessage) {
    final errStr = errorMessage.toLowerCase();
    if (errStr.contains('blocked')) {
      showBlockSnackbar(context, errorMessage);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  /// Any chat update => re-fetch
  void _onChatUpdate() {
    _fetchChats();
  }

  /// If user is typing
  void _onUserTyping(int senderId) {
    if (senderId != widget.userId) {
      final chat = _chats.firstWhere(
        (c) =>
            (c.initiatorUserId == senderId && c.recipientUserId == widget.userId) ||
            (c.recipientUserId == senderId && c.initiatorUserId == widget.userId),
        orElse: () => Contact(
          chatId: 0,
          initiatorUserId: 0,
          initiatorUsername: '',
          recipientUserId: 0,
          recipientUsername: '',
          initiatorProfilePic: '',
          recipientProfilePic: '',
          lastMessage: '',
          lastMessageTime: DateTime.now(),
          unreadCount: 0,
          createdAt: DateTime.now(),
          isMuted: false,
        ),
      );

      if (chat.chatId != 0) {
        setState(() {
          _isTypingMap[chat.chatId] = true;
        });

        _typingTimers[chat.chatId]?.cancel();
        _typingTimers[chat.chatId] = Timer(const Duration(seconds: 3), () {
          setState(() {
            _isTypingMap[chat.chatId] = false;
          });
        });
      }
    }
  }

  /// Fetch user’s chats & decrypt lastMessage if session keys exist
  Future<void> _fetchChats() async {
    try {
      final chats = await _chatService.fetchUserChats(widget.userId);

      if (_sessionKeys != null) {
        final encryptionService = EncryptionService();
        for (int i = 0; i < chats.length; i++) {
          final chat = chats[i];
          if (chat.lastMessage.isNotEmpty) {
            try {
              final ciphertext = base64Decode(chat.lastMessage);
              final decryptedBytes = await encryptionService.decryptMessage(
                encryptionKey: _sessionKeys!.encryptionKey,
                ciphertext: ciphertext,
              );
              final decryptedText = utf8.decode(decryptedBytes);
              chats[i] = chat.copyWith(lastMessage: decryptedText);
            } catch (e) {
              print('Error decrypting lastMessage for chatId=${chat.chatId}: $e');
            }
          }
        }
      }

      setState(() {
        _chats = chats;
        _filteredChats = chats
            .where((chat) => _getDisplayName(chat)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();
        _isLoading = false;
      });
    }
    on SessionExpiredException {
      // The token was truly invalid & could not refresh => session expired
      if (mounted) {
        handleSessionExpired(context);
      }
      setState(() => _isLoading = false);
    } catch (e) {
      final errStr = e.toString();
      if (errStr.startsWith('Exception: BLOCKED:') ||
          errStr.toLowerCase().contains('blocked')) {
        String reason = errStr.startsWith('Exception: BLOCKED:')
            ? errStr.replaceFirst('Exception: BLOCKED:', '')
            : errStr;
        showBlockSnackbar(context, reason);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred while fetching chats.')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  /// Filter the local list of chats
  void _filterChats(String query) {
    setState(() {
      _searchQuery = query;
      _filteredChats = _chats
          .where((chat) =>
              _getDisplayName(chat).toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  /// Return the name to display
  String _getDisplayName(Contact chat) {
    return (chat.initiatorUserId == widget.userId)
        ? chat.recipientUsername
        : chat.initiatorUsername;
  }

  /// Return which user’s profile pic to show
  String _getDisplayProfileImage(Contact chat) {
    return (chat.initiatorUserId == widget.userId)
        ? chat.recipientProfilePic
        : chat.initiatorProfilePic;
  }

  /// Mute/unmute this chat’s other user
  Future<void> _toggleMute(int index) async {
    final chat = _filteredChats[index];
    final otherUserId = (chat.initiatorUserId == widget.userId)
        ? chat.recipientUserId
        : chat.initiatorUserId;

    final dto = MuteUserDto(
      mutedByUserId: widget.userId,
      mutedUserId: otherUserId,
    );

    try {
      if (!chat.isMuted) {
        await _chatService.muteUser(dto);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User muted successfully.')),
        );
      } else {
        await _chatService.unmuteUser(dto);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User unmuted successfully.')),
        );
      }

      setState(() {
        _filteredChats[index] = chat.copyWith(isMuted: !chat.isMuted);
        _chats = _chats.map((c) {
          if (c.chatId == chat.chatId) {
            return chat.copyWith(isMuted: !chat.isMuted);
          }
          return c;
        }).toList();
      });
    }
    on SessionExpiredException {
      if (mounted) {
        handleSessionExpired(context);
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.startsWith('Exception: BLOCKED:') ||
          errStr.toLowerCase().contains('blocked')) {
        final String reason = errStr.startsWith('Exception: BLOCKED:')
            ? errStr.replaceFirst('Exception: BLOCKED:', '')
            : errStr;
        showBlockSnackbar(context, reason);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to toggle mute.')),
        );
      }
    }
  }

  /// Delete chat with a possibility to Undo
  Future<void> _deleteChatWithUndo(Contact chat) async {
    setState(() {
      _chats.removeWhere((c) => c.chatId == chat.chatId);
      _filteredChats.removeWhere((c) => c.chatId == chat.chatId);
    });

    bool shouldDelete = true;

    final snackBar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Chat deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              if (!_chats.any((c) => c.chatId == chat.chatId)) {
                _chats.add(chat);
              }
              if (!_filteredChats.any((c) => c.chatId == chat.chatId)) {
                _filteredChats.add(chat);
              }
            });
            shouldDelete = false;
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );

    await snackBar.closed;

    if (shouldDelete) {
      try {
        await _chatService.deleteChat(
          DeleteUserChat(chatId: chat.chatId, userId: widget.userId),
        );
      }
      on SessionExpiredException {
        // If session expired mid-request, show UI & re-insert chat
        if (mounted) {
          handleSessionExpired(context);
        }
        setState(() {
          _chats.add(chat);
          _filteredChats.add(chat);
        });
      } catch (e) {
        final errStr = e.toString();
        if (errStr.startsWith('Exception: BLOCKED:') ||
            errStr.toLowerCase().contains('blocked')) {
          final String reason = errStr.startsWith('Exception: BLOCKED:')
              ? errStr.replaceFirst('Exception: BLOCKED:', '')
              : errStr;
          showBlockSnackbar(context, reason);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete chat')),
          );
        }
        // Re-insert the chat if it failed
        setState(() {
          _chats.add(chat);
          _filteredChats.add(chat);
        });
      }
    }
  }

  /// Navigate to the single ChatPage for the given contact
  void _navigateToChat(BuildContext context, Contact chat) {
    final int recipientUserId = (chat.initiatorUserId == widget.userId)
        ? chat.recipientUserId
        : chat.initiatorUserId;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatId: chat.chatId,
          currentUserId: widget.userId,
          recipientUserId: recipientUserId,
          contactName: _getDisplayName(chat),
          profileImageUrl: _getDisplayProfileImage(chat),
        ),
      ),
    ).then((_) => _fetchChats());
  }

  /// Start a new chat
  void _navigateToNewChatPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewChatPage(userId: widget.userId),
      ),
    ).then((_) => _fetchChats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.fullname,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFFF45F67),
      ),
      body: Column(
        children: [
          // (A) Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: _filterChats,
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFF45F67)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(
                    color: Color(0xFFF45F67),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.grey, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),

          // (B) List of Chats or Loading
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredChats.isEmpty
                    ? const Center(
                        child: Text(
                          'No chats found.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredChats.length,
                        itemBuilder: (context, index) {
                          final chat = _filteredChats[index];
                          final chatId = chat.chatId;
                          final isTyping = _isTypingMap[chatId] ?? false;

                          return GestureDetector(
                            onTap: () => _navigateToChat(context, chat),
                            child: ContactTile(
                              contactName: _getDisplayName(chat),
                              lastMessage: chat.lastMessage.isNotEmpty
                                  ? chat.lastMessage
                                  : 'No messages yet',
                              profileImage: _getDisplayProfileImage(chat),
                              isMuted: chat.isMuted,
                              unreadMessages: chat.unreadCount,
                              isTyping: isTyping,
                              onMuteToggle: () => _toggleMute(index),
                              onDelete: () => _deleteChatWithUndo(chat),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),

      // (C) New Chat
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToNewChatPage,
        backgroundColor: const Color(0xFFF45F67),
        child: const Icon(Icons.add),
      ),
    );
  }
}
