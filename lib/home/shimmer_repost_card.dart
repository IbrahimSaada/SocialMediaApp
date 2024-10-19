// home/shimmer_repost_card.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerRepostCard extends StatelessWidget {
  const ShimmerRepostCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey[300]!;
    final highlightColor = Colors.grey[100]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.grey[300]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sharer Information Shimmer
              Row(
                children: [
                  // Sharer's Profile Picture Placeholder
                  Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  // Sharer's Username and Timestamp Placeholder
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username Placeholder
                        Container(
                          width: double.infinity,
                          height: 10.0,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 6.0),
                        // Timestamp Placeholder
                        Container(
                          width: 80.0,
                          height: 8.0,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  // More Options Placeholder
                  Container(
                    width: 24.0,
                    height: 24.0,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              // Repost Content Placeholder
              Container(
                width: double.infinity,
                height: 10.0,
                color: Colors.white,
              ),
              const SizedBox(height: 8.0),
              // Original Post Content Placeholder
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(2, (index) {
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
              const SizedBox(height: 12.0),
              // Original Media Placeholder
              Container(
                width: double.infinity,
                height: 150.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              const SizedBox(height: 12.0),
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
