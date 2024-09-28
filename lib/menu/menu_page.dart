import 'package:flutter/material.dart';
import 'package:cook/services/Userprofile_service.dart';
import 'package:cook/models/userprofileresponse_model.dart';
import 'package:cook/menu/profile_page.dart';
import 'package:cook/services/LoginService.dart'; // Import LoginService for logout
import 'package:cook/login/login_page.dart'; // Import LoginPage for navigation after logout

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  UserProfile? userProfile;
  final UserProfileService _userProfileService = UserProfileService();
  final LoginService _loginService = LoginService(); // Initialize login service
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // Load user profile when menu opens
  }

  Future<void> _loadUserProfile() async {
    // Fetch the signed-in user's ID from LoginService
    userId = await _loginService.getUserId();

    if (userId != null) {
      // Fetch the user profile using the fetched userId
      userProfile = await _userProfileService.fetchUserProfile(userId!);

      if (userProfile != null) {
        setState(() {
          // Once profile data is loaded, UI is refreshed
        });
      }
    } else {
      print('User ID is null, make sure user is logged in.');
    }
  }

  Future<void> _logout() async {
    await _loginService.logout(); // Call the logout function
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()), // Navigate to the login page
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          // Detect right-to-left swipe and close menu without transition
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04), // Dynamic padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              userProfile != null
                  ? GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: screenWidth * 0.1, // Responsive size for profile picture
                            backgroundImage: NetworkImage(userProfile!.profilePic),
                          ),
                          SizedBox(height: screenHeight * 0.02), // Responsive spacing
                          Text(
                            userProfile!.fullName,
                            style: TextStyle(
                              fontSize: screenWidth * 0.05, // Responsive font size
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '${userProfile!.followersNb}',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const Text(
                                    'Followers',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              SizedBox(width: screenWidth * 0.08), // Dynamic spacing
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '${userProfile!.followingNb}',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const Text(
                                    'Following',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: BouncingChefHat(), // Custom animated loading indicator
                    ),
              SizedBox(height: screenHeight * 0.03), // Dynamic spacing
              // Menu options like Friends, Saved Posts, Settings, etc.
              ListTile(
                leading: Icon(Icons.people, color: Colors.orange, size: screenWidth * 0.07),
                title: Text(
                  'Friends',
                  style: TextStyle(fontSize: screenWidth * 0.045), // Responsive text size
                ),
              ),
              ListTile(
                leading: Icon(Icons.bookmark, color: Colors.orange, size: screenWidth * 0.07),
                title: Text(
                  'Saved Post',
                  style: TextStyle(fontSize: screenWidth * 0.045), // Responsive text size
                ),
              ),
              ListTile(
                leading: Icon(Icons.settings, color: Colors.orange, size: screenWidth * 0.07),
                title: Text(
                  'Settings',
                  style: TextStyle(fontSize: screenWidth * 0.045), // Responsive text size
                ),
                onTap: () {
                  // Navigate to Settings
                },
              ),
              ListTile(
                leading: Icon(Icons.feedback, color: Colors.orange, size: screenWidth * 0.07),
                title: Text(
                  'Feedback',
                  style: TextStyle(fontSize: screenWidth * 0.045), // Responsive text size
                ),
              ),
              ListTile(
                leading: Icon(Icons.help_outline, color: Colors.orange, size: screenWidth * 0.07),
                title: Text(
                  'Help & Support',
                  style: TextStyle(fontSize: screenWidth * 0.045), // Responsive text size
                ),
              ),
              ListTile(
                leading: Icon(Icons.privacy_tip, color: Colors.orange, size: screenWidth * 0.07),
                title: Text(
                  'Privacy Policy',
                  style: TextStyle(fontSize: screenWidth * 0.045), // Responsive text size
                ),
              ),
              Spacer(), // Push the logout option to the bottom
              ListTile(
                leading: Icon(Icons.logout, color: Colors.orange, size: screenWidth * 0.07),
                title: Text(
                  'Logout',
                  style: TextStyle(fontSize: screenWidth * 0.045), // Responsive text size
                ),
                onTap: _logout, // Call the logout function on tap
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BouncingChefHat extends StatefulWidget {
  @override
  _BouncingChefHatState createState() => _BouncingChefHatState();
}

class _BouncingChefHatState extends State<BouncingChefHat>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Bouncing duration
    )..repeat(reverse: true); // Repeat the animation back and forth

    _animation = Tween<double>(begin: 0, end: 20).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut, // Smooth ease in and out bounce
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_animation.value), // Bounce vertically
          child: Icon(
            Icons.restaurant_menu, // Chef-related icon
            color: Colors.orangeAccent,
            size: 50.0, // Icon size
          ),
        );
      },
    );
  }
}
