import 'package:flutter/material.dart';
import '***REMOVED***/services/LoginService.dart';

void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF557C56), // Earthy green theme color
        ),
        scaffoldBackgroundColor: const Color(0xFFF0F0F0),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF557C56), width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('MyApp'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              handleSessionExpired(context);
            },
            child: const Text('Trigger Session Expired'),
          ),
        ),
      ),
    );
  }
}

void handleSessionExpired(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF557C56), width: 2), // Theme color
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFF557C56), // Theme color for the icon
                size: 40,
              ),
              const SizedBox(height: 10),
              const Text(
                'Session Expired',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF557C56), // Theme color for text
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your session has expired. Please log in again to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await LoginService().logout(); // Handle the logout action
                  // ignore: use_build_context_synchronously
                  Navigator.pushReplacementNamed(context, '/login'); // Navigate to login page
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor: const Color(0xFF557C56), // Button background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  shadowColor: Colors.black54,
                  elevation: 5,
                ),
                child: const Text(
                  'Log In Again',
                  style: TextStyle(
                    color: Colors.white, // Button text color
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
