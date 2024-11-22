import 'package:firebase_messaging/firebase_messaging.dart';
import 'LoginService.dart';

class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Singleton pattern
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> init() async {
    // Request permission
    await _firebaseMessaging.requestPermission();

    // Get the token
    _fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $_fcmToken');

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      _fcmToken = newToken;
      print('Refreshed FCM Token: $_fcmToken');
      // Update the backend
      await LoginService().updateFcmToken(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message in the foreground!');
      // Handle the message
    });
  }

  Future<String?> getFcmToken() async {
    if (_fcmToken != null) {
      return _fcmToken;
    } else {
      _fcmToken = await _firebaseMessaging.getToken();
      return _fcmToken;
    }
  }
}
