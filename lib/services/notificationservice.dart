// notification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import 'package:cook/services/LoginService.dart';

class NotificationService {
  final String apiUrl =
      'https://8a93-185-97-92-72.ngrok-free.app/api/Notification';

  Future<List<NotificationModel>> getUserNotifications() async {
    final int? userId = await LoginService().getUserId();

    if (userId == null) {
      throw Exception('User not logged in');
    }

    final response = await http.get(Uri.parse('$apiUrl/user/$userId'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<NotificationModel> notifications = body
          .map((dynamic item) => NotificationModel.fromJson(item))
          .toList();
      return notifications;
    } else {
      throw Exception('Failed to load notifications');
    }
  }
}
