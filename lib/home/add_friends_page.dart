import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// Replace these imports with your actual files
import '***REMOVED***/models/SearchUserModel.dart';
import '***REMOVED***/services/search_service.dart';
import '***REMOVED***/services/loginservice.dart';
import '***REMOVED***/services/followService.dart';
import '***REMOVED***/maintenance/expiredtoken.dart';  // For session expired
import '***REMOVED***/profile/otheruserprofilepage.dart';
import '***REMOVED***/profile/profile_page.dart';

// Session expired exception, or you can just check for status code 401, etc.
import '***REMOVED***/services/SessionExpiredException.dart';

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
  const AddFriendsPage({Key? key}) : super(key: key);

  @override
  _AddFriendsPageState createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage>
    with SingleTickerProviderStateMixin {
  /// Follower requests (people you may want to follow back).
  List<SearchUserModel> users = [];

  /// Content requests (users requesting to follow your content).
  List<SearchUserModel> contentRequests = [];

  /// Loading states
  bool isLoadingFollowRequests = true;
  bool isLoadingContentRequests = true;
  bool isLoadingMore = false;

  /// For pagination control (if your API actually supports pages).
  int currentFollowPage = 1;
  bool hasMoreFollowers = true;

  final SearchService _searchService = SearchService();
  final LoginService _loginService = LoginService();
  final FollowService _followService = FollowService();

  /// Scroll controller for "Follow Requests" tab
  final ScrollController _scrollController = ScrollController();

  /// Tab controller for switching between "Follow Requests" & "Content Requests"
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadFollowerRequests(page: currentFollowPage);
    _loadContentRequests();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Listen to the scroll in "Follow Requests" tab to load more followers.
  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !isLoadingMore &&
        hasMoreFollowers) {
      currentFollowPage++;
      _loadMoreFollowers(page: currentFollowPage);
    }
  }

  /// Initial load of follower requests.
  Future<void> _loadFollowerRequests({int page = 1}) async {
    setState(() {
      isLoadingFollowRequests = true;
      hasMoreFollowers = true;
    });
    try {
      final currentUserId = await _loginService.getUserId();
      if (currentUserId != null) {
        // In real usage, pass page to your searchService if it supports pagination.
        final fetchedUsers =
            await _searchService.getFollowerRequests(currentUserId);

        setState(() {
          // Remove duplicates
          final newUniqueUsers = fetchedUsers.where((fUser) {
            return !users.any((existing) => existing.userId == fUser.userId);
          }).toList();
          users.addAll(newUniqueUsers);

          // If we got none, no more pages.
          if (newUniqueUsers.isEmpty) {
            hasMoreFollowers = false;
          }
          isLoadingFollowRequests = false;
        });
      } else {
        setState(() {
          isLoadingFollowRequests = false;
          hasMoreFollowers = false;
        });
      }
    } on SessionExpiredException {
      // Handle session expired
      if (mounted) handleSessionExpired(context);
    } catch (e) {
      _handleError(e);
    }
  }

  /// Load content requests.
  Future<void> _loadContentRequests() async {
    setState(() {
      isLoadingContentRequests = true;
    });
    try {
      final currentUserId = await _loginService.getUserId();
      if (currentUserId != null) {
        final fetched = await _searchService.getPendingFollowRequests(currentUserId);
        setState(() {
          contentRequests = fetched;
          isLoadingContentRequests = false;
        });
      } else {
        setState(() {
          isLoadingContentRequests = false;
        });
      }
    } on SessionExpiredException {
      if (mounted) handleSessionExpired(context);
    } catch (e) {
      _handleError(e);
    }
  }

  /// Load more followers (pagination).
  Future<void> _loadMoreFollowers({int page = 2}) async {
    setState(() {
      isLoadingMore = true;
    });

    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    try {
      final currentUserId = await _loginService.getUserId();
      if (currentUserId != null) {
        final moreUsers =
            await _searchService.getFollowerRequests(currentUserId);

        setState(() {
          // Filter duplicates by userId
          final newUniqueUsers = moreUsers.where((mUser) {
            return !users.any((existing) => existing.userId == mUser.userId);
          }).toList();
          users.addAll(newUniqueUsers);

          // If we got none, no more pages
          if (newUniqueUsers.isEmpty) {
            hasMoreFollowers = false;
          }
          isLoadingMore = false;
        });
      }
    } on SessionExpiredException {
      if (mounted) handleSessionExpired(context);
    } catch (e) {
      _handleError(e);
    } finally {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  /// Handle errors: Session expired, blocked, or general.
  void _handleError(dynamic e) {
    final errStr = e.toString();
    if (errStr.startsWith('Exception: BLOCKED:') ||
        errStr.toLowerCase().contains('blocked')) {
      // Extract reason
      String reason;
      if (errStr.startsWith('Exception: BLOCKED:')) {
        reason = errStr.replaceFirst('Exception: BLOCKED:', '');
      } else {
        reason = errStr;
      }
      showBlockSnackbar(context, reason);
    } else if (e is SessionExpiredException || errStr.contains('Session expired')) {
      // Handle session expired
      if (mounted) handleSessionExpired(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $errStr')),
      );
    }

    setState(() {
      isLoadingFollowRequests = false;
      isLoadingContentRequests = false;
      isLoadingMore = false;
    });
    debugPrint("Error: $e");
  }

  /// Shimmer UI for loading. Each item is shaped like a friend request card.
  Widget _shimmerLoading({int itemCount = 5}) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFF45F67), width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Row for user info
                Row(
                  children: [
                    // Circular shimmer for profile picture
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Shimmer lines for username
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 150,
                            height: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 100,
                            height: 10,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Shimmer for action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Primary action button shimmer
                    Container(
                      width: 120,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    // Secondary action button shimmer
                    Container(
                      width: 120,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// A friend-request card for each user
  Widget _friendRequestCard({
    required String fullName,
    required String username,
    required int userId,
    required String profilePic,
    required bool isFollowRequest,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF45F67), width: 2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF45F67).withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 3,
            offset: const Offset(0, 5),
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
                  final currentUserId = await _loginService.getUserId();
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
                      : const AssetImage('assets/profile.png') as ImageProvider,
                  radius: 30,
                  backgroundColor: Colors.transparent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@$username',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                  backgroundColor: const Color(0xFFF45F67),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  isFollowRequest ? 'Follow Back' : 'Approve',
                  style: const TextStyle(color: Colors.white),
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

  /// Follow back (from the "Follow Requests" list).
  Future<void> _handleFollowBack(int userId, String username) async {
    try {
      final currentUserId = await _loginService.getUserId();
      if (currentUserId != null) {
        await _followService.followUser(currentUserId, userId);
        setState(() {
          users.removeWhere((u) => u.username == username);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You have followed $username.')),
        );
      }
    } on SessionExpiredException {
      if (mounted) handleSessionExpired(context);
    } catch (e) {
      _handleError(e);
    }
  }

  /// Cancel a follow request you made.
  Future<void> _handleCancelRequest(int userId, String username) async {
    try {
      final currentUserId = await _loginService.getUserId();
      if (currentUserId != null) {
        await _followService.cancelFollowerRequest(userId, currentUserId);
        setState(() {
          users.removeWhere((u) => u.username == username);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Follow request to $username has been canceled.')),
        );
      }
    } on SessionExpiredException {
      if (mounted) handleSessionExpired(context);
    } catch (e) {
      _handleError(e);
    }
  }

  /// Approve a content request (from the "Content Requests" list).
  Future<void> _handleApprove(int userId, String username) async {
    try {
      final currentUserId = await _loginService.getUserId();
      if (currentUserId != null) {
        await _followService.updateFollowerStatus(currentUserId, userId, 'approved');
        setState(() {
          contentRequests.removeWhere((u) => u.username == username);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$username\'s content request has been approved.')),
        );
      }
    } on SessionExpiredException {
      if (mounted) handleSessionExpired(context);
    } catch (e) {
      _handleError(e);
    }
  }

  /// Decline a content request (from the "Content Requests" list).
  Future<void> _handleDecline(int userId, String username) async {
    try {
      final currentUserId = await _loginService.getUserId();
      if (currentUserId != null) {
        await _followService.updateFollowerStatus(currentUserId, userId, 'declined');
        setState(() {
          contentRequests.removeWhere((u) => u.username == username);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$username\'s content request has been declined.')),
        );
      }
    } on SessionExpiredException {
      if (mounted) handleSessionExpired(context);
    } catch (e) {
      _handleError(e);
    }
  }

  /// Builds the "Follow Requests" tab
  Widget _buildFollowRequestsTab() {
    if (isLoadingFollowRequests) {
      // Show shimmer when first loading the data
      return _shimmerLoading(itemCount: 5);
    } else if (users.isEmpty) {
      return const Center(
        child: Text(
          'No Follow Requests',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    } else {
      return ListView.builder(
        controller: _scrollController,
        itemCount: users.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // If index is at the end and we are loading more, show a progress indicator
          if (index == users.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: CircularProgressIndicator(color: Color(0xFFF45F67)),
              ),
            );
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

  /// Builds the "Content Requests" tab
  Widget _buildContentRequestsTab() {
    if (isLoadingContentRequests) {
      return _shimmerLoading(itemCount: 5);
    } else if (contentRequests.isEmpty) {
      return const Center(
        child: Text(
          'No Content Requests',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
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
      appBar: AppBar(
        title: const Text(
          'Friends Request',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFFF45F67),
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFF45F67),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFF45F67),
              labelPadding: const EdgeInsets.symmetric(vertical: 8.0),
              tabs: const [
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
