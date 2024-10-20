// home/shimmer_post_card.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerPostCard extends StatelessWidget {
  const ShimmerPostCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey[300]!;
    final highlightColor = Colors.grey[100]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (Profile picture, username, timestamp)
            Row(
              children: [
                // Profile Picture
                Container(
                  width: 40.0,
                  height: 40.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12.0),
                // Username and Timestamp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username - wider than timestamp
                      Container(
                        width: MediaQuery.of(context).size.width * 0.5, // 50% width
                        height: 12.0,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 6.0),
                      // Timestamp - shorter than username
                      Container(
                        width: MediaQuery.of(context).size.width * 0.3, // 30% width
                        height: 10.0,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            
            // Content Placeholder
            Container(
              width: double.infinity,
              height: 200.0,
              color: Colors.white,
            ),
            
            const SizedBox(height: 16.0),
            // Action buttons (like, comment, share, bookmark)
            Row(
              children: [
                // Like button
                Container(
                  width: 40.0,
                  height: 20.0,
                  color: Colors.white,
                ),
                const SizedBox(width: 24.0),
                // Comment button
                Container(
                  width: 40.0,
                  height: 20.0,
                  color: Colors.white,
                ),
                const SizedBox(width: 24.0),
                // Share button
                Container(
                  width: 40.0,
                  height: 20.0,
                  color: Colors.white,
                ),
                const Spacer(),
                // Bookmark button
                Container(
                  width: 40.0,
                  height: 20.0,
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
