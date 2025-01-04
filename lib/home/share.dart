import 'package:flutter/material.dart';
import 'package:myapp/services/LoginService.dart';
import 'package:myapp/services/RepostServices.dart';
import 'package:myapp/maintenance/expiredtoken.dart';

void showBlockSnackbar(BuildContext context, String reason) {
  String message;
  if (reason.contains('You are blocked by the post owner')) {
    message = 'User blocked you';
  } else if (reason.contains('You have blocked the post owner')) {
    message = 'You blocked the user';
  } else {
    message = 'Action not allowed due to blocking';
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
      duration: const Duration(seconds: 3),
    ),
  );
}

class ShareBottomSheet extends StatelessWidget {
  final int postId;

  ShareBottomSheet({Key? key, required this.postId}) : super(key: key);

  final TextEditingController _shareTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets, 
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
            Container(
              width: MediaQuery.of(context).size.width * 0.2,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            const SizedBox(height: 15),
            Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Color(0xFFF45F67), width: 1.5),
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
                            int? userId = await LoginService().getUserId();

                            if (userId != null) {
                              try {
                                await RepostService().createRepost(userId, postId, shareText);
                                Navigator.pop(context);
                              } catch (e) {
                                final errStr = e.toString();
                                if (errStr.contains('Session expired')) {
                                  if (context.mounted) {
                                    handleSessionExpired(context);
                                  }
                                } else if (errStr.startsWith('Exception: BLOCKED:')) {
                                  String reason = errStr.replaceFirst('Exception: BLOCKED:', '');
                                  showBlockSnackbar(context, reason);
                                } else {
                                  print('Failed to repost: $e');
                                }
                              }
                            } else {
                              handleSessionExpired(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFF45F67),
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
