import 'package:flutter/material.dart';

void main() {
  runApp(const Search());
}

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  List<Map<String, String>> searchResults = [
    {'username': 'user1', 'profilePic': 'https://via.placeholder.com/50'},
    {'username': 'user2', 'profilePic': 'https://via.placeholder.com/50'},
    {'username': 'user3', 'profilePic': 'https://via.placeholder.com/50'},
    // Add more dummy users if needed
  ];

  void deleteUser(int index) {
    setState(() {
      searchResults.removeAt(index);
    });
  }

  void clearResults() {
    setState(() {
      searchResults.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: SizedBox(
            height: 40,
            child: TextField(
              cursorColor: Colors.black,
              decoration: InputDecoration(
                hintText: 'Search...',
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.orange, width: 2), // Initial and persistent orange border
                  borderRadius: BorderRadius.circular(20),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.orange, width: 2), // Ensure orange border stays even when not focused
                  borderRadius: BorderRadius.circular(20),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(searchResults[index]['profilePic']!),
                    ),
                    title: Text(
                      searchResults[index]['username']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.clear, color: Colors.orange),
                      onPressed: () => deleteUser(index),
                    ),
                  );
                },
              ),
            ),
            if (searchResults.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: clearResults,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.orange, width: 2),
                    ),
                  ),
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
