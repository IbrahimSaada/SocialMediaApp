import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '***REMOVED***/services/LoginService.dart';

class NotificationService {
  final String apiUrl =
      'https://bace-185-97-92-44.ngrok-free.app/api/Notification';

  Future<List<NotificationModel>> getUserNotifications() async {
    final int? userId = await LoginService().getUserId();

    if (userId == null) {
      throw Exception('User not logged in');
    }

    final response = await http.get(Uri.parse('$apiUrl/user/$userId'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body
          .map((dynamic item) => NotificationModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  /// Get the unread notifications count for the current user
  Future<int> getUnreadCount() async {
    final int? userId = await LoginService().getUserId();

    if (userId == null) {
      throw Exception('User not logged in');
    }

    // Adjust your endpoint to match your API route for unread count:
    // e.g., GET /api/Notification/unread-count/{userId}
    // expected response: { "unreadCount": 34 }
    final response = await http.get(Uri.parse('$apiUrl/unread-count/$userId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['unreadCount'] ?? 0;
    } else {
      throw Exception('Failed to load unread count');
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(int notificationId) async {
    // PUT: api/notification/mark-as-read/{notificationId}
    final response = await http.put(
      Uri.parse('$apiUrl/mark-as-read/$notificationId'),
    );

    // Typically returns 204 NoContent on success
    if (response.statusCode != 204) {
      throw Exception('Failed to mark notification as read');
    }
  }

  /// Mark all notifications as read for the current user
  Future<void> markAllAsRead() async {
    final int? userId = await LoginService().getUserId();
    if (userId == null) {
      throw Exception('User not logged in');
    }

    // PUT: api/notification/mark-all-as-read/{userId}
    final response = await http.put(
      Uri.parse('$apiUrl/mark-all-as-read/$userId'),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to mark all notifications as read');
    }
  }

  /// Delete a notification by ID for the current user
  ///
  /// Returns true if deletion is successful, false if unauthorized (401),
  /// otherwise throws an exception.
  Future<bool> deleteNotification(int notificationId) async {
    final int? userId = await LoginService().getUserId();
    if (userId == null) {
      throw Exception('User not logged in');
    }

    // POST: api/notification/{notificationId}?userId={userId}
    // Returns 204 on success, 401 if unauthorized
    final url = Uri.parse('$apiUrl/$notificationId?userId=$userId');
    final response = await http.post(url);

    if (response.statusCode == 204) {
      // Successfully deleted
      return true;
    } else if (response.statusCode == 401) {
      // Unauthorized
      return false;
    } else {
      throw Exception(
        'Failed to delete notification. Status code: ${response.statusCode}',
      );
    }
  }
}
