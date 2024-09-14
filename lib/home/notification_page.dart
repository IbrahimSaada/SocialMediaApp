import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NotificationPage(),
    ),
  );
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationPage> {
  final List<AppNotification> _notifications = [
    AppNotification(
      title: 'New Like',
      message: 'Your post has been liked ',
      time: '2 hours ago',
      username: 'janeDoe',
      profilePhoto: 'https://picsum.photos/200/301',
    ),
    AppNotification(
      title: 'New Comment',
      message: 'Your post has been commented',
      time: '3 hours ago',
      username: 'johnDoe',
      profilePhoto: 'https://picsum.photos/200/300',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Card(
                elevation: 0,
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(
                                _notifications[index].profilePhoto),
                            radius: 20,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _notifications[index].username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(_notifications[index].title),
                              Text(_notifications[index].message),
                              Text(
                                _notifications[index].time,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Flexible(
                        // Ensures text does not overflow
                        child: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              child: Text('Hide'),
                            ),
                            const PopupMenuItem(
                              child: Text('Delete'),
                            ),
                          ],
                          child: const Icon(Icons.more_vert, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AppNotification {
  final String title;
  final String message;
  final String time;
  final String username;
  final String profilePhoto;

  AppNotification({
    required this.title,
    required this.message,
    required this.time,
    required this.username,
    required this.profilePhoto,
  });
}
