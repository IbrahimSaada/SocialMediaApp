import 'package:flutter/material.dart';
import '***REMOVED***/menu/editprofilepage.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isPostsSelected = true;

  // Example list of images for the posts grid
  final List<String> imageUrls = [
    'assets/images/food1.jpg',
    'assets/images/food2.jpeg',
    'assets/images/food3.jpg',
    'assets/images/food4.jpg',
    'assets/images/food5.jpg',
  ];

  // Added variables for username, bio, and profileImage
  String username = 'Omar Mohamed';
  String bio = 'Hi, my name is Omar Mohamed, I am a robotics teacher!! It\'s my greatest passion in life.';
  File? profileImage;
void _openEditProfilePage() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditProfilePage(
        currentUsername: username,
        currentBio: bio,
        currentImage: profileImage,
      ),
    ),
  );

  if (result != null) {
    setState(() {
      username = result['username']; // Update username
      bio = result['bio'];           // Update bio
      profileImage = result['imageFile']; // Update profile image
    });
  }


    if (result != null) {
      setState(() {
        username = result['username'];
        bio = result['bio'];
        profileImage = result['imageFile'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Orange Background positioned higher
          Container(
            height: screenHeight * 0.28, // Slightly higher
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orangeAccent, Colors.deepOrangeAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Curved White Container
          Positioned(
            top: screenHeight * 0.18, // Positioned higher to free up space for posts
            left: 0,
            right: 0,
            child: Container(
              height: screenHeight * 0.8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(60),
                  topRight: Radius.circular(60),
                ),
              ),
            ),
          ),
          // Back Button
          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          // Settings Icon
          Positioned(
            top: 50,
            right: 10,
            child: IconButton(
              icon: Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                // Add settings functionality
              },
            ),
          ),
          // Profile Details with Username Centered and Pencil & QR Code beside each other
          Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.09),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // Profile Picture
                CircleAvatar(
                  radius: 60,
                  backgroundImage: profileImage != null
                      ? FileImage(profileImage!)
                      : AssetImage('assets/images/omar.jpeg'),
                ),
                SizedBox(height: 10),
                // Name, QR Code, and Pencil Icon centered
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pencil Icon for Profile Editing
                    GestureDetector(
                      onTap: _openEditProfilePage,
                      child: Icon(Icons.edit, color: Colors.orangeAccent, size: screenWidth * 0.07),
                    ),
                    SizedBox(width: 10),
                    Text(
                      username, // Updated username
                      style: TextStyle(
                        fontSize: screenWidth * 0.06, // Responsive font size
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.qr_code, size: screenWidth * 0.07, color: Colors.grey),
                  ],
                ),
                SizedBox(height: 10),
                // Enhanced Rating Design
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '4.5',
                        style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.orange, size: screenWidth * 0.05),
                        Icon(Icons.star, color: Colors.orange, size: screenWidth * 0.05),
                        Icon(Icons.star, color: Colors.orange, size: screenWidth * 0.05),
                        Icon(Icons.star, color: Colors.orange, size: screenWidth * 0.05),
                        Icon(Icons.star_half, color: Colors.orange, size: screenWidth * 0.05),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
                // Bio text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Text(
                    bio, // Updated bio
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: screenWidth * 0.03, color: Colors.grey[700]),
                  ),
                ),
                SizedBox(height: 16),
                // Stats (Posts, Followers, Following) after bio
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatItem('5', 'Posts', screenWidth),
                    SizedBox(width: screenWidth * 0.08), // Responsive spacing between stats
                    _buildStatItem('100', 'Followers', screenWidth),
                    SizedBox(width: screenWidth * 0.08),
                    _buildStatItem('200', 'Following', screenWidth),
                  ],
                ),
                SizedBox(height: 16),
                // Orange Divider Line (full width)
                Divider(
                  color: Colors.orange,
                  thickness: 2,
                  indent: 0,
                  endIndent: 0, // Full-width divider line
                ),
                // Toggle between Posts and Saved Posts (without text)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isPostsSelected = true;
                        });
                      },
                      child: Icon(Icons.grid_on, color: isPostsSelected ? Colors.orange : Colors.grey, size: screenWidth * 0.07),
                    ),
                    SizedBox(width: screenWidth * 0.2), // More space between icons
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isPostsSelected = false;
                        });
                      },
                      child: Icon(Icons.bookmark, color: !isPostsSelected ? Colors.orange : Colors.grey, size: screenWidth * 0.07),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Display posts or saved posts based on selection
                Expanded(
                  child: isPostsSelected ? _buildPosts(screenWidth) : _buildSavedPosts(screenWidth),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for building the stats widgets (Posts, Followers, Following)
  Widget _buildStatItem(String count, String label, double screenWidth) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.03,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // Example posts grid (real images)
  Widget _buildPosts(double screenWidth) {
    return GridView.builder(
      padding: EdgeInsets.all(10.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: screenWidth * 0.02, // Reduced spacing
        mainAxisSpacing: screenWidth * 0.02,
      ),
      itemCount: imageUrls.length, // Number of media posts
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.asset(imageUrls[index], fit: BoxFit.cover), // Real images as per your request
        );
      },
    );
  }

  // Example saved posts grid (same real images)
  Widget _buildSavedPosts(double screenWidth) {
    return GridView.builder(
      padding: EdgeInsets.all(10.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: screenWidth * 0.02, // Reduced spacing
        mainAxisSpacing: screenWidth * 0.02,
      ),
      itemCount: imageUrls.length, // Number of saved posts
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.asset(imageUrls[index], fit: BoxFit.cover), // Real images for saved posts
        );
      },
    );
  }
}
