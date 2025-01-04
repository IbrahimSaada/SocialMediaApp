import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:io';
import 'package:myapp/services/LoginService.dart';
import 'package:myapp/services/Userprofile_service.dart';
import 'package:myapp/models/userprofileresponse_model.dart';
import 'package:myapp/services/userpost_service.dart';
import 'package:myapp/models/post_model.dart';
import 'package:myapp/profile/profilepostdetails.dart';
import 'package:myapp/profile/editprofilepage.dart';
import 'package:myapp/settings/settings_page.dart';
import 'package:myapp/profile/post_grid.dart';
import 'package:myapp/profile/bookmarked_grid.dart';
import 'package:myapp/models/sharedpost_model.dart';
import 'shared_posts_grid.dart';
import 'shared_post_details_page.dart';
import 'package:myapp/profile/followerspage.dart';
import 'package:myapp/profile/followingpage.dart';
import 'qr_code.dart';
import 'package:myapp/maintenance/expiredtoken.dart';
import 'package:myapp/services/SessionExpiredException.dart';
import '../services/blocked_user_exception.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isPostsSelected = true;
  bool isSharedPostsSelected = false;
  bool isLoading = false;
  bool isPaginatingSharedPosts = false;
  bool isPrivateAccount = false;

  bool isBlockedBy = false;
  bool isUserBlocked = false;

  int currentSharedPostsPageNumber = 1;
  List<SharedPostDetails> sharedPosts = [];
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
  bool hasMoreSharedPosts = true;
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
          sharedPosts: sharedPosts,
          initialIndex: index,
          isCurrentUserProfile: true,
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
          await _fetchSharedPosts();
        }
      }
    } on SessionExpiredException {
      print("SessionExpired detected in this class");
      handleSessionExpired(context);
    } catch (e) {
      print('Error loading user profile: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchSharedPosts() async {
    if (isPaginatingSharedPosts || userId == null || !hasMoreSharedPosts) return;

    print("[DEBUG] _fetchSharedPosts in ProfilePage started. userId=$userId");
    try {
      setState(() {
        isPaginatingSharedPosts = true;
      });

      int currentUserId = userId!;
      int viewerUserId = userId!;

      List<SharedPostDetails> newSharedPosts = await _userpostService.fetchSharedPosts(
        currentUserId,
        viewerUserId,
        currentSharedPostsPageNumber,
        pageSize,
      );

      setState(() {
        sharedPosts.addAll(newSharedPosts);
        currentSharedPostsPageNumber++;
        isPaginatingSharedPosts = false;

        if (newSharedPosts.length < pageSize) {
          hasMoreSharedPosts = false;
        }
      });
      print("[DEBUG] _fetchSharedPosts success. Loaded ${newSharedPosts.length} shared posts.");
    } on BlockedUserException catch (e) {
      print("[DEBUG] BlockedUserException caught in _fetchSharedPosts: reason=${e.reason}, "
          "isBlockedBy=${e.isBlockedBy}, isUserBlocked=${e.isUserBlocked}");
      setState(() {
        isPaginatingSharedPosts = false;
        isBlockedBy = e.isBlockedBy;
        isUserBlocked = e.isUserBlocked;
      });
      print("[DEBUG] After BlockedUserException: isBlockedBy=$isBlockedBy, "
          "isUserBlocked=$isUserBlocked, isPrivateAccount=$isPrivateAccount");
    } on PrivacyException catch (e) {
      print("[DEBUG] PrivacyException caught in _fetchSharedPosts: message=${e.message}");
      setState(() {
        isPrivateAccount = true;
        isPaginatingSharedPosts = false;
      });
      print("[DEBUG] After PrivacyException: isBlockedBy=$isBlockedBy, "
          "isUserBlocked=$isUserBlocked, isPrivateAccount=$isPrivateAccount");
    } on SessionExpiredException {
      print("[DEBUG] SessionExpiredException caught in _fetchSharedPosts");
      setState(() {
        isPaginatingSharedPosts = false;
      });
      handleSessionExpired(context);
    } catch (e) {
      print("[DEBUG] Unknown exception in _fetchSharedPosts: $e");
      setState(() {
        isPaginatingSharedPosts = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('An error occurred while fetching shared posts.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _fetchUserPosts() async {
    print("[DEBUG] _fetchUserPosts in ProfilePage started. userId=$userId");
    try {
      if (userId != null) {
        setState(() {
          isPaginating = true;
        });

        List<Post> newPosts = await _userpostService.fetchUserPosts(
          userId!,
          userId!,
          currentPageNumber,
          pageSize,
        );

        setState(() {
          userPosts.addAll(newPosts);
          currentPageNumber++;
          isPaginating = false;
        });
        print("[DEBUG] _fetchUserPosts success. Loaded ${newPosts.length} posts.");
      }
    } on BlockedUserException catch (e) {
      print("[DEBUG] BlockedUserException caught in _fetchUserPosts: reason=${e.reason}, "
          "isBlockedBy=${e.isBlockedBy}, isUserBlocked=${e.isUserBlocked}");
      setState(() {
        isPaginating = false;
        isBlockedBy = e.isBlockedBy;
        isUserBlocked = e.isUserBlocked;
      });
      print("[DEBUG] After BlockedUserException in _fetchUserPosts: "
          "isBlockedBy=$isBlockedBy, isUserBlocked=$isUserBlocked, isPrivateAccount=$isPrivateAccount");
    } on PrivacyException catch (e) {
      print("[DEBUG] PrivacyException caught in _fetchUserPosts: message=${e.message}");
      setState(() {
        isPrivateAccount = true;
        isPaginating = false;
      });
      print("[DEBUG] After PrivacyException in _fetchUserPosts: isBlockedBy=$isBlockedBy, "
          "isUserBlocked=$isUserBlocked, isPrivateAccount=$isPrivateAccount");
    } on SessionExpiredException {
      print("[DEBUG] SessionExpiredException caught in _fetchUserPosts");
      setState(() {
        isPaginating = false;
      });
      handleSessionExpired(context);
    } catch (e) {
      print("[DEBUG] Unknown exception in _fetchUserPosts: $e");
      setState(() {
        isPaginating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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
        userId!,
        currentBookmarkedPageNumber,
        pageSize,
      );
      setState(() {
        bookmarkedPosts.addAll(newBookmarks);
        currentBookmarkedPageNumber++;
        isPaginatingBookmarks = false;
      });
    } on SessionExpiredException {
      print("SessionExpired detected in _fetchBookmarkedPosts");
      setState(() {
        isPaginatingBookmarks = false;
      });
      handleSessionExpired(context);
    } catch (e) {
      print("Error fetching bookmarks: $e");
      setState(() {
        isPaginatingBookmarks = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('An error occurred while fetching bookmarked posts.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (isPostsSelected && !isPaginating) {
        _fetchUserPosts();
      } else if (!isPostsSelected &&
          !isSharedPostsSelected &&
          !isPaginatingBookmarks) {
        _fetchBookmarkedPosts();
      } else if (isSharedPostsSelected &&
          !isPaginatingSharedPosts &&
          hasMoreSharedPosts) {
        _fetchSharedPosts();
      }
    }
  }

  Future<void> _refreshUserProfile() async {
    setState(() {
      userPosts.clear();
      bookmarkedPosts.clear();
      sharedPosts.clear();
      currentPageNumber = 1;
      currentBookmarkedPageNumber = 1;
      currentSharedPostsPageNumber = 1;
      hasMoreSharedPosts = true;
    });

    await _loadUserProfile();
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
          isCurrentUserProfile: true,
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Container(
      color: Colors.grey[300],
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        return _buildShimmerEffect();
      },
    );
  }

  Widget _buildStatItem(String count, String label, double screenWidth) {
    return GestureDetector(
      onTap: () {
        if (userId != null) {
          if (label == 'Followers') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FollowersPage(
                  userId: userId!,
                  viewerUserId: userId!,
                ),
              ),
            );
          } else if (label == 'Following') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FollowingPage(
                  userId: userId!,
                  viewerUserId: userId!,
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
          const SizedBox(height: 5),
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

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      /// PREVENTS the background `Stack` from shifting up when keyboard appears:
      resizeToAvoidBottomInset: false,

      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _refreshUserProfile,
        color: const Color(0xFFF45F67),
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
                decoration: const BoxDecoration(
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
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Positioned(
              top: 50,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
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
                        : const AssetImage('assets/images/default.png') as ImageProvider,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _openEditProfilePage,
                        child: Icon(
                          Icons.edit,
                          color: const Color(0xFFF45F67),
                          size: screenWidth * 0.07,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Text(
                        username,
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      GestureDetector(
                        onTap: () {
                          if (userProfile != null && userProfile!.qrCode.isNotEmpty) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return QRCodeModal(qrCodeUrl: userProfile!.qrCode);
                              },
                            );
                          }
                        },
                        child: Icon(
                          Icons.qr_code,
                          size: screenWidth * 0.07,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF45F67).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFF45F67),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      buildStars(rating, screenWidth),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                    child: Container(
                      height: screenHeight * 0.15,
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                      child: SingleChildScrollView(
                        child: _buildBioText(screenWidth),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF45F67), thickness: 2),
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
                        child: Icon(
                          Icons.grid_on,
                          color: isPostsSelected ? const Color(0xFFF45F67) : Colors.grey,
                          size: screenWidth * 0.07,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.15),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isPostsSelected = false;
                            isSharedPostsSelected = false;
                          });
                        },
                        child: Icon(
                          Icons.bookmark,
                          color: (!isPostsSelected && !isSharedPostsSelected)
                              ? const Color(0xFFF45F67)
                              : Colors.grey,
                          size: screenWidth * 0.07,
                        ),
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
                          color: isSharedPostsSelected ? const Color(0xFFF45F67) : Colors.grey,
                          size: screenWidth * 0.07,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                                isPrivateAccount: isPrivateAccount,
                                isBlockedBy: isBlockedBy,
                                isUserBlocked: isUserBlocked,
                              )
                            : isSharedPostsSelected
                                ? SharedPostsGrid(
                                    sharedPosts: sharedPosts,
                                    isPaginatingSharedPosts: isPaginatingSharedPosts,
                                    hasMoreSharedPosts: hasMoreSharedPosts,
                                    scrollController: _scrollController,
                                    screenWidth: screenWidth,
                                    openSharedPost: _openSharedPostDetails,
                                    isPrivateAccount: isPrivateAccount,
                                    isBlockedBy: isBlockedBy,
                                    isUserBlocked: isUserBlocked,
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
}
