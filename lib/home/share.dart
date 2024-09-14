import 'package:flutter/material.dart';
import '***REMOVED***/models/post_model.dart';
import '***REMOVED***/services/LoginService.dart';
import '***REMOVED***/services/RepostServices.dart';


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
            // Share Card that fills the full width
            Container(
              width:
                  MediaQuery.of(context).size.width, // Full width of the screen
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
                padding:
                    const EdgeInsets.all(12.0), // Inner padding for content
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

                            // Fetch the current user's ID from the secure storage
                            int? userId = await LoginService().getUserId();

                            if (userId != null) {
                              // Call the repost service to create a repost
                              try {
                                await RepostService().createRepost(
                                    userId, post.postId, shareText);
                                // ignore: avoid_print
                                print('Repost successful');
                                // Optionally, refresh the UI or show a success message
                              } catch (e) {
                                // ignore: avoid_print
                                print('Failed to repost: $e');
                                // Optionally, show an error message to the user
                              }

                              // Close the bottom sheet after reposting
                              // ignore: use_build_context_synchronously
                              Navigator.pop(context);
                            } else {
                              // Handle the case where the user ID is not available
                              // ignore: avoid_print
                              print('User not logged in');
                              // Optionally, show a message to the user
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange, // Orange background
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40.0,
                                vertical: 15.0), // Larger button size
                          ),
                          child: const Text(
                            'Share',
                            style: TextStyle(
                                color: Colors.white), // White text color
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
