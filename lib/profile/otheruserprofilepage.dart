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

class OtherUserProfilePage extends StatefulWidget {
  final int otherUserId;

  OtherUserProfilePage({required this.otherUserId});

  @override
  _OtherUserProfilePageState createState() => _OtherUserProfilePageState();
}

class _OtherUserProfilePageState extends State<OtherUserProfilePage> {
  bool isPostsSelected = true;
  bool isLoading = false;
  bool isPaginating = false;
  bool isPaginatingBookmarks = false;
  int currentBookmarkedPageNumber = 1;
  String username = '';
  String bio = '';
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
  final UserProfileService _userProfileService = UserProfileService();
  final UserpostService _userpostService = UserpostService();
  final FollowService _followService = FollowService();

  bool isFollowing = false;
  bool amFollowing = false;

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

  Future<void> _loadUserProfile() async {
    setState(() {
      isLoading = true;
    });

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
      await _fetchUserPosts();
      await _fetchBookmarkedPosts();

      final followStatus = await _checkFollowStatus();
      if (followStatus != null) {
        setState(() {
          isFollowing = followStatus.isFollowing;
          amFollowing = followStatus.amFollowing;
        });
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchUserPosts() async {
    try {
      setState(() {
        isPaginating = true;
      });
      List<Post> newPosts =
          await _userpostService.fetchUserPosts(widget.otherUserId, currentPageNumber, pageSize);
      setState(() {
        userPosts.addAll(newPosts);
        currentPageNumber++;
        isPaginating = false;
      });
    } catch (e) {
      print("Error fetching posts: $e");
      setState(() {
        isPaginating = false;
      });
    }
  }

  Future<void> _fetchBookmarkedPosts() async {
    if (isPaginatingBookmarks) return;

    try {
      setState(() {
        isPaginatingBookmarks = true;
      });
      List<Post> newBookmarks = await _userpostService.fetchBookmarkedPosts(
          widget.otherUserId, currentBookmarkedPageNumber, pageSize);
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

  Future<FollowStatusResponse?> _checkFollowStatus() async {
    int currentUserId = 1; // Replace with actual current user ID
    return await _userProfileService.checkFollowStatus(widget.otherUserId, currentUserId);
  }

  void _toggleFollow() async {
    setState(() {
      isFollowing = !isFollowing;
    });

    if (isFollowing) {
      await _followService.followUser(1, widget.otherUserId);
    } else {
      await _followService.unfollowUser(1, widget.otherUserId);
    }
  }

  // Adding refresh functionality
  Future<void> _refreshUserProfile() async {
    await _loadUserProfile(); // Reload the profile on refresh
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

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _refreshUserProfile, // Pull-to-refresh functionality
        color: Color(0xFFF45F67), //  loading indicator
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
            // Three dots menu (More options)
            Positioned(
              top: 50,
              right: 10,
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.white),
                color: Colors.white, // Orange and white theme
                onSelected: (value) {
                  if (value == "report") {
                    _showReportOptions(); // Show the report user options
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
                      Icon(Icons.qr_code, size: screenWidth * 0.07, color: Colors.grey),
                    ],
                  ),
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
                    child: _buildBioText(screenWidth),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isPostsSelected = true;
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
                          });
                        },
                        child: Icon(Icons.bookmark,
                            color: !isPostsSelected ? Color(0xFFF45F67) : Colors.grey,
                            size: screenWidth * 0.07),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: isLoading
                        ? _buildShimmerGrid()
                        : isPostsSelected
                            ? _buildPosts(screenWidth)
                            : _buildSavedPosts(screenWidth),
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
            borderRadius: BorderRadius.circular(30), // Softer border radius
          ),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.07,
            vertical: screenWidth * 0.025,
          ),
          elevation: 8, // Deeper shadow for elegance
        ),
        child: Text(
          followButtonText,
          style: TextStyle(
            fontWeight: FontWeight.w500, // Lighter weight for softer look
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
            borderRadius: BorderRadius.circular(30), // Matching radius
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
        SizedBox(height: screenWidth * 0.01),
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

  Widget _buildPosts(double screenWidth) {
    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(10.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: screenWidth * 0.02,
        mainAxisSpacing: screenWidth * 0.02,
      ),
      itemCount: userPosts.length + (isPaginating ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == userPosts.length) {
          return Center(child: CircularProgressIndicator(color: Color(0xFFF45F67))); // Orange loading indicator
        }
        final post = userPosts[index];
        return GestureDetector(
          onTap: () {
            _openFullPost(index);
          },
          child: _buildPostThumbnail(post, screenWidth),
        );
      },
    );
  }

  Widget _buildSavedPosts(double screenWidth) {
    if (bookmarkedPosts.isEmpty && !isPaginatingBookmarks) {
      return Center(
        child: Text(
          'No bookmarked posts yet',
          style: TextStyle(fontSize: screenWidth * 0.05, color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(10.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: screenWidth * 0.02,
        mainAxisSpacing: screenWidth * 0.02,
      ),
      itemCount: bookmarkedPosts.length + (isPaginatingBookmarks ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == bookmarkedPosts.length) {
          return Center(child: CircularProgressIndicator(color: Color(0xFFF45F67))); // Orange loading indicator
        }
        final post = bookmarkedPosts[index];
        return GestureDetector(
          onTap: () {
            _openFullPost(index);
          },
          child: _buildPostThumbnail(post, screenWidth),
        );
      },
    );
  }

  Widget _buildPostThumbnail(Post post, double screenWidth) {
    if (post.media.isNotEmpty) {
      final firstMedia = post.media[0];

      if (firstMedia.mediaType == 'video') {
        return Stack(
          children: [
            CachedNetworkImage(
              imageUrl: firstMedia.thumbnailurl ?? firstMedia.mediaUrl,  // Ensure this URL is valid
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => _buildShimmerEffect(), // Placeholder while loading
              errorWidget: (context, url, error) => _buildErrorPlaceholder(),  // Error widget
            ),
            Positioned(
              bottom: screenWidth * 0.02,
              right: screenWidth * 0.02,
              child: Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: screenWidth * 0.07,
              ),
            ),
          ],
        );
      } else {
        // If it's an image, display it
        return CachedNetworkImage(
          imageUrl: firstMedia.thumbnailurl ?? firstMedia.mediaUrl,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => _buildErrorPlaceholder(),
          placeholder: (context, url) => _buildShimmerEffect(),
        );
      }
    } else {
      // Handle caption-only posts
      return Container(
        color: Color(0xFFF45F67),
        child: Center(
          child: Icon(
            Icons.format_quote,
            color: Colors.white,
            size: screenWidth * 0.1,
          ),
        ),
      );
    }
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.error,
          color: Colors.red,
          size: 24,
        ),
      ),
    );
  }

  void _openFullPost(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePostDetails(
          userPosts: userPosts,  // Pass the userPosts list
          bookmarkedPosts: bookmarkedPosts, // Pass the bookmarkedPosts list
          initialIndex: index,  // Set the initial post index
          userId: widget.otherUserId,  // Pass the other user's ID
          isPostsSelected: isPostsSelected,  // Ensure whether posts or bookmarks are selected
        ),
      ),
    );
  }
}
