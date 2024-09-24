import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // For shimmer effect
import 'package:cook/models/SearchUserModel.dart';
import 'package:cook/services/search_service.dart';
import 'package:cook/services/loginservice.dart'; // Import LoginService
import 'package:cook/services/followService.dart'; // Import FollowService

class AddFriendsPage extends StatefulWidget {
  @override
  _AddFriendsPageState createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage> with TickerProviderStateMixin {
  List<SearchUserModel> users = [];
  Map<String, String> requestStatus = {};
  bool isLoading = true;
  bool isLoadingMore = false; // For infinite scroll
  final SearchService _searchService = SearchService();
  final LoginService _loginService = LoginService();
  final FollowService _followService = FollowService();
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFollowerRequests();
    _scrollController.addListener(_scrollListener); // Attach scroll listener
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Infinite scroll listener
  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !isLoadingMore) {
      _loadMoreFollowers();
    }
  }

  // Initial load of follower requests
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
      setState(() {
        isLoading = false;
      });
      print("Error loading follower requests: $e");
    }
  }

  // Load more follower requests for infinite scroll
  Future<void> _loadMoreFollowers() async {
    setState(() {
      isLoadingMore = true;
    });

    // You can implement pagination here later if necessary.
    
    setState(() {
      isLoadingMore = false;
    });
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
                                return _friendRequestCard(user.fullName, user.username, user.userId);
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

  // Shimmer effect while loading
  Widget _shimmerLoading() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  // Friend request card with buttons below the full name and orange shaded border
  Widget _friendRequestCard(String fullName, String username, int followedUserId) {
    final user = users.firstWhere((u) => u.username == username); // Find the user model for additional properties

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.orangeAccent, width: 2), // Orange border with shading
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 5,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: user.profilePic.isNotEmpty 
                  ? NetworkImage(user.profilePic) // Use NetworkImage if profilePic is a URL
                  : AssetImage('assets/profile.png') as ImageProvider, // Fallback to AssetImage if no profilePic
                radius: 28,
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '@$username',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          _actionButtons(username, followedUserId),
        ],
      ),
    );
  }

  // Action buttons placed below the full name
  Widget _actionButtons(String username, int followedUserId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
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
              print('Error while following: $e');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          ),
          child: Text('Follow', style: TextStyle(color: Colors.white)),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: () async {
            try {
              int? currentUserId = await _loginService.getUserId();
              if (currentUserId != null) {
                await _followService.cancelFollowerRequest(followedUserId, currentUserId);
                setState(() {
                  requestStatus[username] = 'Declined';
                });
              }
            } catch (e) {
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
}
