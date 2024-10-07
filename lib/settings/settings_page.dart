import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _isProfilePublic = true;
  String _language = 'English';
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final primaryColor = Color(0xFFF45F67); // Updated color

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // White app bar for clean look
        elevation: 0, // Remove shadow
        centerTitle: true, // Center the title
        title: Text(
          'Settings',
          style: TextStyle(
            color: primaryColor, // Updated color
            fontWeight: FontWeight.bold,
            fontSize: 24, // Cleaner font size
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          _buildSwitchTile(
            title: 'Public Profile',
            value: _isProfilePublic,
            icon: Icons.lock_open,
            onChanged: (value) {
              setState(() {
                _isProfilePublic = value;
              });
            },
          ),
          Divider(),

          _buildSwitchTile(
            title: 'Enable Notifications',
            value: _notificationsEnabled,
            icon: Icons.notifications,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.language, color: primaryColor),
            title: Text(
              'Language',
              style: TextStyle(fontSize: screenWidth * 0.045, color: Colors.black87),
            ),
            trailing: DropdownButton<String>(
              value: _language,
              items: <String>['English', 'Spanish', 'French', 'German']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(fontSize: screenWidth * 0.04)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _language = newValue!;
                });
              },
            ),
          ),
          Divider(),

          _buildSwitchTile(
            title: 'Dark Mode',
            value: _darkMode,
            icon: Icons.brightness_6,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
            },
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.lock, color: primaryColor),
            title: Text(
              'Change Password',
              style: TextStyle(fontSize: screenWidth * 0.045, color: Colors.black87),
            ),
            onTap: () {
              // Navigate to Change Password page
            },
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.info, color: primaryColor),
            title: Text(
              'About',
              style: TextStyle(fontSize: screenWidth * 0.045, color: Colors.black87),
            ),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Your App Name',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(Icons.local_cafe, size: screenWidth * 0.1),
                children: [
                  Text('This is a sample app for demonstration purposes.'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
  }) {
    double screenWidth = MediaQuery.of(context).size.width;
    final primaryColor = Color(0xFFF45F67); // Updated color

    return SwitchListTile(
      activeColor: primaryColor, // Color for switch when active
      inactiveThumbColor: Colors.grey, // Color for thumb when inactive
      inactiveTrackColor: Colors.grey.shade300, // Track color when inactive
      title: Text(
        title,
        style: TextStyle(fontSize: screenWidth * 0.045, color: Colors.black87),
      ),
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: primaryColor),
    );
  }
}
