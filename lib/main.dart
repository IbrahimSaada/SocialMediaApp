import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:cook/logo.dart';
import 'package:cook/home/home.dart';
import 'package:cook/login/login_page.dart';
import 'package:cook/profile/otheruserprofilepage.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'services/pushnotificationservice.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize the PushNotificationService
  await PushNotificationService().init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinkListener();
  }

  void _initDeepLinkListener() {
    _sub = _appLinks.uriLinkStream.listen((Uri uri) {
      if (uri.scheme == 'cooktalk' && uri.host == 'profile' && uri.pathSegments.isNotEmpty) {
        final userId = uri.pathSegments.last;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OtherUserProfilePage(otherUserId: int.parse(userId)),
          ),
        );
      }
    }, onError: (err) {
      print("Error with deep link: $err");
    });
  }


  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFF45F67),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFFF45F67),
          secondary: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF45F67),
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: Color(0xFFF45F67),
          textTheme: ButtonTextTheme.primary,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFFF45F67),
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
