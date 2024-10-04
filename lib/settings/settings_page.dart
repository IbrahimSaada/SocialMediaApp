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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // All white app bar
        elevation: 0, // Remove shadow
        centerTitle: true, // Center the title
        title: Text(
          'Settings',
          style: TextStyle(
            color: Colors.orangeAccent, // Orange text
            fontWeight: FontWeight.bold,
            fontSize: 24, // Cleaner font size
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.orangeAccent),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          // Public/Private Profile Toggle
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

          // Notifications Setting
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

          // Language Setting
          ListTile(
            leading: Icon(Icons.language, color: Colors.orangeAccent),
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

          // Dark Mode Setting
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

          // Change Password Option
          ListTile(
            leading: Icon(Icons.lock, color: Colors.orangeAccent),
            title: Text(
              'Change Password',
              style: TextStyle(fontSize: screenWidth * 0.045, color: Colors.black87),
            ),
            onTap: () {
              // Navigate to Change Password page
            },
          ),
          Divider(),

          // About Section
          ListTile(
            leading: Icon(Icons.info, color: Colors.orangeAccent),
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

    return SwitchListTile(
      activeColor: Colors.orangeAccent, // Orange color for switch
      title: Text(
        title,
        style: TextStyle(fontSize: screenWidth * 0.045, color: Colors.black87),
      ),
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: Colors.orangeAccent),
    );
  }
}
