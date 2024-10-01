import 'package:flutter/material.dart';
import 'package:cook/services/Userprofile_service.dart';
import 'package:cook/models/userprofileresponse_model.dart';
import 'package:cook/profile/profile_page.dart';
import 'package:cook/services/LoginService.dart';
import 'package:cook/login/login_page.dart';

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with SingleTickerProviderStateMixin {
  UserProfile? userProfile;
  final UserProfileService _userProfileService = UserProfileService();
  final LoginService _loginService = LoginService();
  int? userId;
  late AnimationController _controller;

  double _dragPosition = 0.0;
  bool _isMenuOpen = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _loadUserProfile() async {
    userId = await _loginService.getUserId();

    if (userId != null) {
      userProfile = await _userProfileService.fetchUserProfile(userId!);
      if (userProfile != null) {
        setState(() {});
      }
    } else {
      print('User ID is null, make sure user is logged in.');
    }
  }

  Future<void> _logout() async {
    await _loginService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _handleCloseMenu() {
    if (_isMenuOpen) {
      _controller.forward().then((value) {
        Navigator.pop(context);
        setState(() {
          _isMenuOpen = false;
        });
      });
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragPosition += details.delta.dx;
      // Limit drag position to the left
      if (_dragPosition > 0) {
        _dragPosition = 0; // Prevent dragging to the right
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragPosition < -MediaQuery.of(context).size.width * 0.4) {
      _handleCloseMenu();
    } else {
      setState(() {
        _dragPosition = 0; // Reset position if not dragged enough
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.3),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => _handleCloseMenu(),
            child: Container(
              color: Colors.transparent,
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            child: Transform.translate(
              offset: Offset(_dragPosition, 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: screenWidth * 0.8,
                height: screenHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.orange,
                    width: 3,
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                padding: EdgeInsets.all(screenWidth * 0.04),
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
                                  radius: screenWidth * 0.1,
                                  backgroundImage: NetworkImage(userProfile!.profilePic),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                Text(
                                  userProfile!.fullName,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.05,
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
                                    SizedBox(width: screenWidth * 0.08),
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
                            child: BouncingChefHat(),
                          ),
                    SizedBox(height: screenHeight * 0.03),
                    ListTile(
                      leading: Icon(Icons.people, color: Colors.orange, size: screenWidth * 0.07),
                      title: Text(
                        'Friends',
                        style: TextStyle(fontSize: screenWidth * 0.045),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.bookmark, color: Colors.orange, size: screenWidth * 0.07),
                      title: Text(
                        'Saved Post',
                        style: TextStyle(fontSize: screenWidth * 0.045),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.settings, color: Colors.orange, size: screenWidth * 0.07),
                      title: Text(
                        'Settings',
                        style: TextStyle(fontSize: screenWidth * 0.045),
                      ),
                      onTap: () {
                        // Navigate to Settings
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.feedback, color: Colors.orange, size: screenWidth * 0.07),
                      title: Text(
                        'Feedback',
                        style: TextStyle(fontSize: screenWidth * 0.045),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.help_outline, color: Colors.orange, size: screenWidth * 0.07),
                      title: Text(
                        'Help & Support',
                        style: TextStyle(fontSize: screenWidth * 0.045),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.privacy_tip, color: Colors.orange, size: screenWidth * 0.07),
                      title: Text(
                        'Privacy Policy',
                        style: TextStyle(fontSize: screenWidth * 0.045),
                      ),
                    ),
                    Spacer(),
                    ListTile(
                      leading: Icon(Icons.logout, color: Colors.orange, size: screenWidth * 0.07),
                      title: Text(
                        'Logout',
                        style: TextStyle(fontSize: screenWidth * 0.045),
                      ),
                      onTap: _logout,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BouncingChefHat extends StatefulWidget {
  @override
  _BouncingChefHatState createState() => _BouncingChefHatState();
}

class _BouncingChefHatState extends State<BouncingChefHat> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 20).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
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
          offset: Offset(0, -_animation.value),
          child: Icon(
            Icons.restaurant_menu,
            color: Colors.orangeAccent,
            size: 50.0,
          ),
        );
      },
    );
  }
}
