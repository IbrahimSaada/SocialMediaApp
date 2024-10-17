// otheruserprofilepage.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '***REMOVED***/services/Userprofile_service.dart';
import '***REMOVED***/services/userpost_service.dart';
import '***REMOVED***/models/userprofileresponse_model.dart';
import '***REMOVED***/models/post_model.dart';
import '***REMOVED***/services/FollowService.dart';
import '***REMOVED***/models/FollowStatusResponse.dart';
import '***REMOVED***/profile/profilepostdetails.dart';
import '***REMOVED***/models/sharedpost_model.dart';
import '***REMOVED***/services/LoginService.dart';
import '***REMOVED***/profile/post_grid.dart';
import '***REMOVED***/profile/shared_posts_grid.dart';
import '***REMOVED***/profile/shared_post_details_page.dart';
import '***REMOVED***/profile/followerspage.dart';
import '***REMOVED***/profile/followingpage.dart';
import '***REMOVED***/maintenance/expiredtoken.dart';
import '***REMOVED***/services/SessionExpiredException.dart';
import '***REMOVED***/profile/qr_code.dart';

class OtherUserProfilePage extends StatefulWidget {
  final int otherUserId;

  OtherUserProfilePage({required this.otherUserId});

  @override
  _OtherUserProfilePageState createState() => _OtherUserProfilePageState();
}

class _OtherUserProfilePageState extends State<OtherUserProfilePage> {
  bool isPostsSelected = true;
  bool isSharedPostsSelected = false;
  bool isLoading = false;
  bool isPaginating = false;
  bool isPaginatingSharedPosts = false;
  bool isPrivateAccount = false;
  bool isFollowersPublic = true;
  bool isFollowingPublic = true;
  bool isProfilePublic = true;
  int currentSharedPageNumber = 1;
  String username = '';
  String bio = '';
  double rating = 0.0;
  int postNb = 0;
  int followersNb = 0;
  int followingNb = 0;
  UserProfile? userProfile;
  List<Post> userPosts = [];
  List<SharedPostDetails> sharedPosts = [];
  int currentPageNumber = 1;
  int pageSize = 10;
  final ScrollController _scrollController = ScrollController();
  final UserProfileService _userProfileService = UserProfileService();
  final UserpostService _userpostService = UserpostService();
  final FollowService _followService = FollowService();
  final LoginService _loginService = LoginService();
  bool hasMoreSharedPosts = true;
  bool isFollowing = false;
  bool amFollowing = false;

  int? currentUserId; // To store the ID of the currently logged-in user

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Add a new method to show the QR Code Modal
void _showQRCode() {
  if (userProfile?.qrCode != null) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return QRCodeModal(qrCodeUrl: userProfile!.qrCode);
      },
    );
  } else {
    // Optional: Show a message if QR code is not available
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("QR code not available."),
        backgroundColor: Color(0xFFF45F67),
      ),
    );
  }
}

Future<void> _loadUserProfile() async {
  setState(() {
    isLoading = true;
  });

  currentUserId = await _loginService.getUserId();

  try {
    userProfile = await _userProfileService.fetchUserProfile(widget.otherUserId);

    if (userProfile != null) {
      setState(() {
        username = userProfile!.fullName;
        bio = userProfile!.bio;
        rating = userProfile!.rating;
        postNb = userProfile!.postNb;
        followersNb = userProfile!.followersNb;
        followingNb = userProfile!.followingNb;
      });

      // Fetch and update privacy settings
      Map<String, bool> privacySettings = await _userProfileService.checkProfilePrivacy(widget.otherUserId);
      setState(() {
        isProfilePublic = privacySettings['isPublic'] ?? false;
        isFollowersPublic = privacySettings['isFollowersPublic'] ?? false;
        isFollowingPublic = privacySettings['isFollowingPublic'] ?? false;
      });

      await _fetchUserPosts();
      await _fetchSharedPosts();

      final followStatus = await _checkFollowStatus();
      if (followStatus != null) {
        setState(() {
          isFollowing = followStatus.isFollowing;
          amFollowing = followStatus.amFollowing;
        });
      }
    } else {
      print('Failed to load user profile. Possibly due to session expiration.');
      handleSessionExpired(context);
    }
  } catch (e) {
    print("Error fetching user profile: $e");

    if (e.toString().contains('401')) { 
      handleSessionExpired(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An unexpected error occurred."),
          backgroundColor: Color(0xFFF45F65),
        ),
      );
    }
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

Future<void> _fetchUserPosts() async {
  if (isPaginating || currentUserId == null) return; // Ensure currentUserId is set

  try {
    setState(() {
      isPaginating = true;
    });
    
    // Fetch the user posts
    List<Post> newPosts = await _userpostService.fetchUserPosts(
      widget.otherUserId, 
      currentUserId!, 
      currentPageNumber, 
      pageSize
    );
    
    setState(() {
      userPosts.addAll(newPosts);
      currentPageNumber++;
      isPaginating = false;
    });
  } on SessionExpiredException {
    print("SessionExpired detected in _fetchUserPosts (OtherUserProfile)");
    // Handle session expiration
    handleSessionExpired(context); // Trigger session expired dialog or UI
  } catch (e) {
    print("Error fetching posts: $e");
    setState(() {
      isPaginating = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('An error occurred while fetching user posts.'),
      backgroundColor: Colors.red,
    ));
  }
}



Future<void> _fetchSharedPosts() async {
  if (isPaginatingSharedPosts || currentUserId == null || !hasMoreSharedPosts) return;

  try {
    setState(() {
      isPaginatingSharedPosts = true;
    });

    List<SharedPostDetails> newSharedPosts = await _userpostService.fetchSharedPosts(
      widget.otherUserId,
      currentUserId!,
      currentSharedPageNumber,
      pageSize,
    );

    setState(() {
      sharedPosts.addAll(newSharedPosts);
      currentSharedPageNumber++;
      isPaginatingSharedPosts = false;
      isPrivateAccount = false;

      // Check if we've received fewer items than pageSize
      if (newSharedPosts.length < pageSize) {
        hasMoreSharedPosts = false;
      }
    });
  } catch (e) {
    print("Error fetching shared posts: $e");
    setState(() {
      isPaginatingSharedPosts = false;
      if (e.toString().contains('Access denied')) {
        isPrivateAccount = true;
      }
    });
  }
}

void _scrollListener() {
  if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
    if (isPostsSelected && !isPaginating) {
      _fetchUserPosts();
    } else if (isSharedPostsSelected && !isPaginatingSharedPosts && hasMoreSharedPosts) {
      _fetchSharedPosts();
    }
  }
}


  Future<FollowStatusResponse?> _checkFollowStatus() async {
    currentUserId ??= await _loginService.getUserId(); // Ensure currentUserId is set
    if (currentUserId == null) {
      return null;
    }
    return await _userProfileService.checkFollowStatus(widget.otherUserId, currentUserId!);
  }

  void _toggleFollow() async {
    currentUserId ??= await _loginService.getUserId();
    if (currentUserId == null) {
      // Handle user not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You need to be logged in to follow users."),
          backgroundColor: Color(0xFFF45F67),
        ),
      );
      return;
    }

    setState(() {
      isFollowing = !isFollowing;
    });

    if (isFollowing) {
      await _followService.followUser(currentUserId!, widget.otherUserId);
    } else {
      await _followService.unfollowUser(currentUserId!, widget.otherUserId);
    }
  }

  // Adding refresh functionality
  Future<void> _refreshUserProfile() async {
    // Reset the user profile data
    setState(() {
      userPosts.clear();
      sharedPosts.clear();
      currentPageNumber = 1;
      currentSharedPageNumber = 1;
    });

    await _loadUserProfile(); // Reload profile data
  }

  void _showReportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Report User",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF45F67)
                ),
              ),
              Divider(color: Color(0xFFF45F67)),
              ListTile(
                title: Text('Spam'),
                leading: Icon(Icons.error, color: Color(0xFFF45F67)),
                onTap: () {
                  Navigator.pop(context);
                  _reportUser();
                },
              ),
              ListTile(
                title: Text('Harassment'),
                leading: Icon(Icons.report_problem, color: Color(0xFFF45F67)),
                onTap: () {
                  Navigator.pop(context);
                  _reportUser();
                },
              ),
              ListTile(
                title: Text('Inappropriate Content'),
                leading: Icon(Icons.block, color: Color(0xFFF45F67)),
                onTap: () {
                  Navigator.pop(context);
                  _reportUser();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _reportUser() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("User reported successfully!"),
        backgroundColor: Color(0xFFF45F67),
      ),
    );
  }

  void _openFullPost(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePostDetails(
          userPosts: userPosts,
          bookmarkedPosts: [], // No bookmarks
          initialIndex: index,
          userId: widget.otherUserId,
          isPostsSelected: true,
          isCurrentUserProfile: false, // This is not the current user's profile
        ),
      ),
    );
  }

  void _openSharedPostDetails(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SharedPostDetailsPage(
          sharedPosts: sharedPosts,
          initialIndex: index,
          isCurrentUserProfile: false, // // This is not the current user's profile
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        color: Colors.grey[300],
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      itemCount: 9,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        return _buildShimmerEffect();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _refreshUserProfile, // Pull-to-refresh functionality
        color: Color(0xFFF45F67), // loading indicator
        child: Stack(
          children: [
            Container(
              height: screenHeight * 0.28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF45F67), Color(0xFFF45F67).withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.18,
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
            // Three dots menu (More options)
            Positioned(
              top: 50,
              right: 10,
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.white),
                color: Colors.white,
                onSelected: (value) {
                  if (value == "report") {
                    _showReportOptions();
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: "report",
                      child: Text("Report User", style: TextStyle(color: Color(0xFFF45F67))),
                    ),
                    PopupMenuItem<String>(
                      value: "block",
                      child: Text("Block User", style: TextStyle(color: Color(0xFFF45F67))),
                    ),
                    PopupMenuItem<String>(
                      value: "share",
                      child: Text("Share Profile", style: TextStyle(color: Color(0xFFF45F67))),
                    ),
                  ];
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.09),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: userProfile != null
                        ? CachedNetworkImageProvider(userProfile!.profilePic)
                        : AssetImage('assets/images/default.png') as ImageProvider,
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        username,
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: 10),

                      // QR Code Icon with onTap functionality
                      GestureDetector(
                        onTap: _showQRCode,
                        child: Icon(
                          Icons.qr_code,
                          size: screenWidth * 0.07,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  // Keep the remaining widgets intact:
                  SizedBox(height: 10),
                  _buildFollowAndMessageButtons(screenWidth),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFFF45F67).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF45F67),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      buildStars(rating, screenWidth),
                    ],
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                    child: Container(
                      height: screenHeight * 0.07, // Set max height for scrollable area
                      child: SingleChildScrollView(
                        child: _buildBioText(screenWidth),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatItem(postNb.toString(), 'Posts', screenWidth),
                      SizedBox(width: screenWidth * 0.08),
                      _buildStatItem(followersNb.toString(), 'Followers', screenWidth),
                      SizedBox(width: screenWidth * 0.08),
                      _buildStatItem(followingNb.toString(), 'Following', screenWidth),
                    ],
                  ),
                  SizedBox(height: 16),
                  Divider(
                    color: Color(0xFFF45F67),
                    thickness: 2,
                  ),
                  // Grid Toggle Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isPostsSelected = true;
                            isSharedPostsSelected = false;
                          });
                        },
                        child: Icon(Icons.grid_on,
                            color: isPostsSelected ? Color(0xFFF45F67) : Colors.grey,
                            size: screenWidth * 0.07),
                      ),
                      SizedBox(width: screenWidth * 0.2),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isPostsSelected = false;
                            isSharedPostsSelected = true;
                          });
                        },
                        child: Icon(Icons.near_me,
                            color: isSharedPostsSelected ? Color(0xFFF45F67) : Colors.grey,
                            size: screenWidth * 0.07),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: isLoading
                        ? _buildShimmerGrid()
                        : isPostsSelected
                            ? PostGrid(
                              userPosts: userPosts,
                              isPaginating: isPaginating,
                              scrollController: _scrollController,
                              screenWidth: screenWidth,
                              openFullPost: _openFullPost,
                              isPrivateAccount: isPrivateAccount, // Pass privacy status here
                            )
                            : SharedPostsGrid(
                              sharedPosts: sharedPosts,
                              isPaginatingSharedPosts: isPaginatingSharedPosts,
                              hasMoreSharedPosts: hasMoreSharedPosts, // Pass the variable here
                              scrollController: _scrollController,
                              screenWidth: screenWidth,
                              openSharedPost: _openSharedPostDetails,
                              isPrivateAccount: isPrivateAccount,
                            )

                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowAndMessageButtons(double screenWidth) {
    String followButtonText = "FOLLOW";
    Color followButtonColor = Color(0xFFF45F67);

    if (amFollowing && !isFollowing) {
      followButtonText = "FOLLOW BACK";
      followButtonColor = Color(0xFFF45F67);
    } else if (isFollowing && !amFollowing) {
      followButtonText = "FOLLOWING";
      followButtonColor = Colors.grey.shade400;
    } else if (!amFollowing && !isFollowing) {
      followButtonText = "FOLLOW";
      followButtonColor = Color(0xFFF45F67);
    } else if (amFollowing && isFollowing) {
      followButtonText = "FOLLOWING";
      followButtonColor = Colors.grey.shade300;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _toggleFollow,
          style: ElevatedButton.styleFrom(
            backgroundColor: followButtonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.07,
              vertical: screenWidth * 0.025,
            ),
            elevation: 8,
          ),
          child: Text(
            followButtonText,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: screenWidth * 0.038,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.05),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Color(0xFFF45F67), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.07,
              vertical: screenWidth * 0.025,
            ),
          ),
          child: Text(
            "MESSAGE",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: screenWidth * 0.038,
              color: Color(0xFFF45F67),
            ),
          ),
        ),
      ],
    );
  }

  Row buildStars(double rating, double screenWidth) {
    rating = rating.clamp(0, 5);

    List<Widget> stars = [];
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    for (int i = 0; i < fullStars; i++) {
      stars.add(Icon(Icons.star, color: Color(0xFFF45F67), size: screenWidth * 0.05));
    }

    if (hasHalfStar) {
      stars.add(Icon(Icons.star_half, color: Color(0xFFF45F67), size: screenWidth * 0.05));
    }

    int emptyStars = 5 - stars.length;
    for (int i = 0; i < emptyStars; i++) {
      stars.add(Icon(Icons.star_border, color: Color(0xFFF45F67), size: screenWidth * 0.05));
    }

    return Row(children: stars);
  }

  Widget _buildBioText(double screenWidth) {
    return Text(
      bio,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: screenWidth * 0.04,
        color: Colors.grey,
      ),
    );
  }

Widget _buildStatItem(String count, String label, double screenWidth) {
  return GestureDetector(
    onTap: () {
      if (label == 'Followers' && isFollowersPublic) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FollowersPage(
              userId: widget.otherUserId,
              viewerUserId: currentUserId ?? 0,
            ),
          ),
        );
      } else if (label == 'Following' && isFollowingPublic) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FollowingPage(
              userId: widget.otherUserId,
              viewerUserId: currentUserId ?? 0,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("This list is private."),
            backgroundColor: Color(0xFFF45F67),
          ),
        );
      }
    },
    child: Column(
      children: [
        Text(
          (label == 'Followers' && !isFollowersPublic) || (label == 'Following' && !isFollowingPublic)
              ? '-'  // Display "-" if the list is private
              : count, // Show the actual count if public
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
    ),
  );
}

}
