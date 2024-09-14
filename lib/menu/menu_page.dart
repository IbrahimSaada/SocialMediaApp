import 'package:flutter/material.dart';
import '***REMOVED***/menu/profile_page.dart';
import '***REMOVED***/login/login_page.dart';
import '***REMOVED***/menu/setting_page.dart';
import '***REMOVED***/services/LoginService.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  );
                },
                child: const Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage('assets/chef.jpg'),
                      radius: 30,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Ahmad Ghosen',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow
                            .ellipsis, // Optional: Adds ellipsis for long text
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const ListTile(
              leading: Icon(Icons.people, color: Colors.lightBlue),
              title: Text('Friends'),
            ),
            const ListTile(
              leading: Icon(Icons.bookmark, color: Colors.lightBlueAccent),
              title: Text('Saved Post'),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.orange),
              title: const Text('Setting'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.pink),
              title: const Text('Logout'),
              onTap: () async {
                // Call the logout function
                await LoginService().logout();

                // After logout, redirect to login page
                Navigator.pushReplacement(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
