import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import 'LoginService.dart';
import 'SessionExpiredException.dart';
import 'apiService.dart';

class NotificationService {
  static const String baseUrl = '***REMOVED***/api/Notification';

  final ApiService _apiService = ApiService();
  final LoginService _loginService = LoginService();

  /// Fetch user notifications
  Future<List<NotificationModel>> getUserNotifications() async {
    final int? userId = await _loginService.getUserId();
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final Uri uri = Uri.parse('$baseUrl/user/$userId');
    // The server expects a signature over the userId (string form).
    final String signatureData = userId.toString();

    try {
      final http.Response response = await _apiService.makeRequestWithToken(
        uri,
        signatureData,
        'GET',
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => NotificationModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load notifications: ${response.body}');
      }
    } on SessionExpiredException {
      // Propagate so you can handle re-login in your UI
      rethrow;
    } catch (e) {
      throw Exception('Error getting user notifications: $e');
    }
  }

  /// Get the unread notifications count for the current user
  Future<int> getUnreadCount() async {
    final int? userId = await _loginService.getUserId();
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final Uri uri = Uri.parse('$baseUrl/unread-count/$userId');
    final String signatureData = userId.toString();

    try {
      final http.Response response = await _apiService.makeRequestWithToken(
        uri,
        signatureData,
        'GET',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unreadCount'] ?? 0;
      } else {
        throw Exception('Failed to load unread count: ${response.body}');
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      throw Exception('Error getting unread count: $e');
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(int notificationId) async {
    final int? userId = await _loginService.getUserId();
    if (userId == null) {
      throw Exception('User not logged in');
    }

    // According to your backend, the endpoint is:
    // PUT: api/notification/mark-as-read/{notificationId}?userId={userId}
    final Uri uri = Uri.parse('$baseUrl/mark-as-read/$notificationId?userId=$userId');

    // Signature data is "userId:notificationId".
    final String signatureData = '$userId:$notificationId';

    try {
      final http.Response response = await _apiService.makeRequestWithToken(
        uri,
        signatureData,
        'PUT',
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to mark notification as read: ${response.body}');
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for the current user
  Future<void> markAllAsRead() async {
    final int? userId = await _loginService.getUserId();
    if (userId == null) {
      throw Exception('User not logged in');
    }

    // PUT: api/notification/mark-all-as-read/{userId}
    final Uri uri = Uri.parse('$baseUrl/mark-all-as-read/$userId');
    // Signature data is just the userId in string form.
    final String signatureData = userId.toString();

    try {
      final http.Response response = await _apiService.makeRequestWithToken(
        uri,
        signatureData,
        'PUT',
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to mark all notifications as read: ${response.body}');
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      throw Exception('Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<bool> deleteNotification(int notificationId) async {
    final int? userId = await _loginService.getUserId();
    if (userId == null) {
      throw Exception('User not logged in');
    }

    // POST: api/notification/{notificationId}?userId={userId}
    final Uri uri = Uri.parse('$baseUrl/$notificationId?userId=$userId');
    // Signature data is "userId:notificationId".
    final String signatureData = '$userId:$notificationId';

    try {
      final http.Response response = await _apiService.makeRequestWithToken(
        uri,
        signatureData,
        'POST',
      );

      if (response.statusCode == 204) {
        return true; // Successfully deleted
      } else if (response.statusCode == 401) {
        // Unauthorized
        return false;
      } else {
        throw Exception(
          'Failed to delete notification. '
          'Status code: ${response.statusCode}, body: ${response.body}',
        );
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      throw Exception('Error deleting notification: $e');
    }
  }
}
