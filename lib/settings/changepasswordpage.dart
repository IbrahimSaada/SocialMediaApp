import 'package:flutter/material.dart';
import '***REMOVED***/services/userprofile_service.dart';
import '***REMOVED***/services/loginservice.dart';

class ChangePasswordPage extends StatefulWidget {
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final UserProfileService _userProfileService = UserProfileService();
  final LoginService _loginService = LoginService();
  bool _isOldPasswordVerified = false;
  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    int? userId = await _loginService.getUserId();
    setState(() {
      _userId = userId;
    });
  }

  void _changePassword() async {
    if (_formKey.currentState!.validate() && _userId != null) {
      if (!_isOldPasswordVerified) {
        // Step 1: Verify the old password
        final response = await _userProfileService.changePassword(
          _userId!,
          _oldPasswordController.text,
          _oldPasswordController.text, // Temporarily use the old password in both fields
        );

        if (response['success'] == true) {
          setState(() {
            _isOldPasswordVerified = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Old password verified. Enter new password.")));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Old password is wrong")));
        }
      } else {
        // Step 2: Change to the new password
        final response = await _userProfileService.changePassword(
          _userId!,
          _oldPasswordController.text,
          _newPasswordController.text,
        );

        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Password changed successfully")));
          Navigator.pop(context); // Go back after successful change
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'])));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFFF45F67);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Change Password',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _oldPasswordController,
                obscureText: !_isOldPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Old Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isOldPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isOldPasswordVisible = !_isOldPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your old password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              if (_isOldPasswordVerified) ...[
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: !_isNewPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isNewPasswordVisible = !_isNewPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isNewPasswordVisible,
                  decoration: InputDecoration(labelText: 'Confirm New Password'),
                  validator: (value) {
                    if (value == null || value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
              SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text(
                    _isOldPasswordVerified ? 'Change Password' : 'Verify Old Password',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
