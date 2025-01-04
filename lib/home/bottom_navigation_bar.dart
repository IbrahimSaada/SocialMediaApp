import 'package:flutter/material.dart';
import 'package:myapp/home/add_friends_page.dart';
import 'package:myapp/notification/notification_page.dart';
import 'package:myapp/home/search.dart';
import 'package:myapp/contact/contacts_page.dart';
import 'package:myapp/services/LoginService.dart';
import 'package:myapp/services/notificationservice.dart';

class BottomNavigationBarCook extends StatefulWidget {
  const BottomNavigationBarCook({Key? key}) : super(key: key);

  @override
  _BottomNavigationBarCookState createState() =>
      _BottomNavigationBarCookState();
}

class _BottomNavigationBarCookState extends State<BottomNavigationBarCook> {
  final LoginService loginService = LoginService();
  final NotificationService _notificationService = NotificationService();

  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  /// Fetch unread notifications count
  Future<void> _fetchUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      setState(() {
        _unreadCount = count;
      });
    } catch (e) {
      // Handle error silently or show a message
      print('Error fetching unread count: $e');
    }
  }

  /// Call this whenever you'd like to refresh the unread count immediately
  void refreshUnreadCount() {
    _fetchUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
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
                ).then((_) {
                  // Refresh unread count when coming back
                  refreshUnreadCount();
                });
              },
            ),
IconButton(
  icon: Stack(
    clipBehavior: Clip.none, // Ensures the badge is not clipped
    children: [
      const Icon(Icons.notifications_none, color: Colors.white, size: 28),
      if (_unreadCount > 0)
        Positioned(
          right: -4, // Adjusted to keep it within bounds
          top: -6,  // Slightly above the icon
          child: Container(
            padding: const EdgeInsets.all(1.5), // Smaller padding
            decoration: BoxDecoration(
              color: Colors.white, // White background for the badge
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).primaryColor, width: 0.8), // Thin border
            ),
            constraints: const BoxConstraints(
              minWidth: 12, // Ensures it stays circular
              minHeight: 12, // Ensures it stays circular
            ),
            child: Text(
              '$_unreadCount',
              style: TextStyle(
                color: Theme.of(context).primaryColor, // Primary color for the number
                fontSize: 8, // Smaller font size
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
    ],
  ),
  onPressed: () async {
    // Navigate to the notifications page
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotificationPage()),
    );
    // After returning from NotificationPage, refresh unread count
    refreshUnreadCount();
  },
),


            IconButton(
              icon: const Icon(Icons.search, color: Colors.white, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Search()),
                ).then((_) {
                  refreshUnreadCount();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
              onPressed: () async {
                int? userId = await loginService.getUserId();
                String fullname = await loginService.getFullname();

                if (userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ContactsPage(
                        fullname: fullname,
                        userId: userId,
                      ),
                    ),
                  ).then((_) {
                    refreshUnreadCount();
                  });
                } else {
                  print('User is not logged in');
                  Navigator.pushNamed(context, '/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
