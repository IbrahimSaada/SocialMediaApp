import 'package:flutter/material.dart';
import '***REMOVED***/menu/editprofilepage.dart';
import 'dart:io';
import '***REMOVED***/services/LoginService.dart';
import '***REMOVED***/services/Userprofile_service.dart';
import '***REMOVED***/models/userprofileresponse_model.dart';
import '***REMOVED***/services/userpost_service.dart';
import '***REMOVED***/models/post_model.dart';


class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isPostsSelected = true;
  bool isLoading = false;
  bool isPaginating = false;
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
  final ScrollController _scrollController = ScrollController(); // Pagination controller

  final LoginService _loginService = LoginService();
  final UserProfileService _userProfileService = UserProfileService();
  final UserpostService _userpostService = UserpostService(); // Updated to use UserpostService

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
        // Fetch posts and bookmarks
        await _fetchUserPosts();
        await _fetchBookmarkedPosts();
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchUserPosts() async {
    try {
      if (userId != null) {
        setState(() {
          isPaginating = true; // Start showing pagination loading indicator
        });
        List<Post> newPosts = await _userpostService.fetchUserPosts(userId!, currentPageNumber, pageSize);
        setState(() {
          userPosts.addAll(newPosts); // Append new posts to the list
          currentPageNumber++; // Increment page number for the next fetch
          isPaginating = false; // Stop showing pagination loading indicator
        });
      }
    } catch (e) {
      print("Error fetching posts: $e");
      setState(() {
        isPaginating = false; // Stop pagination loading if there's an error
      });
    }
  }

  Future<void> _fetchBookmarkedPosts() async {
    try {
      if (userId != null) {
        List<Post> bookmarks = await _userpostService.fetchBookmarkedPosts(userId!, 1, 10); // Updated to use UserpostService
        setState(() {
          bookmarkedPosts = bookmarks;
        });
        print('Fetched bookmarks: ${bookmarkedPosts.length}');
      }
    } catch (e) {
      print("Error fetching bookmarks: $e");
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !isPaginating) {
      // User scrolled to the bottom, fetch more posts
      _fetchUserPosts();
    }
  }

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
      stars.add(Icon(Icons.star, color: Colors.orange, size: screenWidth * 0.05));
    }

    if (hasHalfStar) {
      stars.add(Icon(Icons.star_half, color: Colors.orange, size: screenWidth * 0.05));
    }

    int emptyStars = 5 - stars.length;
    for (int i = 0; i < emptyStars; i++) {
      stars.add(Icon(Icons.star_border, color: Colors.orange, size: screenWidth * 0.05));
    }

    return Row(children: stars);
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
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
                // Add settings functionality
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
                      ? NetworkImage(userProfile!.profilePic)
                      : AssetImage('assets/images/default.png'),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _openEditProfilePage,
                      child: Icon(
                        Icons.edit,
                        color: Colors.orangeAccent,
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
                    Icon(Icons.qr_code, size: screenWidth * 0.07, color: Colors.grey),
                  ],
                ),
                SizedBox(height: 10),
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
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
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
                  child: Text(
                    bio.isNotEmpty ? bio : 'No bio available',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
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
                  color: Colors.orange,
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
                SizedBox(height: 16),
                Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : isPostsSelected
                          ? _buildPosts(screenWidth)
                          : _buildSavedPosts(screenWidth),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildPosts(double screenWidth) {
    return GridView.builder(
      controller: _scrollController, // Attach the scroll controller for pagination
      padding: EdgeInsets.all(10.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: screenWidth * 0.02,
        mainAxisSpacing: screenWidth * 0.02,
      ),
      itemCount: userPosts.length + (isPaginating ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == userPosts.length) {
          return Center(child: CircularProgressIndicator()); // Show loading indicator at the bottom
        }
        final post = userPosts[index];
        return GestureDetector(
          onTap: () {
            _openFullPost(post);
          },
          child: _buildPostThumbnail(post),
        );
      },
    );
  }

  Widget _buildSavedPosts(double screenWidth) {
    return GridView.builder(
      padding: EdgeInsets.all(10.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: screenWidth * 0.02,
        mainAxisSpacing: screenWidth * 0.02,
      ),
      itemCount: bookmarkedPosts.length,
      itemBuilder: (context, index) {
        final post = bookmarkedPosts[index];
        return GestureDetector(
          onTap: () {
            _openFullPost(post);
          },
          child: _buildPostThumbnail(post),
        );
      },
    );
  }

 Widget _buildPostThumbnail(Post post) {
  if (post.media.isNotEmpty) {
    final firstMedia = post.media[0];

    if (firstMedia.mediaType == 'video') {
      return Stack(
        children: [
          Image.network(
            firstMedia.mediaUrl, // This is the thumbnail for the video
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackVideoThumbnail(); // Fallback if thumbnail doesn't load
            },
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Icon(
              Icons.play_circle_filled, // Video play icon
              color: Colors.white,
              size: 24, // Smaller video play icon
            ),
          ),
        ],
      );
    } else {
      // Handle image thumbnails
      return Image.network(
        firstMedia.mediaUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder(); // Fallback for image load failure
        },
      );
    }
  } else {
    // Caption post: No media, so show an orange background with "quote" design
    return Container(
      color: Colors.orange,
      child: Center(
        child: Icon(
          Icons.format_quote, // Quotation mark icon for captions
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }
}

// Fallback for video posts if thumbnail fails to load
Widget _buildFallbackVideoThumbnail() {
  return Container(
    color: Colors.black54, // Fallback background color for video
    child: Center(
      child: Icon(
        Icons.videocam, // Video camera icon as fallback
        color: Colors.white,
        size: 50,
      ),
    ),
  );
}

// Placeholder for other media load errors
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


  void _openFullPost(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullPostPage(post: post),
      ),
    );
  }
}

// Full Post Page to display the post details
class FullPostPage extends StatelessWidget {
  final Post post;

  const FullPostPage({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Details'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.media.isNotEmpty)
              if (post.media[0].mediaType == 'video')
                Container(
                  height: 200,
                  color: Colors.black,
                  child: Center(child: Icon(Icons.videocam, color: Colors.white, size: 100)),
                )
              else
                Image.network(post.media[0].mediaUrl),
            if (post.caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  post.caption,
                  style: TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
