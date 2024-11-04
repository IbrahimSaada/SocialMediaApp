// new_chat_page.dart

import 'package:flutter/material.dart';
import 'contact_tile.dart';
import '../chat/chat_page.dart';
import 'package:cook/services/contact_service.dart';
import 'package:cook/models/usercontact_model.dart';

class NewChatPage extends StatefulWidget {
  final int userId;

  NewChatPage({required this.userId});

  @override
  _NewChatPageState createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  final ContactService _contactService = ContactService();
  List<UserContact> _contacts = [];
  List<UserContact> _filteredContacts = [];
  String _searchQuery = '';
  bool _isLoading = true;
  int _pageNumber = 1;
  final int _pageSize = 10;
  bool _isFetchingMore = false;
  bool _hasMoreContacts = true;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchContacts();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchContacts({bool isInitialLoad = true}) async {
    if (_isFetchingMore) return;
    setState(() {
      _isFetchingMore = true;
      if (isInitialLoad) _isLoading = true;
    });

    try {
      final contacts = await _contactService.fetchContacts(
        widget.userId,
        search: _searchQuery,
        pageNumber: _pageNumber,
        pageSize: _pageSize,
      );

      setState(() {
        if (isInitialLoad) {
          _contacts = contacts;
        } else {
          _contacts.addAll(contacts);
        }
        _filteredContacts = _contacts;
        _isLoading = false;
        _isFetchingMore = false;
        if (contacts.length < _pageSize) {
          _hasMoreContacts = false;
        } else {
          _pageNumber++;
        }
      });
    } catch (e) {
      print('Error fetching contacts: $e');
      setState(() {
        _isLoading = false;
        _isFetchingMore = false;
      });
    }
  }

  void _filterContacts(String query) {
    setState(() {
      _searchQuery = query;
      _filteredContacts = _contacts
          .where((contact) =>
              contact.fullname.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _navigateToChat(BuildContext context, UserContact contact) async {
    // Optionally, create a new chat in the backend if needed
    // For now, we assume a chat is created and navigate to the chat page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatId: 0, // Replace with actual chatId after creating chat
          currentUserId: widget.userId,
          recipientUserId: contact.userId,
          contactName: contact.fullname,
          profileImageUrl: contact.profilePicUrl,
          isOnline: true, // Placeholder, replace with actual status if available
          lastSeen: '', // Placeholder, replace with actual last seen time if available
        ),
      ),
    ).then((_) {
      // After returning from chat, you might want to do something
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        _hasMoreContacts) {
      _fetchContacts(isInitialLoad: false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshContacts() async {
    setState(() {
      _pageNumber = 1;
      _hasMoreContacts = true;
    });
    await _fetchContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Contact',
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
              onChanged: (value) {
                _filterContacts(value);
                // Optionally, fetch contacts from API with search query
                setState(() {
                  _pageNumber = 1;
                  _hasMoreContacts = true;
                });
                _fetchContacts();
              },
              decoration: InputDecoration(
                hintText: 'Search contacts...',
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
                : RefreshIndicator(
                    onRefresh: _refreshContacts,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount:
                          _filteredContacts.length + (_hasMoreContacts ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _filteredContacts.length) {
                          return Center(child: CircularProgressIndicator());
                        }
                        final contact = _filteredContacts[index];
                        return GestureDetector(
                          onTap: () => _navigateToChat(context, contact),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  NetworkImage(contact.profilePicUrl),
                            ),
                            title: Text(
                              contact.fullname,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Tap to start chat',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
