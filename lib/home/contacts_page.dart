import 'package:flutter/material.dart';
import 'package:cook/home/chat_page.dart'; // Import the chat_page

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contacts App',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: ContactsPage(),
    );
  }
}

class ContactsPage extends StatelessWidget {
  final List<Contact> contacts = [
    Contact(
        name: 'Ibrahim Saada',
        description: 'Software Engineer',
        imageUrl: 'https://via.placeholder.com/150',
        lastSeen: '2 hours ago',
        lastMessage: '',
        isOnline: true),
    Contact(
        name: 'Jane Smith',
        description: 'Product Manager',
        imageUrl: 'https://via.placeholder.com/150',
        lastSeen: '5 minutes ago',
        lastMessage: 'See you tomorrow!',
        isOnline: false),
    Contact(
        name: 'Michael Brow',
        description: 'UX Designer',
        imageUrl: 'https://via.placeholder.com/150',
        lastSeen: '1 hour ago',
        lastMessage: 'Can you review this design?',
        isOnline: true),
  ];

   ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality goes here
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Messages',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                return ContactCard(
                  contact: contacts[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ChatPage(contact: contacts[index]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Contact {
  final String name;
  final String description;
  final String imageUrl;
  final String lastSeen;
  final String lastMessage;
  final bool isOnline;

  Contact({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.lastSeen,
    required this.lastMessage,
    required this.isOnline,
  });
}

class ContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;

  const ContactCard({super.key, required this.contact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(contact.imageUrl),
              radius: 30.0,
            ),
            if (contact.isOnline)
              const Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: Colors.green,
                  radius: 8.0,
                ),
              ),
          ],
        ),
        title: Text(
          contact.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.description),
            const SizedBox(height: 4.0),
            Text(
              contact.lastMessage.isNotEmpty
                  ? 'Message: ${contact.lastMessage}'
                  : 'Last seen: ${contact.lastSeen}',
              style: const TextStyle(
                fontSize: 12.0,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
