import 'package:flutter/material.dart';
import 'contact_tile.dart';
import 'chat_page.dart';  // Import the chat page

class ContactsPage extends StatefulWidget {
  final String username;

  ContactsPage({required this.username});

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  // A map to store the mute status for each contact (using index for simplicity)
  Map<int, bool> muteStatus = {};

  // Function to toggle mute/unmute
  void _toggleMute(int index) {
    setState(() {
      muteStatus[index] = !(muteStatus[index] ?? false);  // Toggle the mute status
    });
  }

  void _onDelete(String contactName) {
    // Handle the delete action
    print('Deleted chat with $contactName');
  }

  // Function to navigate to ChatPage
  void _navigateToChat(BuildContext context, String contactName, bool isOnline, String lastSeen, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          contactName: contactName,
          profileImageUrl: 'https://example.com/profile.jpg',
          isOnline: isOnline,
          lastSeen: lastSeen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFF45F67),
        elevation: 0,
        title: Text(
          widget.username,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFFF45F67)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MESSAGES',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 20,  // Example: 20 contacts for now
              itemBuilder: (context, index) {
                String contactName = 'Contact $index';
                return GestureDetector(
                  onTap: () {
                    _navigateToChat(
                      context, 
                      contactName, 
                      index % 2 == 0,  // Example value for isOnline
                      index % 2 == 0 ? 'now' : '5 minutes ago',
                      index,
                    );  // Navigate to chat on tap
                  },
                  child: ContactTile(
                    contactName: contactName,
                    lastMessage: 'Hey, how’s it going?',
                    profileImage: 'assets/contact_image.jpg',
                    isOnline: index % 2 == 0,
                    lastActive: index % 2 == 0 ? 'now' : '5 minutes ago',
                    isMuted: muteStatus[index] ?? false,  // Pass mute state
                    unreadMessages: index % 2 == 0 ? index : 0,
                    onMuteToggle: () => _toggleMute(index),  // Pass toggle mute function
                    onDelete: () => _onDelete(contactName),  // Pass delete function
                    isTyping: false,  // You can adjust this if you have the typing status
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action for starting a new chat
        },
        backgroundColor: Color(0xFFF45F67),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
