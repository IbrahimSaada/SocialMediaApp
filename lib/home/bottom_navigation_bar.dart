// widgets/bottom_navigation_bar.dart

import 'package:flutter/material.dart';
import 'package:cook/home/add_friends_page.dart';
import 'package:cook/notification/notification_page.dart';
import 'package:cook/home/search.dart';
import 'package:cook/askquestion/qna_page.dart';
import 'package:cook/contact/contacts_page.dart';
import 'package:cook/services/LoginService.dart';

Widget buildBottomNavigationBar(BuildContext context) {
    final LoginService loginService = LoginService();
  return SizedBox(
    height: 65,
    child: BottomAppBar(
      color: const Color(0xFFF45F67),
      elevation: 8.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.person_add_alt, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddFriendsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Search()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QnaPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
            onPressed: () async {
              // Retrieve userId using LoginService
              int? userId = await loginService.getUserId();
              String fullname = await loginService.getFullname();
    
              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ContactsPage(
                      fullname: fullname,
                      userId: userId,
                      // Since token is not needed, we can omit it or pass an empty string
                    ),
                  ),
                );
              } else {
                // Handle the case where userId is not available
                // For example, navigate to login page or show a message
                print('User is not logged in');
                // Navigate to LoginPage or show a dialog
                Navigator.pushNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    ),
  );
}