// widgets/bottom_navigation_bar.dart

import 'package:flutter/material.dart';
import 'package:cook/home/add_friends_page.dart';
import 'package:cook/home/notification_page.dart';
import 'package:cook/home/search.dart';
import 'package:cook/askquestion/qna_page.dart';
import 'package:cook/home/contacts_page.dart';

Widget buildBottomNavigationBar(BuildContext context) {
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ContactsPage()),
              );
            },
          ),
        ],
      ),
    ),
  );
}