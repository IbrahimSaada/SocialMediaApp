import 'package:flutter/material.dart';


class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setting'),
      ),
      body: const SingleChildScrollView(
        child: Column(
          children: [
   
            ListTile(
              leading: Icon(Icons.lock, color: Colors.lightBlue),
              title: Text('Change password'),
            ),
             ListTile(
              leading: Icon(Icons.notifications, color: Colors.orange),
              title: Text('Notification setting'),
            ),
            

          ],
        ),
      ),
    );
  }
}