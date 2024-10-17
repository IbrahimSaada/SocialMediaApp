import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cook/models/sharedpost_model.dart';

class SharedPostsGrid extends StatelessWidget {
  final List<SharedPostDetails> sharedPosts;
  final bool isPaginatingSharedPosts;
  final bool hasMoreSharedPosts;
  final ScrollController scrollController;
  final double screenWidth;
  final Function(int) openSharedPost;
  final bool isPrivateAccount;

  const SharedPostsGrid({
    Key? key,
    required this.sharedPosts,
    required this.isPaginatingSharedPosts,
    required this.hasMoreSharedPosts,
    required this.scrollController,
    required this.screenWidth,
    required this.openSharedPost,
    required this.isPrivateAccount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isPrivateAccount) {
      // Display lock icon and private account message
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
    } else if (sharedPosts.isEmpty && !isPaginatingSharedPosts) {
      // Display "No shared posts yet" message for empty list
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, color: Colors.grey, size: 50),
            SizedBox(height: 10),
            Text(
              "No shared posts yet.",
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
          ],
        ),
      );
    }

     int itemCount = sharedPosts.length;
    if (isPaginatingSharedPosts) {
      itemCount += 1; // For the loading indicator
    }


    // If neither condition applies, display the grid of shared posts
 return GridView.builder(
      controller: scrollController,
      padding: EdgeInsets.all(10.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: screenWidth * 0.02,
        mainAxisSpacing: screenWidth * 0.02,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == sharedPosts.length) {
          // Loading indicator at the end
          return Center(
            child: CircularProgressIndicator(color: Color(0xFFF45F67)),
          );
        }
        final sharedPost = sharedPosts[index];
        return GestureDetector(
          onTap: () {
            openSharedPost(index);
          },
          child: _buildSharedPostThumbnail(sharedPost, screenWidth),
        );
      },
    );
  }


  Widget _buildSharedPostThumbnail(SharedPostDetails sharedPost, double screenWidth) {
    if (sharedPost.media.isNotEmpty) {
      final firstMedia = sharedPost.media[0];

      if (firstMedia.mediaType == 'video') {
        return Stack(
          children: [
            CachedNetworkImage(
              imageUrl: firstMedia.thumbnailUrl ?? firstMedia.mediaUrl,
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
          imageUrl: firstMedia.thumbnailUrl ?? firstMedia.mediaUrl,
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
