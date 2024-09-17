import 'package:flutter/material.dart';
import '***REMOVED***/models/post_model.dart';
import '***REMOVED***/services/LoginService.dart';
import '***REMOVED***/services/RepostServices.dart';
import '***REMOVED***/maintenance/expiredtoken.dart'; // Import expired token handler

class ShareBottomSheet extends StatelessWidget {
  final Post post;

  ShareBottomSheet({super.key, required this.post});

  final TextEditingController _shareTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets, // Handles keyboard overlap
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: 16.0), // Padding for the bottom sheet
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10.0,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top handle bar for dragging
            Container(
              width: MediaQuery.of(context).size.width * 0.2,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            const SizedBox(height: 15),
            // Share Card
            Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.orange, width: 1.5),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Share Post',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _shareTextController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 12.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            String shareText = _shareTextController.text.trim();

                            // Check user session before sharing
                            int? userId = await LoginService().getUserId();

                            if (userId != null) {
                              // Perform the repost action
                              try {
                                await RepostService().createRepost(
                                    userId, post.postId, shareText);
                                Navigator.pop(context); // Close bottom sheet after successful share
                              } catch (e) {
                                print('Failed to repost: $e');
                              }
                            } else {
                              // Session expired, show dialog
                              handleSessionExpired(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40.0, vertical: 15.0),
                          ),
                          child: const Text(
                            'Share',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
