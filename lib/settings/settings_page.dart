import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '***REMOVED***/services/userprofile_service.dart';
import '***REMOVED***/models/privacy_settings_model.dart';
import '***REMOVED***/settings/changepasswordpage.dart';
import '***REMOVED***/maintenance/expiredtoken.dart';
import '***REMOVED***/services/SessionExpiredException.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _isProfilePublic = true;
  bool _isFollowersPublic = true;
  bool _isFollowingPublic = true;
  bool _isNotificationsMuted = true;
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
      await _loadProfilePrivacy();
    }
  }

Future<void> _loadProfilePrivacy() async {
  if (_userId == null) return;

  try {
    Map<String, bool> privacySettings = await _userProfileService.checkProfilePrivacy(_userId!);

    setState(() {
      _isProfilePublic = privacySettings['isPublic'] ?? false;
      _isFollowersPublic = privacySettings['isFollowersPublic'] ?? false;
      _isFollowingPublic = privacySettings['isFollowingPublic'] ?? false;
      _isNotificationsMuted = privacySettings['isNotificationsMuted'] ?? false;
    });
  } on SessionExpiredException {
    print("SessionExpired detected while loading privacy");
    handleSessionExpired(context); // Trigger session expired dialog
  } catch (e) {
    print('Error loading profile privacy: $e');
    // Optionally, display an error message to the user
  }
}



void _updatePrivacySettings() async {
  if (_userId == null) return;

  // Always send the current states of all three fields
  PrivacySettings settings = PrivacySettings(
    isPublic: _isProfilePublic,
    isFollowersPublic: _isFollowersPublic,
    isFollowingPublic: _isFollowingPublic,
    isNotificationsMuted: _isNotificationsMuted,
  );

  print('Updating Privacy Settings: ${settings.toJson()}'); // Log the complete payload

  try {
    await _userProfileService.changeProfilePrivacy(_userId!, settings);
    print("Privacy settings updated successfully.");

    // Optionally, show success feedback to the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Privacy settings updated successfully!"),
        backgroundColor: Colors.green,
      ),
    );

  } on SessionExpiredException {
    // Handle session expired
    print("SessionExpired detected while updating privacy settings.");
    handleSessionExpired(context); // Show session expired dialog

  } catch (e) {
    // Log and show error message to the user
    print("Error updating privacy settings: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Failed to update privacy settings. Please try again."),
        backgroundColor: Colors.red,
      ),
    );
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
  value: _isProfilePublic,
  icon: Icons.lock_open,
  onChanged: (value) {
    setState(() {
      _isProfilePublic = value;
    });
    _updatePrivacySettings(); // Update after changing the toggle state
  },
),

          Divider(),
          _buildSwitchTile(
            title: 'Public Followers',
            value: _isFollowersPublic,
            icon: Icons.group,
            onChanged: (value) {
              setState(() {
                _isFollowersPublic = value;
              });
              _updatePrivacySettings(); // Update backend on change
            },
          ),
          Divider(),
          _buildSwitchTile(
            title: 'Public Following',
            value: _isFollowingPublic,
            icon: Icons.group_add,
            onChanged: (value) {
              setState(() {
                _isFollowingPublic = value;
              });
              _updatePrivacySettings(); // Update backend on change
            },
          ),
          Divider(),
          _buildSwitchTile(
            title: 'Mute Notifications',
            value: _isNotificationsMuted,
            icon: Icons.notifications,
            onChanged: (value) {
              setState(() {
                _isNotificationsMuted = value;
              });
              _updatePrivacySettings(); // Update backend on change
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChangePasswordPage()),
    );
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
}
