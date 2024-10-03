import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cook/models/SearchUserModel.dart';
import 'package:cook/services/search_service.dart';
import 'package:cook/services/loginservice.dart';
import 'package:cook/services/followService.dart';
import 'package:cook/maintenance/expiredtoken.dart'; // Import the expired session handler
import 'package:cook/profile/otheruserprofilepage.dart';
import 'package:cook/profile/profile_page.dart';

class AddFriendsPage extends StatefulWidget {
  @override
  _AddFriendsPageState createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage> with TickerProviderStateMixin {
  List<SearchUserModel> users = [];
  Map<String, String> requestStatus = {};
  bool isLoading = true;
  bool isLoadingMore = false;
  final SearchService _searchService = SearchService();
  final LoginService _loginService = LoginService();
  final FollowService _followService = FollowService();
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFollowerRequests();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !isLoadingMore) {
      _loadMoreFollowers();
    }
  }

  Future<void> _loadFollowerRequests() async {
    try {
      int? currentUserId = await _loginService.getUserId();
      if (currentUserId != null) {
        List<SearchUserModel> fetchedUsers = await _searchService.getFollowerRequests(currentUserId);
        setState(() {
          users = fetchedUsers;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print("User ID not found");
      }
    } catch (e) {
      // Handle session expiration
      if (e.toString().contains('Session expired')) {
        if (context.mounted) {
          handleSessionExpired(context);  // Show session expired dialog
        }
      }
      setState(() {
        isLoading = false;
      });
      print("Error loading follower requests: $e");
    }
  }

  Future<void> _loadMoreFollowers() async {
    setState(() {
      isLoadingMore = true;
    });

    await Future.delayed(Duration(seconds: 2)); // Simulate a delay

    try {
      List<SearchUserModel> moreUsers = await _searchService.getFollowerRequests(users.length);
      setState(() {
        users.addAll(moreUsers); // Add more users to the list
        isLoadingMore = false;
      });
    } catch (e) {
      // Handle session expiration
      if (e.toString().contains('Session expired')) {
        if (context.mounted) {
          handleSessionExpired(context);  // Show session expired dialog
        }
      }
      print("Error loading more followers: $e");
    } finally {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  Widget _shimmerLoading() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 20), // Reduced vertical margin
            height: 70, // Reduced height
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

 Widget _friendRequestCard(String fullName, String username, int followedUserId, String phoneNumber, Function(String) onDecline) {
  return Container(
    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 20), // Reduced vertical margin
    padding: EdgeInsets.all(10), // Reduced padding
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.orange, width: 2),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.orange.withOpacity(0.3),
          blurRadius: 10, // Reduced blur radius
          spreadRadius: 3, // Reduced spread radius
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () async {
            int? currentUserId = await _loginService.getUserId(); // Fetch current user ID
            if (currentUserId == followedUserId) {
              // If the tapped user is the logged-in user, navigate to ProfilePage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(), // Navigate to ProfilePage
                ),
              );
            } else {
              // If the tapped user is another user, navigate to OtherUserProfilePage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OtherUserProfilePage(
                    otherUserId: followedUserId, // Navigate to other user's profile
                  ),
                ),
              );
            }
          },
          child: CircleAvatar(
            backgroundImage: AssetImage('assets/profile.png'),
            radius: 25, // Reduced radius
          ),
        ),
        SizedBox(width: 10), // Reduced spacing
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: TextStyle(
                            fontSize: 16, // Reduced font size
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text('@$username', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        SizedBox(height: 2), // Reduced spacing
                        Text(phoneNumber, style: TextStyle(fontSize: 10, color: Colors.grey[800])),
                      ],
                    ),
                  ),
                  // Action buttons on the same line
                  _actionButtons(username, followedUserId, onDecline),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


  Widget _actionButtons(String username, int followedUserId, Function(String) onDecline) {
    bool isFollowing = requestStatus[username] == 'Following';

    return Row(
      children: [
        ElevatedButton(
          onPressed: () async {
            try {
              int? currentUserId = await _loginService.getUserId();
              if (currentUserId != null) {
                await _followService.followUser(currentUserId, followedUserId);
                setState(() {
                  requestStatus[username] = 'Following';
                });
              }
            } catch (e) {
              // Handle session expiration
              if (e.toString().contains('Session expired')) {
                if (context.mounted) {
                  handleSessionExpired(context);  // Show session expired dialog
                }
              }
              print('Error while following: $e');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(isFollowing ? 'Following' : 'Follow', style: TextStyle(color: Colors.white)),
        ),
        SizedBox(width: 5), // Reduced spacing
        if (!isFollowing) // Show "Decline" button only if not following
          ElevatedButton(
            onPressed: () async {
              try {
                int? currentUserId = await _loginService.getUserId();
                if (currentUserId != null) {
                  await _followService.cancelFollowerRequest(followedUserId, currentUserId);
                  setState(() {
                    requestStatus[username] = 'Declined';
                  });
                  onDecline(username); // Call the decline function
                }
              } catch (e) {
                // Handle session expiration
                if (e.toString().contains('Session expired')) {
                  if (context.mounted) {
                    handleSessionExpired(context);  // Show session expired dialog
                  }
                }
                print('Error while canceling the follower request: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            ),
            child: Text('Decline', style: TextStyle(color: Colors.white)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.orangeAccent.shade200,
                  Colors.deepOrangeAccent,
                  Colors.white,
                ],
                stops: [0.1, 0.4, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Add Friends" header with classy font and icons
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu, color: Colors.white, size: 30),
                      SizedBox(width: 10),
                      Text(
                        'Add Friends',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Metropolis', // Classy font style
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.restaurant_menu, color: Colors.white, size: 30),
                    ],
                  ),
                ),
                // Main content
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: isLoading
                        ? _shimmerLoading() // Show shimmer while loading
                        : NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification scrollInfo) {
                              if (!isLoadingMore && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                                _loadMoreFollowers();
                              }
                              return true;
                            },
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: users.length + (isLoadingMore ? 1 : 0), // Add loading indicator at the bottom if loading more
                              itemBuilder: (context, index) {
                                if (index == users.length && isLoadingMore) {
                                  return Center(child: CircularProgressIndicator());
                                }
                                final user = users[index];
                                return _friendRequestCard(
                                  user.fullName,
                                  user.username,
                                  user.userId,
                                  user.phoneNumber,
                                  (username) {
                                    setState(() {
                                      // Remove the user from the list when declined
                                      users.removeWhere((u) => u.username == username);
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
