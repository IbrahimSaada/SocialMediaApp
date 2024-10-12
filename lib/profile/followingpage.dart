import 'package:flutter/material.dart';

class FollowingPage extends StatefulWidget {
  final int userId;

  FollowingPage({required this.userId});

  @override
  _FollowingPageState createState() => _FollowingPageState();
}

class _FollowingPageState extends State<FollowingPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> following = [
    {
      'username': 'emily_clark_with_long_username',
      'profilePic': 'assets/images/profile3.png',
    },
    {
      'username': 'mike_lee',
      'profilePic': 'assets/images/profile4.png',
    },
    // Add more following as examples
  ];

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Following',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).secondaryHeaderColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search following...',
                    hintStyle: TextStyle(color: Theme.of(context).primaryColor),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: following.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: AssetImage(following[index]['profilePic']!),
                        radius: screenWidth * 0.05, // Smaller profile picture
                      ),
                      SizedBox(width: 8), // Reduced space between pp and username
                      Expanded(
                        child: Text(
                          following[index]['username']!,
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          // Implement message functionality
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Theme.of(context).primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4), // Adjusted padding
                        ),
                        child: Text(
                          'Message',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Theme.of(context).primaryColor),
                        itemBuilder: (BuildContext context) {
                          return [
                            PopupMenuItem<String>(
                              value: 'block',
                              child: Row(
                                children: [
                                  Icon(Icons.block, color: Colors.redAccent),
                                  SizedBox(width: 8),
                                  Text('Block'),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'unfollow',
                              child: Row(
                                children: [
                                  Icon(Icons.person_remove, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text('Unfollow'),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'mute',
                              child: Row(
                                children: [
                                  Icon(Icons.volume_off, color: Colors.blueAccent),
                                  SizedBox(width: 8),
                                  Text('Mute'),
                                ],
                              ),
                            ),
                          ];
                        },
                        onSelected: (value) {
                          // Handle each menu action
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
