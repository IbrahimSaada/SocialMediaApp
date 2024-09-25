import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Messaging',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    // Request permission to display notifications
    FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Get FCM token
    FirebaseMessaging.instance.getToken().then((token) {
      setState(() {
        _fcmToken = token;
      });
      print("FCM Token: $token"); // Print the FCM token in the console
    });

    // Listen to FCM token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      setState(() {
        _fcmToken = newToken;
      });
      print("Refreshed FCM Token: $newToken");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Firebase Messaging"),
      ),
      body: Center(
        child: _fcmToken == null
            ? CircularProgressIndicator() // Show loading until the token is fetched
            : Text("FCM Token: $_fcmToken"), // Display the FCM token
      ),
    );
  }
}
