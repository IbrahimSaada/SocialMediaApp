import 'package:flutter/material.dart';
import 'contact_tile.dart';
import 'chat_page.dart';
import '***REMOVED***/services/chat_service.dart';
import '***REMOVED***/models/contact_model.dart';

class ContactsPage extends StatefulWidget {
  final String username;
  final int userId;

  ContactsPage({required this.username, required this.userId});

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final ChatService _chatService = ChatService();
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  Map<int, bool> muteStatus = {};
  bool _hasFetchedContacts = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    if (_hasFetchedContacts) {
      print('Fetch skipped; already fetched contacts.');
      return;
    }

    try {
      final contacts = await _chatService.fetchUserChats(widget.userId);
      setState(() {
        _contacts = contacts;
        _filteredContacts = contacts;
        _hasFetchedContacts = true;
      });
    } catch (e) {
      print('Error fetching contacts: $e');
    }
  }

  void _filterContacts(String query) {
    setState(() {
      _searchQuery = query;
      _filteredContacts = _contacts
          .where((contact) =>
              _getDisplayName(contact)
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();
    });
  }

  String _getDisplayName(Contact contact) {
    // Show recipient's name if user is the initiator, otherwise show initiator's name
    return contact.initiatorUserId == widget.userId
        ? contact.recipientUsername
        : contact.initiatorUsername;
  }

  String _getDisplayProfileImage(Contact contact) {
    // Show recipient's profile pic if user is the initiator, otherwise show initiator's profile pic
    return contact.initiatorUserId == widget.userId
        ? contact.recipientProfilePic
        : contact.initiatorProfilePic;
  }

  void _toggleMute(int index) {
    setState(() {
      muteStatus[index] = !(muteStatus[index] ?? false);
    });
  }

  void _onDelete(String contactName) {
    print('Deleted chat with $contactName');
  }

 void _navigateToChat(BuildContext context, Contact contact) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatPage(
        chatId: contact.chatId,  // Pass chatId to ChatPage
        contactName: _getDisplayName(contact),
        profileImageUrl: _getDisplayProfileImage(contact),
        isOnline: true, // Placeholder, replace with actual status if available
        lastSeen: contact.createdAt.toString(),
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFF45F67),
        title: Text(
          widget.username,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: _filterContacts,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: Icon(Icons.search, color: Color(0xFFF45F67)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Color(0xFFF45F67), width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: _filteredContacts.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      return GestureDetector(
                        onTap: () => _navigateToChat(context, contact),
                        child: ContactTile(
                          contactName: _getDisplayName(contact),
                          lastMessage: 'Hey, how’s it going?', // Placeholder message
                          profileImage: _getDisplayProfileImage(contact),
                          isOnline: true, // Placeholder for online status
                          lastActive: '5 mins ago', // Placeholder for last active status
                          isMuted: muteStatus[index] ?? false,
                          unreadMessages: 0, // Placeholder, replace with actual unread count if available
                          isTyping: false, // Placeholder for typing status
                          onMuteToggle: () => _toggleMute(index),
                          onDelete: () => _onDelete(_getDisplayName(contact)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
