import 'package:flutter/material.dart';
import 'dart:async';
import '***REMOVED***/login/login_page.dart';
import '***REMOVED***/services/LoginService.dart';
import '***REMOVED***/home/home.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();  // Secure Storage instance

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..forward();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _navigateToNextScreen();
  }

  Future<void> _storeSecretKeyOnInit() async {
    // Check if the secret key is already stored
    String? storedKey = await _secureStorage.read(key: 'secretKey');

    if (storedKey == null) {
      // If not stored, store the secret key
      const String secretKey = 'YourSharedSecretKeyForRequestSigning';  // Replace with your actual secret key
      await _secureStorage.write(key: 'secretKey', value: secretKey);
      // ignore: avoid_print
      print('Secret key stored in secure storage.');
    } else {
      // ignore: avoid_print
      print('Secret key already exists in secure storage.');
    }
  }

  Future<void> _navigateToNextScreen() async {
    // Store the secret key during app initialization
    await _storeSecretKeyOnInit();

    // Simulate a delay for the splash screen
    await Future.delayed(const Duration(seconds: 3));

    try {
      // Check if the user is logged in (this includes checking if the token needs to be refreshed)
      bool isLoggedIn = await LoginService().isLoggedIn();

      if (isLoggedIn) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushReplacement(
          // ignore: prefer_const_constructors
          MaterialPageRoute(builder: (context) =>  HomePage()),
        );
      } else {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      // If there's an issue, such as a failed token refresh, log the user out
      await LoginService().logout();  // This will clear tokens and delete from DB
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _animation,
        child: Center(
          child: Image.asset('assets/adamgay.jpg'),
        ),
      ),
    );
  }
}
