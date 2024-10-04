import 'package:flutter/material.dart';
import 'package:cook/logo.dart';
import 'package:cook/home/home.dart';
import 'package:cook/login/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
        // ignore: prefer_const_constructors
        '/home': (context) =>  HomePage(),
      },
    );
  }
}