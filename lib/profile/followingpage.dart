import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '***REMOVED***/services/userprofile_service.dart';
import '***REMOVED***/models/following_model.dart';
import '***REMOVED***/maintenance/expiredtoken.dart';
import '***REMOVED***/services/SessionExpiredException.dart';

class FollowingPage extends StatefulWidget {
  final int userId;
  final int viewerUserId;

  FollowingPage({required this.userId, required this.viewerUserId});

  @override
  _FollowingPageState createState() => _FollowingPageState();
}

class _FollowingPageState extends State<FollowingPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Following> following = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 1;
  final int pageSize = 10; // Keep page size as 10 for pagination
  bool hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _fetchFollowing();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
        hasMoreData &&
        !isLoadingMore) {
      _fetchFollowing(page: currentPage + 1);
    }
  }

Future<void> _fetchFollowing({int page = 1}) async {
  if (page == 1) setState(() => isLoading = true);
  else setState(() => isLoadingMore = true);

  try {
    List<Following> newFollowing = await UserProfileService().fetchFollowing(
      widget.userId,
      widget.viewerUserId,
      search: _searchController.text,
      pageNumber: page,
      pageSize: pageSize,
    );

    setState(() {
      if (page == 1) {
        following = newFollowing;
      } else {
        following.addAll(newFollowing);
      }
      currentPage = page;
      hasMoreData = newFollowing.length == pageSize;
    });
  } on SessionExpiredException {
    // Handle session expired
    print("Session expired in _fetchFollowing");
    handleSessionExpired(context);  // Show session expired dialog/UI
  } catch (e) {
    print('Error fetching following: $e');
  } finally {
    setState(() {
      isLoading = false;
      isLoadingMore = false;
    });
  }
}


  Widget _buildShimmerEffect(double screenWidth) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: 20,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: CircleAvatar(
                  radius: screenWidth * 0.07,
                  backgroundColor: Colors.grey[300],
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: screenWidth * 0.05,
                    color: Colors.grey[300],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Following',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).secondaryHeaderColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search following...',
                  hintStyle: TextStyle(color: Theme.of(context).primaryColor),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  currentPage = 1; // Reset pagination for new search
                  _fetchFollowing(page: 1);
                },
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? _buildShimmerEffect(screenWidth)
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: following.length + (isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == following.length) {
                        return Center(child: CircularProgressIndicator());
                      }
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(following[index].profilePic),
                              radius: screenWidth * 0.07,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                following[index].fullName,
                                style: TextStyle(fontSize: screenWidth * 0.04),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                // Implement message functionality
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Theme.of(context).primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              ),
                              child: Text(
                                'Message',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: screenWidth * 0.035,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: Theme.of(context).primaryColor),
                              itemBuilder: (BuildContext context) {
                                return [
                                  PopupMenuItem<String>(
                                    value: 'block',
                                    child: Row(
                                      children: [
                                        Icon(Icons.block, color: Colors.redAccent),
                                        SizedBox(width: 8),
                                        Text('Block'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'unfollow',
                                    child: Row(
                                      children: [
                                        Icon(Icons.person_remove, color: Colors.orange),
                                        SizedBox(width: 8),
                                        Text('Unfollow'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'mute',
                                    child: Row(
                                      children: [
                                        Icon(Icons.volume_off, color: Colors.blueAccent),
                                        SizedBox(width: 8),
                                        Text('Mute'),
                                      ],
                                    ),
                                  ),
                                ];
                              },
                              onSelected: (value) {
                                // Handle each menu action
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
