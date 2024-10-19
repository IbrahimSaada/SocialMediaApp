// widgets/fullscreen_image_page.dart

import 'package:flutter/material.dart';


class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImagePage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.pop(context); // Close the full-screen image on tap
          },
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}