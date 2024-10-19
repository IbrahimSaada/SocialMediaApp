// home/shimmer_post_card.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerPostCard extends StatelessWidget {
  const ShimmerPostCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define shimmer base and highlight colors
    final baseColor = Colors.grey[300]!;
    final highlightColor = Colors.grey[100]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Shimmer: Profile Picture, Username, Timestamp
              Row(
                children: [
                  // Profile Picture Placeholder
                  Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  // Username and Timestamp Placeholder
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username Placeholder
                        Container(
                          width: double.infinity,
                          height: 12.0,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 6.0),
                        // Timestamp Placeholder
                        Container(
                          width: 100.0,
                          height: 10.0,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  // More Options Placeholder (Icon)
                  Container(
                    width: 24.0,
                    height: 24.0,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              // Post Content Placeholder: Multiple Lines
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(3, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Container(
                      width: double.infinity,
                      height: 10.0,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16.0),
              // Media Placeholder
              Container(
                width: double.infinity,
                height: 200.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              const SizedBox(height: 16.0),
              // Action Buttons Shimmer: Like, Comment, Share, Bookmark
              Row(
                children: [
                  // Like Button Placeholder
                  Container(
                    width: 40.0,
                    height: 20.0,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 24.0),
                  // Comment Button Placeholder
                  Container(
                    width: 40.0,
                    height: 20.0,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 24.0),
                  // Share Button Placeholder
                  Container(
                    width: 40.0,
                    height: 20.0,
                    color: Colors.white,
                  ),
                  const Spacer(),
                  // Bookmark Button Placeholder
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
      ),
    );
  }
}
