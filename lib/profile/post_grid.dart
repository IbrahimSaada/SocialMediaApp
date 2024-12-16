import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '***REMOVED***/models/post_model.dart';

class PostGrid extends StatelessWidget {
  final List<Post> userPosts;
  final bool isPaginating;
  final ScrollController scrollController;
  final double screenWidth;
  final Function(int) openFullPost;
  final bool isPrivateAccount;
  final bool isBlockedBy;
  final bool isUserBlocked;

  const PostGrid({
    Key? key,
    required this.userPosts,
    required this.isPaginating,
    required this.scrollController,
    required this.screenWidth,
    required this.openFullPost,
    required this.isPrivateAccount,
    required this.isBlockedBy,
    required this.isUserBlocked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isBlockedBy) {
      return _buildBlockedMessage("You are blocked by this user.");
    } else if (isUserBlocked) {
      return _buildBlockedMessage("You have blocked this user.");
    }

    // Check if private account before checking if empty
    if (isPrivateAccount) {
      return _buildPrivateAccountMessage();
    } else if (userPosts.isEmpty && !isPaginating) {
      return _buildEmptyMessage("No posts yet.");
    }

    return GridView.builder(
      controller: scrollController,
      padding: EdgeInsets.all(10.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: screenWidth * 0.02,
        mainAxisSpacing: screenWidth * 0.02,
      ),
      itemCount: userPosts.length + (isPaginating ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == userPosts.length) {
          return Center(child: CircularProgressIndicator(color: Color(0xFFF45F67)));
        }
        final post = userPosts[index];
        return GestureDetector(
          onTap: () => openFullPost(index),
          child: _buildPostThumbnail(post, screenWidth),
        );
      },
    );
  }

  Widget _buildBlockedMessage(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block, color: Colors.red, size: 50),
          SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(color: Colors.grey, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateAccountMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, color: Colors.grey, size: 50),
          SizedBox(height: 10),
          Text(
            "This account is private.",
            style: TextStyle(color: Colors.grey, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library, color: Colors.grey, size: 50),
          SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(color: Colors.grey, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildPostThumbnail(Post post, double screenWidth) {
    if (post.media.isNotEmpty) {
      final firstMedia = post.media[0];

      if (firstMedia.mediaType == 'video') {
        return Stack(
          children: [
            CachedNetworkImage(
              imageUrl: firstMedia.thumbnailurl ?? firstMedia.mediaUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => _buildShimmerEffect(),
              errorWidget: (context, url, error) => _buildErrorPlaceholder(),
            ),
            Positioned(
              bottom: screenWidth * 0.02,
              right: screenWidth * 0.02,
              child: Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: screenWidth * 0.07,
              ),
            ),
          ],
        );
      } else {
        return CachedNetworkImage(
          imageUrl: firstMedia.thumbnailurl ?? firstMedia.mediaUrl,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => _buildErrorPlaceholder(),
          placeholder: (context, url) => _buildShimmerEffect(),
        );
      }
    } else {
      return Container(
        color: Color(0xFFF45F67),
        child: Center(
          child: Icon(
            Icons.format_quote,
            color: Colors.white,
            size: screenWidth * 0.1,
          ),
        ),
      );
    }
  }

  Widget _buildShimmerEffect() {
    return Container(
      color: Colors.grey[300],
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
}
