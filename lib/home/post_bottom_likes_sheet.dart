// post_likes_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:myapp/services/loginservice.dart'; // adjust import as needed
import 'package:myapp/profile/otheruserprofilepage.dart';
import 'package:myapp/profile/profile_page.dart';
import '../models/user_like.dart';

class PostLikesBottomSheet extends StatefulWidget {
  final int postId;
  final List<UserLike> initialLikes;

  const PostLikesBottomSheet({
    Key? key,
    required this.postId,
    required this.initialLikes,
  }) : super(key: key);

  @override
  _PostLikesBottomSheetState createState() => _PostLikesBottomSheetState();
}

class _PostLikesBottomSheetState extends State<PostLikesBottomSheet> {
  List<UserLike> _allLikes = [];
  List<UserLike> _filteredLikes = [];
  String _searchQuery = '';
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserId();
    _allLikes = widget.initialLikes;
    _filteredLikes = widget.initialLikes;
  }

  Future<void> _fetchCurrentUserId() async {
    _currentUserId = await LoginService().getUserId();
  }

  void _filterLikes(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredLikes = _allLikes.where((like) {
        return like.fullname.toLowerCase().contains(_searchQuery);
      }).toList();
    });
  }

  Future<void> _navigateToUserProfile(UserLike userLike) async {
    if (_currentUserId == userLike.userId) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OtherUserProfilePage(otherUserId: userLike.userId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.75, // covers 75% of the screen
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: _filterLikes,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Color(0xFFF45F67)),
                hintText: 'Search...',
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredLikes.isEmpty
                ? Center(child: Text('No likes found.'))
                : ListView.builder(
                    itemCount: _filteredLikes.length,
                    itemBuilder: (context, index) {
                      final like = _filteredLikes[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(like.profilePic),
                        ),
                        title: Text(like.fullname),
                        onTap: () => _navigateToUserProfile(like),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
