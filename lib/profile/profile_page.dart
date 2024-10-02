import 'package:flutter/material.dart';
import '***REMOVED***/profile/editprofilepage.dart';
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

  bool showFullBio = false; // Track if we are showing the full bio

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
          isPaginating = true;
        });
        List<Post> newPosts =
            await _userpostService.fetchUserPosts(userId!, currentPageNumber, pageSize);
        setState(() {
          userPosts.addAll(newPosts);
          currentPageNumber++;
          isPaginating = false;
        });
      }
    } catch (e) {
      print("Error fetching posts: $e");
      setState(() {
        isPaginating = false;
      });
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
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (isPostsSelected && !isPaginating) {
        _fetchUserPosts();
      } else if (!isPostsSelected && !isPaginatingBookmarks) {
        _fetchBookmarkedPosts();
      }
    }
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

  Widget _buildBioText(double screenWidth) {
    // Decide whether to show truncated bio or full bio
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
        if (bio.length > 100) // Show the "Show More" button if bio is longer than 100 chars
          GestureDetector(
            onTap: () {
              setState(() {
                showFullBio = !showFullBio; // Toggle between showing full and truncated bio
              });
            },
            child: Text(
              showFullBio ? 'Show Less' : 'Show More',
              style: TextStyle(color: Colors.orange, fontSize: screenWidth * 0.04),
            ),
          ),
      ],
    );
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
                  child: _buildBioText(screenWidth), // Use the bio builder method
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
        return Center(child: CircularProgressIndicator());
      }
      final post = userPosts[index];
      return GestureDetector(
        onTap: () {
          _openFullPost(post);
        },
        child: _buildPostThumbnail(post), // Updated to use the thumbnail
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
        return Center(child: CircularProgressIndicator());
      }
      final post = bookmarkedPosts[index];
      return GestureDetector(
        onTap: () {
          _openFullPost(post);
        },
        child: _buildPostThumbnail(post), // Updated to use the thumbnail
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
          // Use the thumbnail URL if available, else fallback to the media URL
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
            bottom: 8,
            right: 8,
            child: Icon(
              Icons.play_circle_filled,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      );
    } else {
      // If it's an image, just display it
      return Image.network(
        firstMedia.thumbnailurl ?? firstMedia.mediaUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder();
        },
      );
    }
  } else {
    // For caption-only posts, show a placeholder or icon
    return Container(
      color: Colors.orange,
      child: Center(
        child: Icon(
          Icons.format_quote,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }
}


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
