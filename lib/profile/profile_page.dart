import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:io';
import 'package:cook/services/LoginService.dart';
import 'package:cook/services/Userprofile_service.dart';
import 'package:cook/models/userprofileresponse_model.dart';
import 'package:cook/services/userpost_service.dart';
import 'package:cook/models/post_model.dart';
import 'package:cook/profile/profilepostdetails.dart';
import 'package:cook/profile/editprofilepage.dart';
import 'package:cook/settings/settings_page.dart';
import 'package:cook/profile/post_grid.dart';         // Import the new PostGrid class
import 'package:cook/profile/bookmarked_grid.dart';   // Import the new BookmarkedGrid class
import 'package:cook/models/sharedpost_model.dart';
import 'shared_posts_grid.dart';
import 'shared_post_details_page.dart';
import 'package:cook/profile/followerspage.dart';
import 'package:cook/profile/followingpage.dart';
import 'qr_code.dart'; // Import the QRCodeModal
import 'package:cook/maintenance/expiredtoken.dart';
import 'package:cook/services/SessionExpiredException.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isPostsSelected = true;
  bool isSharedPostsSelected = false;
  bool isLoading = false;
  bool isPaginatingSharedPosts = false; // New state variable
  bool isPrivateAccount = false; // New state variable to track privacy status
  
  int currentSharedPostsPageNumber = 1; // New state variable
  List<SharedPostDetails> sharedPosts = []; // New state variable
  bool isPaginating = false;
  bool isPaginatingBookmarks = false;
  int currentBookmarkedPageNumber = 1;
  String username = '';
  String bio = '';
  File? profileImage;
  int? userId;
  double rating = 0.0;
  int postNb = 0;
  int followersNb = 0;
  int followingNb = 0;
  UserProfile? userProfile;
  List<Post> userPosts = [];
  List<Post> bookmarkedPosts = [];
  int currentPageNumber = 1;
  int pageSize = 10;
  final ScrollController _scrollController = ScrollController();
  final LoginService _loginService = LoginService();
  final UserProfileService _userProfileService = UserProfileService();
  final UserpostService _userpostService = UserpostService();

  bool showFullBio = false;

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
void _openSharedPostDetails(int index) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SharedPostDetailsPage(
        sharedPosts: sharedPosts, // The list of shared posts
        initialIndex: index,      // The index of the selected shared post
        isCurrentUserProfile: true, // This is the user's own profile
      ),
    ),
  );
}

Future<void> _loadUserProfile() async {
  setState(() {
    isLoading = true;
  });

  try {
    final isLoggedIn = await _loginService.isLoggedIn();
    if (isLoggedIn) {
      final userId = await _loginService.getUserId();
      if (userId != null) {
        userProfile = await _userProfileService.fetchUserProfile(userId);
        if (userProfile != null) {
          setState(() {
            this.userId = userId;
            username = userProfile!.fullName;
            bio = userProfile!.bio;
            rating = userProfile!.rating;
            postNb = userProfile!.postNb;
            followersNb = userProfile!.followersNb;
            followingNb = userProfile!.followingNb;
          });
        }

        await _fetchUserPosts();
        await _fetchBookmarkedPosts();
        await _fetchSharedPosts(); // Fetch shared posts
      }
    }
  } on SessionExpiredException {
    print("SessionExpired detected in this class");
    handleSessionExpired(context); // Trigger session expired dialog
  } catch (e) {
    print('Error loading user profile: $e');
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}
  
Future<void> _fetchSharedPosts() async {
  if (isPaginatingSharedPosts || userId == null) return;

  try {
    setState(() {
      isPaginatingSharedPosts = true;
    });

    int currentUserId = userId!;
    int viewerUserId = userId!; // Adjust if necessary

    List<SharedPostDetails> newSharedPosts = await _userpostService.fetchSharedPosts(
        currentUserId, viewerUserId, currentSharedPostsPageNumber, pageSize);
    setState(() {
      sharedPosts.addAll(newSharedPosts);
      currentSharedPostsPageNumber++;
      isPaginatingSharedPosts = false;
      isPrivateAccount = false; // Set to false since posts were fetched
    });
  } catch (e) {
    print("Error fetching shared posts: $e");
    setState(() {
      isPaginatingSharedPosts = false;
      if (e.toString().contains('Access denied')) {
        isPrivateAccount = true; // Set to true on privacy error
      }
    });
  }
}


Future<void> _fetchUserPosts() async {
  try {
    if (userId != null) {
      setState(() {
        isPaginating = true;
      });
      int viewerUserId = userId!; // Use the logged-in user's ID as the viewerUserId
      print("UserId is: $userId");
      
      List<Post> newPosts = await _userpostService.fetchUserPosts(
        userId!, 
        viewerUserId, 
        currentPageNumber, 
        pageSize
      );

      setState(() {
        userPosts.addAll(newPosts);
        currentPageNumber++;
        isPaginating = false;
      });
    }
  } on SessionExpiredException {
    print("SessionExpired detected in _fetchUserPosts");
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


  Future<void> _fetchBookmarkedPosts() async {
    if (isPaginatingBookmarks || userId == null) return;

    try {
      setState(() {
        isPaginatingBookmarks = true;
      });
      List<Post> newBookmarks = await _userpostService.fetchBookmarkedPosts(
          userId!, currentBookmarkedPageNumber, pageSize);
      setState(() {
        bookmarkedPosts.addAll(newBookmarks);
        currentBookmarkedPageNumber++;
        isPaginatingBookmarks = false;
      });
    } catch (e) {
      print("Error fetching bookmarks: $e");
      setState(() {
        isPaginatingBookmarks = false;
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (isPostsSelected && !isPaginating) {
        _fetchUserPosts();
      } else if (!isPostsSelected && !isPaginatingBookmarks) {
        _fetchBookmarkedPosts();
      }
    }
  }

  Future<void> _refreshUserProfile() async {
    // Reset the user profile data
    setState(() {
      userPosts.clear();
      bookmarkedPosts.clear();
      currentPageNumber = 1;
      currentBookmarkedPageNumber = 1;
    });

    await _loadUserProfile(); // Reload profile data
  }

  void _openEditProfilePage() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return EditProfilePage(
          currentUsername: username,
          currentBio: bio,
          currentImage: profileImage,
        );
      },
    );

    if (result != null) {
      setState(() {
        username = result['username'];
        bio = result['bio'];
        profileImage = result['imageFile'];
      });
    }
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
    String displayedBio = bio;
    if (!showFullBio && bio.length > 100) {
      displayedBio = bio.substring(0, 100) + '...';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          displayedBio.isNotEmpty ? displayedBio : 'No bio available',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            color: Colors.grey,
          ),
        ),
        if (bio.length > 100)
          GestureDetector(
            onTap: () {
              setState(() {
                showFullBio = !showFullBio;
              });
            },
            child: Text(
              showFullBio ? 'Show Less' : 'Show More',
              style: TextStyle(color: Color(0xFFF45F67), fontSize: screenWidth * 0.04),
            ),
          ),
      ],
    );
  }

void _openFullPost(int index) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ProfilePostDetails(
        userPosts: userPosts,
        bookmarkedPosts: bookmarkedPosts,
        initialIndex: index,
        userId: userId!,
        isPostsSelected: isPostsSelected,
        isCurrentUserProfile: true, // This is the user's own profile
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
        onRefresh: _refreshUserProfile,
        color: Color(0xFFF45F67), // Updated loading indicator color
        child: Stack(
          children: [
            Container(
              height: screenHeight * 0.28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF45F67), Color(0xFFF45F67).withOpacity(0.8)], // Using primary color
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
            Positioned(
              top: 50,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
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
                      GestureDetector(
                        onTap: _openEditProfilePage,
                        child: Icon(
                          Icons.edit,
                          color: Color(0xFFF45F67),
                          size: screenWidth * 0.07,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        username,
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: 10),
                     GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return QRCodeModal(qrCodeUrl: userProfile!.qrCode);
                          },
                        );
                      },
                      child: Icon(
                        Icons.qr_code,
                        size: screenWidth * 0.07,
                        color: Colors.grey,
                      ),
                    ),
                    ],
                  ),
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
                    child:     Container(
                    height: screenHeight * 0.15, // Adjust height as needed
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                    child: SingleChildScrollView(
                      child: _buildBioText(screenWidth), // Scrollable bio
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
                  Divider(color: Color(0xFFF45F67), thickness: 2),
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
                      SizedBox(width: screenWidth * 0.15),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isPostsSelected = false;
                            isSharedPostsSelected = false;
                          });
                        },
                        child: Icon(Icons.bookmark,
                            color: (!isPostsSelected && !isSharedPostsSelected) ? Color(0xFFF45F67) : Colors.grey,
                            size: screenWidth * 0.07),
                      ),
                      SizedBox(width: screenWidth * 0.15),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isSharedPostsSelected = true;
                            isPostsSelected = false;
                          });
                        },
                        child: Icon(
                          Icons.near_me,
                          color: isSharedPostsSelected ? Color(0xFFF45F67) : Colors.grey,
                          size: screenWidth * 0.07,
                        ),
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
                              : isSharedPostsSelected
                                  ? SharedPostsGrid(
                                    sharedPosts: sharedPosts,
                                    isPaginatingSharedPosts: isPaginatingSharedPosts,
                                    scrollController: _scrollController,
                                    screenWidth: screenWidth,
                                    openSharedPost: _openSharedPostDetails,
                                    isPrivateAccount: isPrivateAccount, // Pass the privacy status here
                                    )

                                  : BookmarkedGrid(
                                      bookmarkedPosts: bookmarkedPosts,
                                      isPaginatingBookmarks: isPaginatingBookmarks,
                                      scrollController: _scrollController,
                                      screenWidth: screenWidth,
                                      openFullPost: _openFullPost,
                                    ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildStatItem(String count, String label, double screenWidth) {
  return GestureDetector(
    onTap: () {
      if (userId != null) { // Check if userId is not null
        if (label == 'Followers') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FollowersPage(
                userId: userId!,
                viewerUserId: userId!, // Assuming it's the user's own profile
              ),
            ),
          );
        } else if (label == 'Following') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FollowingPage(
                userId: userId!,
                viewerUserId: userId!, // Same for following
              ),
            ),
          );
        }
      }
    },
    child: Column(
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
    ),
  );
}


}
