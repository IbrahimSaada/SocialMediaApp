// pluscontact.dart (NewChatPage)

import 'package:flutter/material.dart';
import '***REMOVED***/services/contact_service.dart';
import '***REMOVED***/models/usercontact_model.dart';
import '***REMOVED***/services/signalr_service.dart';
import '../chat/chat_page.dart';
import '***REMOVED***/maintenance/expiredtoken.dart';
import '***REMOVED***/services/SessionExpiredException.dart';

class NewChatPage extends StatefulWidget {
  final int userId;

  const NewChatPage({Key? key, required this.userId}) : super(key: key);

  @override
  _NewChatPageState createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  final ContactService _contactService = ContactService();
  final SignalRService _signalRService = SignalRService();

  List<UserContact> _contacts = [];
  List<UserContact> _filteredContacts = [];

  String _searchQuery = '';
  bool _isLoading = true;
  int _pageNumber = 1;
  final int _pageSize = 10;
  bool _isFetchingMore = false;
  bool _hasMoreContacts = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initSignalR();
    _fetchContacts();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initSignalR() async {
    try {
      await _signalRService.initSignalR();
      // Setup listeners for new chat or errors
      _signalRService.setupListeners(
        onChatCreated: _onChatCreated,
        onNewChatNotification: _onNewChatNotification,
        onError: (String errorMessage) => _showPermissionErrorDialog(errorMessage),
      );
    } on SessionExpiredException {
      // If we cannot connect due to session expired, show the session-expired UI
      if (mounted) {
        handleSessionExpired(context);
      }
    } catch (e) {
      print('Error in _initSignalR => $e');
    }
  }

  void _showPermissionErrorDialog(String reason) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create Chat Failed'),
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

  void _onChatCreated(dynamic chatDto) {
    // If ChatCreated => navigate to ChatPage
    print('ChatCreated event => $chatDto');
    if (chatDto != null && chatDto is Map<String, dynamic>) {
      final recipientUserId = chatDto['recipientUserId'] as int;
      final chatId = chatDto['chatId'] as int;

      final contact = _contacts.firstWhere(
        (c) => c.userId == recipientUserId,
        orElse: () => UserContact(
          userId: 0,
          fullname: 'Unknown',
          profilePicUrl: '',
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            chatId: chatId,
            currentUserId: widget.userId,
            recipientUserId: recipientUserId,
            contactName: contact.fullname,
            profileImageUrl: contact.profilePicUrl,
          ),
        ),
      );
    }
  }

  void _onNewChatNotification(dynamic chatDto) {
    print('NewChatNotification => $chatDto');
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
    } on SessionExpiredException {
      if (mounted) {
        handleSessionExpired(context);
      }
      setState(() {
        _isLoading = false;
        _isFetchingMore = false;
      });
    } catch (e) {
      print('Error fetching contacts: $e');
      setState(() {
        _isLoading = false;
        _isFetchingMore = false;
      });
    }
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
    _signalRService.hubConnection.stop();
    super.dispose();
  }

  void _filterContacts(String query) {
    setState(() {
      _searchQuery = query;
      _pageNumber = 1;
      _hasMoreContacts = true;
    });
    _fetchContacts();
  }

  void _navigateToChat(UserContact contact) async {
    try {
      await _signalRService.createChat(contact.userId);
    } on SessionExpiredException {
      if (mounted) {
        handleSessionExpired(context);
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('Session expired')) {
        handleSessionExpired(context);
      } else {
        _showPermissionErrorDialog(errStr);
      }
    }
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
        title: const Text(
          'Select Contact',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFFF45F67),
      ),
      body: Column(
        children: [
          // (A) Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (value) => _filterContacts(value),
              decoration: InputDecoration(
                hintText: 'Search contacts...',
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

          // (B) Contacts list or loading
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refreshContacts,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _filteredContacts.length +
                          (_hasMoreContacts ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _filteredContacts.length &&
                            _hasMoreContacts) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (index >= _filteredContacts.length) {
                          return const SizedBox.shrink();
                        }
                        final contact = _filteredContacts[index];
                        return GestureDetector(
                          onTap: () => _navigateToChat(contact),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  NetworkImage(contact.profilePicUrl),
                            ),
                            title: Text(
                              contact.fullname,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
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
