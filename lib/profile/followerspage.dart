import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cook/services/userprofile_service.dart';
import 'package:cook/models/follower_model.dart';
import 'package:cook/maintenance/expiredtoken.dart';
import 'package:cook/services/SessionExpiredException.dart';

class FollowersPage extends StatefulWidget {
  final int userId;
  final int viewerUserId;

  FollowersPage({required this.userId, required this.viewerUserId});

  @override
  _FollowersPageState createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Follower> followers = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 1;
  final int pageSize = 10;
  bool hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _fetchFollowers();
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
      _fetchFollowers(page: currentPage + 1);
    }
  }

Future<void> _fetchFollowers({int page = 1}) async {
  try {
    if (page == 1) setState(() => isLoading = true);
    else setState(() => isLoadingMore = true);

    List<Follower> newFollowers = await UserProfileService().fetchFollowers(
      widget.userId,
      widget.viewerUserId,
      search: _searchController.text,
      pageNumber: page,
      pageSize: pageSize,
    );

    setState(() {
      if (page == 1) {
        followers = newFollowers;
      } else {
        followers.addAll(newFollowers);
      }
      currentPage = page;
      hasMoreData = newFollowers.length == pageSize;
      isLoading = false;
      isLoadingMore = false;
    });
  } on SessionExpiredException {
    print("SessionExpired detected while fetching followers");
    handleSessionExpired(context); // Trigger the session expired dialog
  } catch (e) {
    print('Error fetching followers: $e');
    setState(() {
      isLoading = false;
      isLoadingMore = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load followers. Please try again.')),
    );
  }
}


Widget _buildShimmerEffect(double screenWidth) {
  return ListView.builder(
    itemCount: 20,
    itemBuilder: (context, index) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            Expanded( // Ensures full-width shimmer for the username
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: double.infinity, // Take full available width
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
          'Followers',
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
                  hintText: 'Search followers...',
                  hintStyle: TextStyle(color: Theme.of(context).primaryColor),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  currentPage = 1;
                  _fetchFollowers(page: 1);
                },
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? _buildShimmerEffect(screenWidth)
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: followers.length + (isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == followers.length) {
                        return Center(child: CircularProgressIndicator());
                      }
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10), // Increased padding
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(followers[index].profilePic),
                              radius: screenWidth * 0.07,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                followers[index].fullName,
                                style: TextStyle(fontSize: screenWidth * 0.04),
                                overflow: TextOverflow.ellipsis,
                              ),
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
