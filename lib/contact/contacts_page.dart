import 'dart:async'; // Import for Timer
import 'package:cook/models/deleteuserchat.dart';
import 'package:flutter/material.dart';
import 'contact_tile.dart';
import '../chat/chat_page.dart';
import 'package:cook/services/chat_service.dart';
import 'package:cook/models/contact_model.dart';
import 'pluscontact.dart';
import 'package:cook/services/signalr_service.dart';

class ContactsPage extends StatefulWidget {
  final String username;
  final int userId;
  ContactsPage({required this.username, required this.userId});

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

  Future<void> _fetchChats() async {
    try {
      final chats = await _chatService.fetchUserChats(widget.userId);
      setState(() {
        _chats = chats;
        _filteredChats = chats;
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

  void _toggleMute(int index) {
    setState(() {
      muteStatus[index] = !(muteStatus[index] ?? false);
    });
  }

Future<void> _deleteChatWithUndo(Contact chat) async {
  // Temporarily remove the chat from the displayed list
  setState(() {
    _chats.removeWhere((c) => c.chatId == chat.chatId);
    _filteredChats.removeWhere((c) => c.chatId == chat.chatId);
  });

  // Flag to track whether to delete or not
  bool shouldDelete = true;

  // Show Snackbar with "Undo" action
  final snackBar = ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Chat deleted'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          setState(() {
            // Check if the chat is not already in the lists before adding
            if (!_chats.any((c) => c.chatId == chat.chatId)) {
              _chats.add(chat);
            }
            if (!_filteredChats.any((c) => c.chatId == chat.chatId)) {
              _filteredChats.add(chat);
            }
          });
          shouldDelete = false; // Cancel the delete
        },
      ),
      duration: Duration(seconds: 3), // Snackbar duration
    ),
  );

  // Wait for the Snackbar to disappear before finalizing deletion
  await snackBar.closed;

  // Perform deletion only if "Undo" was not pressed
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

      // If deletion fails, add the chat back to the list if it's not already there
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
          isOnline: true, // Placeholder, replace with actual status if available
          lastSeen: chat.createdAt.toString(),
        ),
      ),
    );
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
      // Refresh chats when returning from NewChatPage
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
          widget.username,
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
                            lastMessage: 'Hey, how’s it going?', // Placeholder message
                            profileImage: _getDisplayProfileImage(chat),
                            isOnline: true, // Placeholder for online status
                            lastActive: '5 mins ago', // Placeholder for last active status
                            isMuted: muteStatus[index] ?? false,
                            unreadMessages: 0, // Placeholder, replace with actual unread count if available
                            isTyping: false, // Placeholder for typing status
                            onMuteToggle: () => _toggleMute(index),
                            onDelete: () => _deleteChatWithUndo(chat), // Calls the updated delete method
                          ),
                        );
                      },
                    )

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
