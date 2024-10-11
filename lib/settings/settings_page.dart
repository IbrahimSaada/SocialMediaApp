import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '***REMOVED***/services/userprofile_service.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _isProfilePublic = true;
  String _language = 'English';
  bool _darkMode = false;
  final UserProfileService _userProfileService = UserProfileService();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    String? userIdString = await _secureStorage.read(key: 'userId');
    if (userIdString != null) {
      setState(() {
        _userId = int.parse(userIdString);
      });
      await _loadProfilePrivacy(); // Load the profile privacy status
    }
  }

   Future<void> _loadProfilePrivacy() async {
    if (_userId == null) return;

    try {
      bool isPublic = await _userProfileService.checkProfilePrivacy(_userId!);
      setState(() {
        _isProfilePublic = isPublic; // Update UI with the fetched privacy status
      });
    } catch (e) {
      print('Error loading profile privacy: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final primaryColor = Color(0xFFF45F67);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Settings',
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
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
            _buildSwitchTile(
              title: 'Public Profile',
              value: _isProfilePublic, // Updated to reflect actual status fetched from API
              icon: Icons.lock_open,
              onChanged: (value) {
                setState(() {
                  _isProfilePublic = value;
                });
                _updateProfilePrivacy(value); // Update privacy on toggle
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
            onTap: () {},
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
    final primaryColor = Color(0xFFF45F67);

    return SwitchListTile(
      activeColor: primaryColor,
      inactiveThumbColor: Colors.grey,
      inactiveTrackColor: Colors.grey.shade300,
      title: Text(
        title,
        style: TextStyle(fontSize: screenWidth * 0.045, color: Colors.black87),
      ),
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: primaryColor),
    );
  }

  Future<void> _updateProfilePrivacy(bool isPublic) async {
    if (_userId == null) {
      return;
    }
    try {
      await _userProfileService.changeProfilePrivacy(_userId!, isPublic);
    } catch (e) {
      print("Error updating profile privacy: $e");
    }
  }
}
