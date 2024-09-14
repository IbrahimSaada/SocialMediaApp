import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Add Friends',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AddFriendsPage(),
    );
  }
}

class AddFriendsPage extends StatefulWidget {
  const AddFriendsPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AddFriendsPageState createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage> {
  final List<User> _users = [
    User(profilePhoto: 'assets/chef.jpg', name: 'John Doe'),
    User(profilePhoto: 'assets/2.jpg', name: 'Ahmad'),
    User(profilePhoto: 'assets/3.jpg', name: 'ibrahim'),
    // Add more users here
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality goes here
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  return UserForm(
                    profilePhoto: _users[index].profilePhoto,
                    name: _users[index].name,
                    onAdd: () {
                      // Add friend functionality goes here
                      setState(() {
                        _users[index].isAdded = true;
                      });
                    },
                    onRemove: () {
                      // Remove friend functionality goes here
                      setState(() {
                        _users[index].isAdded = false;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class User {
  String profilePhoto;
  String name;
  bool isAdded;

  User({required this.profilePhoto, required this.name, this.isAdded = false});
}

class UserForm extends StatelessWidget {
  final String profilePhoto;
  final String name;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const UserForm({super.key, 
    required this.profilePhoto,
    required this.name,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: AssetImage(profilePhoto), // Use AssetImage
            ),
            const SizedBox(width: 10),
            Text(
              name,
              style: const TextStyle(fontSize: 18),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange), // Set button color to orange
              child: const Text(
                'Add',
                style: TextStyle(
                    color: Colors
                        .white), // Set text color to white (since button color is orange)
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: onRemove,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange), // Set button color to orange
              child: const Text(
                'Remove',
                style: TextStyle(
                    color: Colors
                        .white), // Set text color to white (since button color is orange)
              ),
            ),
          ],
        ),
      ),
    );
  }
}
