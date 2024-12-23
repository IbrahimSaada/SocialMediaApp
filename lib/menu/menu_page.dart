import '***REMOVED***/menu/savedposts.dart';
import '***REMOVED***/settings/settings_page.dart';
import 'package:flutter/material.dart';
import '***REMOVED***/services/Userprofile_service.dart';
import '***REMOVED***/models/userprofileresponse_model.dart';
import '***REMOVED***/profile/profile_page.dart';
import '***REMOVED***/services/LoginService.dart';
import '***REMOVED***/login/login_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '***REMOVED***/maintenance/expiredtoken.dart';
import '***REMOVED***/services/SessionExpiredException.dart';
import '../profile/followingpage.dart';
import 'helpnsupport.dart';
import 'privacypolicy.dart';

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
    try {
      userProfile = await _userProfileService.fetchUserProfile(userId!);
      if (userProfile != null) {
        setState(() {});
      }
    } on SessionExpiredException {
      print("SessionExpired detected in menu.dart");
      handleSessionExpired(context); // Trigger session expired dialog
    } catch (e) {
      print('Error loading profile: $e'); // Log other errors
    }
  } else {
    print('User ID is null, make sure user is logged in.');
  }
}

Future<void> _logout() async {
  await _loginService.logout();
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => const LoginPage()),
    (route) => false, // This removes all previous routes from the stack
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
      if (_dragPosition > 0) {
        _dragPosition = 0;
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragPosition < -MediaQuery.of(context).size.width * 0.4) {
      _handleCloseMenu();
    } else {
      setState(() {
        _dragPosition = 0;
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
  final primaryColor = Color(0xFFF45F67); // Your primary color

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
                  color: primaryColor, // Updated color
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
                                backgroundImage: CachedNetworkImageProvider(userProfile!.profilePic),
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
                          child: BouncingChefHat(primaryColor: primaryColor),
                        ),
                  SizedBox(height: screenHeight * 0.03),
                  _buildMenuItem(
                    icon: Icons.people,
                    text: 'Friends',
                    color: primaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FollowingPage(
                            userId: userId!,
                            viewerUserId: userId!,
                          ),
                        ),
                      );
                    },
                  ),
                    _buildMenuItem(
                      icon: Icons.bookmark,
                      text: 'Saved Post',
                      color: primaryColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SavedPostsPage(userId: userId!),
                          ),
                        );
                      },
                    ),
                  _buildMenuItem(
                    icon: Icons.settings,
                    text: 'Settings',
                    color: primaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    text: 'Help & Support',
                    color: primaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HelpSupportPage()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.privacy_tip,
                    text: 'Privacy Policy',
                    color: primaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
                      );
                    },
                  ),
                  Spacer(),
                  _buildMenuItem(
                    icon: Icons.logout,
                    text: 'Logout',
                    color: primaryColor,
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


  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required Color color,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 24),
      title: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }
}

class BouncingChefHat extends StatefulWidget {
  final Color primaryColor;

  const BouncingChefHat({required this.primaryColor});

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
            color: widget.primaryColor,
            size: 50.0,
          ),
        );
      },
    );
  }
}
