import 'package:flutter/material.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String username;
  final String profileImageUrl;
  final String status;
  final VoidCallback onProfileTap;

  ChatAppBar({
    required this.username,
    required this.profileImageUrl,
    required this.status,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.grey[100]!,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Color(0xFFF45F67)),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: GestureDetector(
        onTap: onProfileTap,
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(profileImageUrl),
                  radius: 18,
                ),
              ],
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(
                    color: Color(0xFFF45F67),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  status,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      centerTitle: false,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
