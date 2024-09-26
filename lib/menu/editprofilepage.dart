import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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

  void _saveChanges() {
    Navigator.pop(context, {
      'username': usernameController.text,
      'bio': bioController.text,
      'imageFile': _imageFile,
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Material(
      type: MaterialType.transparency, // Ensure transparency
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.transparent, // Ensure background stays transparent
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: screenWidth * 0.85,
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
                  borderRadius: BorderRadius.circular(30),
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
                      maxLength: bioMaxLength,
                      decoration: InputDecoration(
                        labelText: 'Bio',
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
                      ),
                    ),
                    SizedBox(height: 30),
                    SizedBox(
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
