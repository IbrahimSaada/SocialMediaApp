// contacts_page.dart

import 'package:flutter/material.dart';
import 'contact_tile.dart';
import '../chat/chat_page.dart';
import 'package:cook/services/chat_service.dart';
import 'package:cook/models/contact_model.dart';
import 'pluscontact.dart';

class ContactsPage extends StatefulWidget {
  final String username;
  final int userId;

  ContactsPage({required this.username, required this.userId});

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final ChatService _chatService = ChatService();
  List<Contact> _chats = [];
  List<Contact> _filteredChats = [];
  Map<int, bool> muteStatus = {};
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChats();
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
    // Show recipient's name if user is the initiator, otherwise show initiator's name
    return chat.initiatorUserId == widget.userId
        ? chat.recipientUsername
        : chat.initiatorUsername;
  }

  String _getDisplayProfileImage(Contact chat) {
    // Show recipient's profile pic if user is the initiator, otherwise show initiator's profile pic
    return chat.initiatorUserId == widget.userId
        ? chat.recipientProfilePic
        : chat.initiatorProfilePic;
  }

  void _toggleMute(int index) {
    setState(() {
      muteStatus[index] = !(muteStatus[index] ?? false);
    });
  }

  void _onDelete(Contact chat) {
    print('Deleted chat with ${_getDisplayName(chat)}');
    // Implement deletion logic if necessary
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
                              lastMessage:
                                  'Hey, how’s it going?', // Placeholder message
                              profileImage: _getDisplayProfileImage(chat),
                              isOnline:
                                  true, // Placeholder for online status
                              lastActive:
                                  '5 mins ago', // Placeholder for last active status
                              isMuted: muteStatus[index] ?? false,
                              unreadMessages:
                                  0, // Placeholder, replace with actual unread count if available
                              isTyping:
                                  false, // Placeholder for typing status
                              onMuteToggle: () => _toggleMute(index),
                              onDelete: () => _onDelete(chat),
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
