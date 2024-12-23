import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFFF45F67);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Help & Support',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(Icons.contact_support, color: primaryColor),
              title: Text('Contact Us'),
              subtitle: Text('Get in touch with our support team'),
              onTap: () {
                // Add functionality for contacting support
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.bug_report, color: primaryColor),
              title: Text('Report a Bug'),
              subtitle: Text('Let us know about any issues you face'),
              onTap: () {
                // Add functionality for bug reporting
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.feedback, color: primaryColor),
              title: Text('FAQs'),
              subtitle: Text('Find answers to common questions'),
              onTap: () {
                // Add functionality to show FAQs
              },
            ),
          ],
        ),
      ),
    );
  }
}
