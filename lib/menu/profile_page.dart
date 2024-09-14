import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner:
          false, // Add this line to remove the debug watermark
      home: ProfilePage(),
    ),
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage(
                'assets/chef.jpg'), // Replace with actual profile pic URL
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '@ahmadghosen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.qr_code),
                onPressed: () {
                  // Add your QR code generation and display logic here
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text('50', style: TextStyle(fontSize: 18)),
                  Text('Following'),
                ],
              ),
              SizedBox(width: 30),
              Column(
                children: [
                  Text('532', style: TextStyle(fontSize: 18)),
                  Text('Followers'),
                ],
              ),
            ],
          ),
          // bio edit
          const EditableTextWidget(),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Icon(Icons.library_books, size: 25, color: Colors.orange),
                ],
              ),
              SizedBox(width: 100), // Add space between icons
              Column(
                children: [
                  Icon(Icons.bookmark, size: 25, color: Colors.orange),
                ],
              ),
              SizedBox(width: 100), // Add space between icons
              Column(
                children: [
                  Icon(Icons.favorite, size: 25, color: Colors.orange),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200, // fixed height
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Number of columns
                crossAxisSpacing: 10, // Spacing between columns
                mainAxisSpacing: 10, // Spacing between rows
              ),
              itemCount: 6, // Number of videos (adjust as needed)
              itemBuilder: (context, index) {
                // Replace with your actual video data (e.g., video URL, thumbnail)
                // ignore: avoid_unnecessary_containers
                return Container(
                  child: Stack(
                    children: [
                      if (index ==
                          0) // Display the image only for the first item
                        Image.asset(
                          'assets/1.png', // Replace with actual asset image name
                          fit: BoxFit.cover,
                        ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '${(index + 1) * 10}K', // Replace with your actual view count
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const Align(
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.play_circle,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EditableTextWidget extends StatefulWidget {
  const EditableTextWidget({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EditableTextWidgetState createState() => _EditableTextWidgetState();
}

class _EditableTextWidgetState extends State<EditableTextWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller.text = 'bioo';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            setState(() {
              _isEditing = !_isEditing;
            });
          },
        ),
        ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: 200), // Adjust the maximum width
          child: _isEditing
              ? TextField(
                  controller: _controller,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Text(
                  _controller.text,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}
