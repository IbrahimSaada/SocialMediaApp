import 'package:flutter/material.dart';
import '***REMOVED***/services/Userprofile_service.dart';
import '***REMOVED***/services/userpost_service.dart';
import '***REMOVED***/models/userprofileresponse_model.dart';
import '***REMOVED***/models/post_model.dart';
import '***REMOVED***/services/FollowService.dart';
import '***REMOVED***/models/FollowStatusResponse.dart'; // Import the FollowStatusResponse model
import '***REMOVED***/profile/profilepostdetails.dart';

class OtherUserProfilePage extends StatefulWidget {
  final int otherUserId; // Pass the ID of the other user

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

  bool isFollowing = false; // Follow/Unfollow status
  bool amFollowing = false; // Am I being followed

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
      // Fetch posts and bookmarks
      await _fetchUserPosts();
      await _fetchBookmarkedPosts();
      
      // Check follow status using the new method
      final followStatus = await _checkFollowStatus();
      if (followStatus != null) {
        setState(() {
          isFollowing = followStatus.isFollowing; // Current user follows other user
          amFollowing = followStatus.amFollowing; // Other user follows current user
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
      List<Post> newPosts = await _userpostService.fetchUserPosts(widget.otherUserId, currentPageNumber, pageSize);
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
      List<Post> newBookmarks = await _userpostService.fetchBookmarkedPosts(widget.otherUserId, currentBookmarkedPageNumber, pageSize);
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

  // New method to check follow status using the API
  Future<FollowStatusResponse?> _checkFollowStatus() async {
    int currentUserId = 1; // Replace with actual current user ID
    return await _userProfileService.checkFollowStatus(widget.otherUserId, currentUserId);
  }

  void _toggleFollow() async {
    setState(() {
      if (!isFollowing) {
        // If you are not following the other user, follow them
        isFollowing = true;

        // If the other user is already following you (amFollowing is true), this means it's a "Follow Back"
        if (amFollowing) {
          isFollowing = true; // Follow back action
        }
      } else {
        // If you are already following the user, unfollow them
        isFollowing = false;
      }
    });

    // Perform the follow/unfollow action in the backend
    if (isFollowing) {
      await _followService.followUser(1, widget.otherUserId); // Replace 1 with actual current user ID
    } else {
      await _followService.unfollowUser(1, widget.otherUserId); // Replace 1 with actual current user ID
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
          // Gradient Background
          Container(
            height: screenHeight * 0.28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orangeAccent, Colors.deepOrangeAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // White Container with Rounded Corners
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
          // Main Content
          Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.09),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // Profile Picture
                  CircleAvatar(
                    radius: screenWidth * 0.15, // Responsive radius
                    backgroundImage: userProfile != null
                        ? NetworkImage(userProfile!.profilePic)
                        : AssetImage('assets/images/default.png') as ImageProvider,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  // Username
                  Text(
                    username,
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  // Follow and Message Buttons
                  _buildFollowAndMessageButtons(screenWidth),
                  SizedBox(height: screenHeight * 0.01),
                  // Rating
                  _buildRating(screenWidth),
                  SizedBox(height: screenHeight * 0.01),
                  // Bio
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                    child: _buildBioText(screenWidth),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // Stats: Posts, Followers, Following
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
                  SizedBox(height: screenHeight * 0.02),
                  // Divider
                  Divider(
                    color: Colors.orange,
                    thickness: 2,
                  ),
                  // Toggle Icons: Posts and Bookmarks
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
                            color: isPostsSelected ? Colors.orange : Colors.grey,
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
                            color: !isPostsSelected ? Colors.orange : Colors.grey,
                            size: screenWidth * 0.07),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // Posts or Bookmarks
                  Container(
                    height: screenHeight * 0.5, // Adjust as needed
                    child: isLoading
                        ? Center(child: CircularProgressIndicator())
                        : isPostsSelected
                            ? _buildPosts(screenWidth)
                            : _buildSavedPosts(screenWidth),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Adjusted _buildFollowAndMessageButtons method with smaller buttons and responsive sizing
  Widget _buildFollowAndMessageButtons(double screenWidth) {
    String followButtonText = "FOLLOW"; // Default follow button text in uppercase
    Color followButtonColor = Colors.orange; // Default follow button color

    // Determine button text and color based on follow status
    if (amFollowing && !isFollowing) {
      followButtonText = "FOLLOW BACK";
      followButtonColor = Colors.orange;
    } else if (isFollowing && !amFollowing) {
      followButtonText = "FOLLOWING";
      followButtonColor = Colors.grey;
    } else if (!amFollowing && !isFollowing) {
      followButtonText = "FOLLOW";
      followButtonColor = Colors.orange;
    } else if (amFollowing && isFollowing) {
      followButtonText = "FOLLOWING";
      followButtonColor = Colors.orange;
    }

    // Further reduce the padding and font size based on screen width
    double buttonHorizontalPadding = screenWidth * 0.02; // Reduced from 0.03
    double buttonVerticalPadding = screenWidth * 0.01; // Reduced from 0.015
    double fontSize = screenWidth * 0.03; // Reduced from 0.035

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Follow Button
        ElevatedButton(
          onPressed: _toggleFollow,
          style: ElevatedButton.styleFrom(
            backgroundColor: followButtonColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Rounded corners
            ),
            padding: EdgeInsets.symmetric(
                horizontal: buttonHorizontalPadding,
                vertical: buttonVerticalPadding),
          ),
          child: Text(
            followButtonText,
            style: TextStyle(
              letterSpacing: 1.5,
              fontSize: fontSize,
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.02), // Reduced spacing
        // Message Button
        ElevatedButton(
          onPressed: () {
            // Handle message button tap here
            // For example, navigate to the message/chat page
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(153, 20, 8, 189), // Blue color
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Rounded corners
            ),
            padding: EdgeInsets.symmetric(
                horizontal: buttonHorizontalPadding,
                vertical: buttonVerticalPadding),
          ),
          child: Text(
            "MESSAGE",
            style: TextStyle(
              letterSpacing: 1.5,
              fontSize: fontSize,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the rating section with stars
  Row buildStars(double rating, double screenWidth) {
    rating = rating.clamp(0, 5); // Ensure rating is between 0 and 5

    List<Widget> stars = [];
    int fullStars = rating.floor(); // Full stars
    bool hasHalfStar = (rating - fullStars) >= 0.5; // Check if there's a half star

    // Add full stars
    for (int i = 0; i < fullStars; i++) {
      stars.add(Icon(Icons.star, color: Colors.orange, size: screenWidth * 0.05));
    }

    // Add half star if needed
    if (hasHalfStar) {
      stars.add(Icon(Icons.star_half, color: Colors.orange, size: screenWidth * 0.05));
    }

    // Add empty stars
    int emptyStars = 5 - stars.length;
    for (int i = 0; i < emptyStars; i++) {
      stars.add(Icon(Icons.star_border, color: Colors.orange, size: screenWidth * 0.05));
    }

    return Row(children: stars);
  }

  /// Builds the rating widget
  Widget _buildRating(double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(screenWidth * 0.02),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.02),
        buildStars(rating, screenWidth),
      ],
    );
  }

  /// Builds a single stat item (Posts, Followers, Following)
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

  /// Builds the bio text
  Widget _buildBioText(double screenWidth) {
    // Show full bio or truncated bio
    return Text(
      bio,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: screenWidth * 0.04,
        color: Colors.grey,
      ),
    );
  }

  /// Builds the grid of user posts
  Widget _buildPosts(double screenWidth) {
    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(screenWidth * 0.02),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: screenWidth * 0.02,
        mainAxisSpacing: screenWidth * 0.02,
      ),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: userPosts.length + (isPaginating ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == userPosts.length) {
          return Center(child: CircularProgressIndicator());
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

  /// Builds the grid of bookmarked posts
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
      padding: EdgeInsets.all(screenWidth * 0.02),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: screenWidth * 0.02,
        mainAxisSpacing: screenWidth * 0.02,
      ),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: bookmarkedPosts.length + (isPaginatingBookmarks ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == bookmarkedPosts.length) {
          return Center(child: CircularProgressIndicator());
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

  /// Builds a single post thumbnail
  Widget _buildPostThumbnail(Post post, double screenWidth) {
    if (post.media.isNotEmpty) {
      final firstMedia = post.media[0];

      if (firstMedia.mediaType == 'video') {
        return Stack(
          children: [
            Image.network(
              firstMedia.thumbnailurl ?? firstMedia.mediaUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackVideoThumbnail();
              },
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
        return Image.network(
          firstMedia.thumbnailurl ?? firstMedia.mediaUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorPlaceholder();
          },
        );
      }
    } else {
      // For caption-only posts
      return Container(
        color: Colors.orange,
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

  /// Fallback thumbnail for videos
  Widget _buildFallbackVideoThumbnail() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Icon(
          Icons.videocam,
          color: Colors.white,
          size: 50,
        ),
      ),
    );
  }

  /// Placeholder for image loading errors
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

  /// Opens the full post details page
  void _openFullPost(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePostDetails(
          userPosts: userPosts,
          initialIndex: index,
          userId: widget.otherUserId,
        ),
      ),
    );
  }
}
