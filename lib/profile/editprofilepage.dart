import 'dart:io';
import 'package:cook/models/presigned_url.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cook/services/s3_upload_service.dart'; // Use your S3UploadService
import 'package:cook/services/loginservice.dart'; // Use your LoginService
import 'package:cook/services/userprofile_service.dart'; // Use the UserProfileService
import 'package:cook/models/editprofile_model.dart'; // Use your EditUserProfile model

class EditProfilePage extends StatefulWidget {
  final String currentUsername;
  final String currentBio;
  final File? currentImage;

  EditProfilePage({
    required this.currentUsername,
    required this.currentBio,
    this.currentImage,
  });

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController usernameController;
  late TextEditingController bioController;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final int bioMaxLength = 150;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: widget.currentUsername);
    bioController = TextEditingController(text: widget.currentBio);
    _imageFile = widget.currentImage;
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

Future<void> _saveChanges() async {
  setState(() {
    isUploading = true; // Show progress indicator
  });

  String? uploadedImageUrl;
  if (_imageFile != null) {
    // Upload the selected image using S3UploadService
    uploadedImageUrl = await _uploadProfileImage(_imageFile!);
  }

  // Check if the fields have changed
  String? newUsername = (usernameController.text != widget.currentUsername) ? usernameController.text : null;
  String? newBio = (bioController.text != widget.currentBio) ? bioController.text : null;
  String? newProfilePic = (uploadedImageUrl != null) ? uploadedImageUrl : null;

  if (newProfilePic != null || newUsername != null || newBio != null) {
    // Call the edit profile API after the image has been uploaded
    UserProfileService userProfileService = UserProfileService();
    int userId = await LoginService().getUserId() ?? 0;

    // Create the updated profile model with only the changed fields
    EditUserProfile updatedProfile = EditUserProfile(
      profilePic: newProfilePic,
      fullName: newUsername,
      bio: newBio,
    );

    // Use the UserProfileService to update the profile
    bool success = await userProfileService.editUserProfile(
      id: userId.toString(),
      editUserProfile: updatedProfile, // Correct parameter name
    );

    if (success) {
      // On successful update, return the updated profile data
      Navigator.pop(context, {
        'username': usernameController.text,
        'bio': bioController.text,
        'imageFile': _imageFile,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No changes detected')),
    );
  }

  setState(() {
    isUploading = false;
  });
}


  Future<String?> _uploadProfileImage(File imageFile) async {
    try {
      S3UploadService s3UploadService = S3UploadService();

      String fileName = imageFile.path.split('/').last;

      // Get the presigned URL from the S3 service
      List<PresignedUrl> presignedUrls = await s3UploadService.getPresignedUrls([fileName], folderName: 'users');

      if (presignedUrls.isNotEmpty) {
        // Upload the file to the presigned URL
        String uploadedUrl = await s3UploadService.uploadFile(presignedUrls[0], XFile(imageFile.path));

        return uploadedUrl; // Return the uploaded file URL
      }
    } catch (e) {
      print('Error uploading profile image: $e');
    }
    return null;
  }

@override
Widget build(BuildContext context) {
  double screenWidth = MediaQuery.of(context).size.width;

  return Material(
    type: MaterialType.transparency,  // Maintain background transparency
    child: Scaffold(
      resizeToAvoidBottomInset: true,  // Adjust layout when the keyboard is open
      backgroundColor: Colors.transparent,  // Keep the profile page as the background
      body: SafeArea(  // Ensure content is visible within safe areas
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.transparent,  // Keep the background transparent
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(  // Allows scrolling when the keyboard appears
                child: Container(
                  width: screenWidth * 0.85,  // Set the width relative to screen size
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        spreadRadius: 5,
                        offset: Offset(0, 8),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(30),  // Rounded corners for the container
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(Icons.close, color: Colors.grey, size: 24),
                        ),
                      ),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          _showImageSourceActionSheet(context);
                        },
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : widget.currentImage != null
                                  ? FileImage(widget.currentImage!)
                                  : AssetImage('assets/images/chef-image.jpg'),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 14,
                              child: Icon(Icons.edit, size: 18, color: Colors.orangeAccent),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: TextStyle(color: Colors.orangeAccent),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.orangeAccent),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          prefixIcon: Icon(Icons.person_outline, color: Colors.orangeAccent),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: bioController,
                        maxLines: 6,
                        maxLength: 100,  // Limit the bio to 100 characters
                        decoration: InputDecoration(
                          labelText: 'Bio (max 100 characters)',
                          labelStyle: TextStyle(color: Colors.orangeAccent),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.orangeAccent),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          prefixIcon: Icon(Icons.info_outline, color: Colors.orangeAccent),
                          counterText: '',  // Hide character counter display
                        ),
                      ),
                      SizedBox(height: 30),
                      isUploading
                          ? CircularProgressIndicator()  // Show progress while uploading
                          : SizedBox(
                              width: screenWidth * 0.7,
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.check, color: Colors.white),
                                label: Text('Save', style: TextStyle(color: Colors.white, fontSize: 16)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent,
                                  padding: EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                ),
                                onPressed: _saveChanges,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.close),
                title: Text('Cancel'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
