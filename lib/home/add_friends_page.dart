import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cook/models/SearchUserModel.dart';
import 'package:cook/services/search_service.dart';
import 'package:cook/services/loginservice.dart';
import 'package:cook/services/followService.dart';
import 'package:cook/maintenance/expiredtoken.dart';
import 'package:cook/profile/otheruserprofilepage.dart';
import 'package:cook/profile/profile_page.dart';

void showBlockSnackbar(BuildContext context, String reason) {
  String message;
  if (reason.contains('You are blocked by the post owner')) {
    message = 'User blocked you';
  } else if (reason.contains('You have blocked the post owner')) {
    message = 'You blocked the user';
  } else if (reason.toLowerCase().contains('blocked')) {
    message = 'Action not allowed due to blocking';
  } else {
    message = 'Action not allowed.';
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
      duration: const Duration(seconds: 3),
    ),
  );
}

class AddFriendsPage extends StatefulWidget {
  @override
  _AddFriendsPageState createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage>
    with SingleTickerProviderStateMixin {
  List<SearchUserModel> users = [];
  List<SearchUserModel> contentRequests = [];
  bool isLoadingFollowRequests = true;
  bool isLoadingContentRequests = true;
  bool isLoadingMore = false;
  final SearchService _searchService = SearchService();
  final LoginService _loginService = LoginService();
  final FollowService _followService = FollowService();
  ScrollController _scrollController = ScrollController();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadFollowerRequests();
    _loadContentRequests();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !isLoadingMore) {
      _loadMoreFollowers();
    }
  }

  Future<void> _loadFollowerRequests() async {
    setState(() {
      isLoadingFollowRequests = true;
    });
    try {
      int? currentUserId = await _loginService.getUserId();
      if (currentUserId != null) {
        List<SearchUserModel> fetchedUsers =
            await _searchService.getFollowerRequests(currentUserId);
        setState(() {
          users = fetchedUsers;
          isLoadingFollowRequests = false;
        });
      } else {
        setState(() {
          isLoadingFollowRequests = false;
        });
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _loadContentRequests() async {
    setState(() {
      isLoadingContentRequests = true;
    });
    try {
      int? currentUserId = await _loginService.getUserId();
      if (currentUserId != null) {
        List<SearchUserModel> fetchedContentRequests =
            await _searchService.getPendingFollowRequests(currentUserId);
        setState(() {
          contentRequests = fetchedContentRequests;
          isLoadingContentRequests = false;
        });
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _loadMoreFollowers() async {
    setState(() {
      isLoadingMore = true;
    });
    await Future.delayed(Duration(seconds: 2)); // Simulate network delay
    try {
      int? currentUserId = await _loginService.getUserId();
      if (currentUserId != null) {
        List<SearchUserModel> moreUsers =
            await _searchService.getFollowerRequests(currentUserId);
        setState(() {
          users.addAll(moreUsers);
          isLoadingMore = false;
        });
      }
    } catch (e) {
      _handleError(e);
    } finally {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  void _handleError(dynamic e) {
    final errStr = e.toString();
    if (errStr.contains('Session expired')) {
      if (context.mounted) {
        handleSessionExpired(context);
      }
    } else if (errStr.startsWith('Exception: BLOCKED:') || errStr.toLowerCase().contains('blocked')) {
      // Extract reason
      String reason;
      if (errStr.startsWith('Exception: BLOCKED:')) {
        reason = errStr.replaceFirst('Exception: BLOCKED:', '');
      } else {
        reason = errStr;
      }
      showBlockSnackbar(context, reason);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}')),
      );
    }

    setState(() {
      isLoadingFollowRequests = false;
      isLoadingContentRequests = false;
      isLoadingMore = false;
    });
    print("Error: $e");
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

  Widget _friendRequestCard({
    required String fullName,
    required String username,
    required int userId,
    required String profilePic,
    required bool isFollowRequest,
  }) {
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
          // User Information
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  int? currentUserId = await _loginService.getUserId();
                  if (currentUserId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => currentUserId == userId
                            ? ProfilePage()
                            : OtherUserProfilePage(otherUserId: userId),
                      ),
                    );
                  }
                },
                child: CircleAvatar(
                  backgroundImage: profilePic.isNotEmpty
                      ? NetworkImage(profilePic)
                      : AssetImage('assets/profile.png') as ImageProvider,
                  radius: 30,
                  backgroundColor: Colors.transparent,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text('@$username',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Primary Action Button
              ElevatedButton(
                onPressed: () async {
                  if (isFollowRequest) {
                    await _handleFollowBack(userId, username);
                  } else {
                    await _handleApprove(userId, username);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF45F67),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  isFollowRequest ? 'Follow Back' : 'Approve',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              // Secondary Action Button
              OutlinedButton(
                onPressed: () async {
                  if (isFollowRequest) {
                    await _handleCancelRequest(userId, username);
                  } else {
                    await _handleDecline(userId, username);
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: Text(
                  isFollowRequest ? 'Cancel' : 'Decline',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleFollowBack(int userId, String username) async {
    try {
      int? currentUserId = await _loginService.getUserId();
      if (currentUserId != null) {
        await _followService.followUser(currentUserId, userId);
        setState(() {
          users.removeWhere((u) => u.username == username);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You have followed $username.')),
        );
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _handleCancelRequest(int userId, String username) async {
    try {
      int? currentUserId = await _loginService.getUserId();
      if (currentUserId != null) {
        await _followService.cancelFollowerRequest(userId, currentUserId);
        setState(() {
          users.removeWhere((u) => u.username == username);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Follow request to $username has been canceled.')),
        );
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _handleApprove(int userId, String username) async {
    try {
      int? currentUserId = await _loginService.getUserId();
      if (currentUserId != null) {
        await _followService.updateFollowerStatus(
            currentUserId, userId, 'approved');
        setState(() {
          contentRequests.removeWhere((u) => u.username == username);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$username\'s content request has been approved.')),
        );
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _handleDecline(int userId, String username) async {
    try {
      int? currentUserId = await _loginService.getUserId();
      if (currentUserId != null) {
        await _followService.updateFollowerStatus(
            currentUserId, userId, 'declined');
        setState(() {
          contentRequests.removeWhere((u) => u.username == username);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$username\'s content request has been declined.')),
        );
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Widget _buildFollowRequestsTab() {
    if (isLoadingFollowRequests) {
      return _shimmerLoading();
    } else if (users.isEmpty) {
      return Center(
          child: Text('No Follow Requests',
              style: TextStyle(fontSize: 18, color: Colors.grey)));
    } else {
      return ListView.builder(
        controller: _scrollController,
        itemCount: users.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == users.length) {
            return Center(
                child: CircularProgressIndicator(color: Color(0xFFF45F67)));
          }
          final user = users[index];
          return _friendRequestCard(
            fullName: user.fullName,
            username: user.username,
            userId: user.userId,
            profilePic: user.profilePic,
            isFollowRequest: true,
          );
        },
      );
    }
  }

  Widget _buildContentRequestsTab() {
    if (isLoadingContentRequests) {
      return _shimmerLoading();
    } else if (contentRequests.isEmpty) {
      return Center(
          child: Text('No Content Requests',
              style: TextStyle(fontSize: 18, color: Colors.grey)));
    } else {
      return ListView.builder(
        itemCount: contentRequests.length,
        itemBuilder: (context, index) {
          final user = contentRequests[index];
          return _friendRequestCard(
            fullName: user.fullName,
            username: user.username,
            userId: user.userId,
            profilePic: user.profilePic,
            isFollowRequest: false,
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Color(0xFFF45F67),
          elevation: 4,
          shadowColor: Colors.grey.shade200,
          leading: Padding(
            padding: const EdgeInsets.only(top: 20, left: 10),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              'Friends Request ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(top: 20, right: 15),
              child: Icon(Icons.local_dining, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Color(0xFFF45F67),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFFF45F67),
              labelPadding: EdgeInsets.symmetric(vertical: 8.0),
              tabs: [
                Text(
                  'Follow Requests',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Content Requests',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFollowRequestsTab(),
                _buildContentRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
