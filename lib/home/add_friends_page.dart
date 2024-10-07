import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cook/models/SearchUserModel.dart';
import 'package:cook/services/search_service.dart';
import 'package:cook/services/loginservice.dart';
import 'package:cook/services/followService.dart';
import 'package:cook/maintenance/expiredtoken.dart';
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
      if (e.toString().contains('Session expired')) {
        if (context.mounted) {
          handleSessionExpired(context);
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

    await Future.delayed(Duration(seconds: 2));

    try {
      List<SearchUserModel> moreUsers = await _searchService.getFollowerRequests(users.length);
      setState(() {
        users.addAll(moreUsers);
        isLoadingMore = false;
      });
    } catch (e) {
      if (e.toString().contains('Session expired')) {
        if (context.mounted) {
          handleSessionExpired(context);
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
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            height: 70,
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
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFF45F67), width: 2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFF45F67).withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 3,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  int? currentUserId = await _loginService.getUserId();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => currentUserId == followedUserId ? ProfilePage() : OtherUserProfilePage(otherUserId: followedUserId),
                    ),
                  );
                },
                child: CircleAvatar(
                  backgroundImage: AssetImage('assets/profile.png'),
                  radius: 30,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text('@$username', style: TextStyle(fontSize: 12, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _actionButtons(username, followedUserId, onDecline),
        ],
      ),
    );
  }

  Widget _actionButtons(String username, int followedUserId, Function(String) onDecline) {
    bool isFollowing = requestStatus[username] == 'Following';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
              if (e.toString().contains('Session expired')) {
                if (context.mounted) {
                  handleSessionExpired(context);
                }
              }
              print('Error while following: $e');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFF45F67),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(isFollowing ? 'Following' : 'Follow', style: TextStyle(color: Colors.white)),
        ),
        if (!isFollowing)
          OutlinedButton(
            onPressed: () async {
              try {
                int? currentUserId = await _loginService.getUserId();
                if (currentUserId != null) {
                  await _followService.cancelFollowerRequest(followedUserId, currentUserId);
                  setState(() {
                    requestStatus[username] = 'Declined';
                  });
                  onDecline(username);
                }
              } catch (e) {
                if (e.toString().contains('Session expired')) {
                  if (context.mounted) {
                    handleSessionExpired(context);
                  }
                }
                print('Error while canceling the follower request: $e');
              }
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Text('Decline', style: TextStyle(color: Colors.grey[700])),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: PreferredSize(
  preferredSize: Size.fromHeight(80),
  child: AppBar(
    backgroundColor: Colors.white,
    elevation: 4,
    shadowColor: Colors.grey.shade200,
    leading: Padding(
      padding: const EdgeInsets.only(top: 20, left: 10), // Adjust padding to lower the arrow
      child: IconButton(
        icon: Icon(Icons.arrow_back, color: Color(0xFFF45F67), size: 28),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    ),
    title: Padding(
      padding: const EdgeInsets.only(top: 20),  // Lower the title text
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Drop shadow effect for the cooking theme
          Text(
            'Add Friends',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,  // Base color for the "drop" layer
              shadows: [
                Shadow(
                  offset: Offset(-3, -3),
                  blurRadius: 0,
                  color: Color(0xFFF45F67),
                ),
                Shadow(
                  offset: Offset(0, 0),
                  blurRadius: 2,
                  color: Color(0xFFF45F67).withOpacity(0.8), // Main drop painting effect
                ),
              ],
            ),
          ),
          // Main visible text on top of the "drop"
          Text(
            'Add Friends',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    ),
    centerTitle: true,
    actions: [
      Padding(
        padding: const EdgeInsets.only(top: 20, right: 15),  // Position the cooking icon
        child: Icon(Icons.local_dining, color: Color(0xFFF45F67), size: 28),
      ),
    ],
    flexibleSpace: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF45F67), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    ),
  ),
),

      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white , Color(0xFFF45F67), Colors.white],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.zero, // Remove rounded edges at top
                    ),
                    child: isLoading
                        ? _shimmerLoading()
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: users.length + (isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == users.length && isLoadingMore) {
                                return Center(child: CircularProgressIndicator(color: Color(0xFFF45F67)));
                              }
                              final user = users[index];
                              return _friendRequestCard(
                                user.fullName,
                                user.username,
                                user.userId,
                                user.phoneNumber,
                                (username) {
                                  setState(() {
                                    users.removeWhere((u) => u.username == username);
                                  });
                                },
                              );
                            },
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
