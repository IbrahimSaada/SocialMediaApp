import 'package:flutter/material.dart';

class FullScreenImagePage extends StatelessWidget {
  final List<String> mediaUrls;
  final int initialIndex;

  const FullScreenImagePage({
    super.key,
    required this.mediaUrls,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: mediaUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.pop(context); // Close the full-screen image on tap
            },
            child: Center(
              child: InteractiveViewer(
                panEnabled: true, // Enable panning
                minScale: 1.0, // Minimum zoom level (normal size)
                maxScale: 4.0, // Maximum zoom level
                child: Image.network(
                  mediaUrls[index],
                  fit: BoxFit.contain, // Ensure the image fits without distortion
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
