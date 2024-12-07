import 'dart:async';
import 'package:cook/models/deleteuserchat.dart';
import 'package:flutter/material.dart';
import 'contact_tile.dart';
import '../chat/chat_page.dart';
import 'package:cook/services/chat_service.dart';
import 'package:cook/models/contact_model.dart';
import 'pluscontact.dart';
import 'package:cook/services/signalr_service.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _initSignalR();
    _fetchChats();
  }

  Future<void> _initSignalR() async {
    await _signalRService.initSignalR();
    _signalRService.setupListeners(
      onChatCreated: _onChatCreated,
      onNewChatNotification: _onNewChatNotification,
      onError: _onError,
      // Real-time updates for the contacts page
      onReceiveMessage: _onChatUpdate,
      onMessageSent: _onChatUpdate,
      onMessageEdited: _onChatUpdate,
      onMessageUnsent: _onChatUpdate,
      onMessagesRead: _onChatUpdate,
    );
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
    // When a message is received/sent/edited/unsent/read,
    // refresh the chat list to update lastMessage/unreadCounts
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    try {
      final chats = await _chatService.fetchUserChats(widget.userId);
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

  void _toggleMute(int index) {
    setState(() {
      muteStatus[index] = !(muteStatus[index] ?? false);
    });
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
      // Now that we have real-time updates, we may not need to refresh here,
      // but let's keep it in case something wasn't caught by SignalR.
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
    super.dispose();
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
                          return GestureDetector(
                            onTap: () => _navigateToChat(context, chat),
                            child: ContactTile(
                              contactName: _getDisplayName(chat),
                              lastMessage: chat.lastMessage.isNotEmpty
                                  ? chat.lastMessage
                                  : 'No messages yet',
                              profileImage: _getDisplayProfileImage(chat),
                              isOnline: true, // Placeholder if needed
                              lastActive: _formatLastMessageTime(chat.lastMessageTime),
                              isMuted: muteStatus[index] ?? false,
                              unreadMessages: chat.unreadCount,
                              isTyping: false,
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
