import 'package:flutter/material.dart';
import '***REMOVED***/logo.dart';
import '***REMOVED***/home/home.dart';
import '***REMOVED***/login/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFFF45F67), // Your primary color
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color(0xFFF45F67), // Set primary color
          secondary: Colors.white,    // Set secondary color
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFF45F67),
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Color(0xFFF45F67),
          textTheme: ButtonTextTheme.primary,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFFF45F67), // Set the cursor color here
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}
