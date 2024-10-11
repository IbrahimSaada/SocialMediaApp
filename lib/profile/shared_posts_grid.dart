// shared_posts_grid.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cook/models/sharedpost_model.dart';

class SharedPostsGrid extends StatelessWidget {
  final List<SharedPostDetails> sharedPosts;
  final bool isPaginatingSharedPosts;
  final ScrollController scrollController;
  final double screenWidth;
  final Function(int) openSharedPost;

  const SharedPostsGrid({
    Key? key,
    required this.sharedPosts,
    required this.isPaginatingSharedPosts,
    required this.scrollController,
    required this.screenWidth,
    required this.openSharedPost,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (sharedPosts.isEmpty && !isPaginatingSharedPosts) {
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

    return GridView.builder(
      controller: scrollController,
      padding: EdgeInsets.all(10.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: screenWidth * 0.02,
        mainAxisSpacing: screenWidth * 0.02,
      ),
      itemCount: sharedPosts.length + (isPaginatingSharedPosts ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == sharedPosts.length) {
          return Center(child: CircularProgressIndicator(color: Color(0xFFF45F67)));
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
