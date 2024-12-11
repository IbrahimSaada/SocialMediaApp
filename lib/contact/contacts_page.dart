// contacts/contacts.dart
import 'dart:async';
import 'dart:convert';
import '***REMOVED***/models/deleteuserchat.dart';
import '***REMOVED***/models/contact_model.dart';
import '***REMOVED***/services/chat_service.dart';
import '***REMOVED***/services/signalr_service.dart';
import '***REMOVED***/services/crypto/key_exchange_service.dart';
import '***REMOVED***/services/crypto/encryption_service.dart';
import '***REMOVED***/services/crypto/key_manager.dart' show UserKeyPair;
import 'package:flutter/material.dart';
import 'contact_tile.dart';
import '../chat/chat_page.dart';
import 'pluscontact.dart';
import 'package:intl/intl.dart';
import 'package:cryptography/cryptography.dart';
import '***REMOVED***/models/mute_user_dto.dart'; // Import the MuteUserDto

class ContactsPage extends StatefulWidget {
  final String fullname;
  final int userId;
  ContactsPage({required this.fullname, required this.userId});

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final ChatService _chatService = ChatService();
  final SignalRService _signalRService = SignalRService();
  List<Contact> _chats = [];
  List<Contact> _filteredChats = [];
  Map<int, bool> muteStatus = {};
  String _searchQuery = '';
  bool _isLoading = true;

  // Map to track typing status by chatId
  Map<int, bool> _isTypingMap = {};
  Map<int, Timer?> _typingTimers = {};

  SessionKeys? _sessionKeys;

  @override
  void initState() {
    super.initState();
    _initE2EE().then((_) {
      _initSignalR().then((_) {
        _fetchChats();
      });
    });
  }

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

  void _onUserTyping(int senderId) {
    if (senderId != widget.userId) {
      // Find the chat associated with this senderId
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
              createdAt: DateTime.now()));

      if (chat.chatId != 0) {
        setState(() {
          _isTypingMap[chat.chatId] = true;
        });

        // Reset any existing timer
        _typingTimers[chat.chatId]?.cancel();

        // Typing status should disappear after 3 seconds if no further typing events
        _typingTimers[chat.chatId] = Timer(Duration(seconds: 3), () {
          setState(() {
            _isTypingMap[chat.chatId] = false;
          });
        });
      }
    }
  }

  void _onChatCreated(dynamic chatDto) {
    print('ChatCreated event received: $chatDto');
    _fetchChats();
  }

  void _onNewChatNotification(dynamic chatDto) {
    print('NewChatNotification event received: $chatDto');
    _fetchChats();
  }

  void _onError(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );
  }

  void _onChatUpdate() {
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    try {
      final chats = await _chatService.fetchUserChats(widget.userId);

      // Decrypt last messages if session keys are available
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
              // If decryption fails, leave as is or show placeholder
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
    } catch (e) {
      print('Error fetching chats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterChats(String query) {
    setState(() {
      _searchQuery = query;
      _filteredChats = _chats
          .where((chat) => _getDisplayName(chat)
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  String _getDisplayName(Contact chat) {
    return chat.initiatorUserId == widget.userId
        ? chat.recipientUsername
        : chat.initiatorUsername;
  }

  String _getDisplayProfileImage(Contact chat) {
    return chat.initiatorUserId == widget.userId
        ? chat.recipientProfilePic
        : chat.initiatorProfilePic;
  }

  String _formatLastMessageTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      return DateFormat('h:mm a').format(time);
    } else {
      return DateFormat('dd/MM/yyyy').format(time);
    }
  }

  Future<void> _toggleMute(int index) async {
    final chat = _filteredChats[index];
    // Determine the other userId
    int otherUserId = chat.initiatorUserId == widget.userId
        ? chat.recipientUserId
        : chat.initiatorUserId;

    final currentlyMuted = muteStatus[index] ?? false;

    // We'll call the appropriate API
    final dto = MuteUserDto(
      mutedByUserId: widget.userId,
      mutedUserId: otherUserId,
    );

    try {
      if (!currentlyMuted) {
        // Mute the user
        await _chatService.muteUser(dto);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User muted successfully.')),
        );
      } else {
        // Unmute the user
        await _chatService.unmuteUser(dto);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User unmuted successfully.')),
        );
      }

      setState(() {
        muteStatus[index] = !currentlyMuted;
      });
    } catch (e) {
      print('Error toggling mute: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle mute.')),
      );
    }
  }

  Future<void> _deleteChatWithUndo(Contact chat) async {
    setState(() {
      _chats.removeWhere((c) => c.chatId == chat.chatId);
      _filteredChats.removeWhere((c) => c.chatId == chat.chatId);
    });

    bool shouldDelete = true;

    final snackBar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chat deleted'),
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
        duration: Duration(seconds: 3),
      ),
    );

    await snackBar.closed;

    if (shouldDelete) {
      try {
        await _chatService.deleteChat(DeleteUserChat(
          chatId: chat.chatId,
          userId: widget.userId,
        ));
      } catch (e) {
        print('Error deleting chat: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete chat')),
        );
        setState(() {
          if (!_chats.any((c) => c.chatId == chat.chatId)) {
            _chats.add(chat);
          }
          if (!_filteredChats.any((c) => c.chatId == chat.chatId)) {
            _filteredChats.add(chat);
          }
        });
      }
    }
  }

  void _navigateToChat(BuildContext context, Contact chat) {
    int recipientUserId;
    if (chat.initiatorUserId == widget.userId) {
      recipientUserId = chat.recipientUserId;
    } else {
      recipientUserId = chat.initiatorUserId;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatId: chat.chatId,
          currentUserId: widget.userId,
          recipientUserId: recipientUserId,
          contactName: _getDisplayName(chat),
          profileImageUrl: _getDisplayProfileImage(chat),
          isOnline: true,
          lastSeen: chat.createdAt.toString(),
        ),
      ),
    ).then((_) {
      _fetchChats();
    });
  }

  void _navigateToNewChatPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewChatPage(
          userId: widget.userId,
        ),
      ),
    ).then((_) {
      _fetchChats();
    });
  }

  @override
  void dispose() {
    _signalRService.hubConnection.stop();
    for (var timer in _typingTimers.values) {
      timer?.cancel();
    }
    super.dispose();
  }

  Future<void> _initE2EE() async {
    print('Initializing E2EE in ContactsPage...');
    final myKeyPair = await _loadMyUserKeyPair();
    print('My private key length: ${myKeyPair.privateKey.length}, public key length: ${myKeyPair.publicKey.length}');

    final recipientPublicKey = await _fetchRecipientPublicKeyFromServer();
    print('Mock recipient public key length: ${recipientPublicKey.length}');

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

    print('Session keys derived in ContactsPage. EncryptionKey length: ${sessionKeys.encryptionKey.length}, macKey length: ${sessionKeys.macKey.length}');

    setState(() {
      _sessionKeys = sessionKeys;
    });
  }

  Future<UserKeyPair> _loadMyUserKeyPair() async {
    print('Generating user key pair with a fixed seed (ContactsPage) for stable keys...');
    final seed = List<int>.filled(32, 1);
    final algo = X25519();
    final kp = await algo.newKeyPairFromSeed(seed);
    final privateKey = await kp.extractPrivateKeyBytes();
    final publicKey = (await kp.extractPublicKey()).bytes;
    print('Generated user key pair (ContactsPage): privateKey length=${privateKey.length}, publicKey length=${publicKey.length}');
    return UserKeyPair(privateKey: privateKey, publicKey: publicKey);
  }

  Future<List<int>> _fetchRecipientPublicKeyFromServer() async {
    print('Fetching recipient public key (mock, stable) for ContactsPage');
    // Using stable approach:
    final seed = List<int>.filled(32, 2);
    final algo = X25519();
    final kp = await algo.newKeyPairFromSeed(seed);
    final publicKey = (await kp.extractPublicKey()).bytes;
    print('Mock recipient public key length=${publicKey.length} (ContactsPage)');
    return publicKey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.fullname,
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Color(0xFFF45F67),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: _filterChats,
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: Icon(Icons.search, color: Color(0xFFF45F67)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      BorderSide(color: Color(0xFFF45F67), width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      BorderSide(color: Colors.grey, width: 2),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredChats.isEmpty
                    ? Center(
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
                              isOnline: true,
                              lastActive: _formatLastMessageTime(chat.lastMessageTime),
                              isMuted: muteStatus[index] ?? false,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToNewChatPage,
        child: Icon(Icons.add),
        backgroundColor: Color(0xFFF45F67),
      ),
    );
  }
}
