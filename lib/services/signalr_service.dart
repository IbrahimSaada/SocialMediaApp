// services/signalr_service.dart

import 'package:signalr_core/signalr_core.dart';
import 'package:cook/services/loginservice.dart';

class SignalRService {
  late HubConnection _hubConnection;
  final LoginService _loginService = LoginService();

  Future<void> initSignalR() async {
    // Get the access token from LoginService
    String? accessToken = await _loginService.getToken();

    // Check if the access token is expired and refresh if necessary
    DateTime? expiration = await _loginService.getTokenExpiration();
    if (expiration == null || DateTime.now().isAfter(expiration)) {
      await _loginService.refreshAccessToken();
      accessToken = await _loginService.getToken();
    }

    // Ensure accessToken is not null
    if (accessToken == null) {
      throw Exception('Access token is null. User might not be logged in.');
    }

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          'https://0d21-185-89-86-31.ngrok-free.app/chatHub',
          HttpConnectionOptions(
            accessTokenFactory: () async => accessToken!,
          ),
        )
        .withAutomaticReconnect()
        .build();

    // Start the connection
    await _hubConnection.start();

    // Handle connection events
    _setupConnectionEvents();
  }

  void _setupConnectionEvents() {
    _hubConnection.onclose((error) {
      print('Connection closed: $error');
      // Optionally attempt to reconnect or handle the disconnection
    });

    _hubConnection.onreconnecting((error) {
      print('Reconnecting: $error');
    });

    _hubConnection.onreconnected((connectionId) {
      print('Reconnected: $connectionId');
    });
  }

  // Method to send typing notification
  Future<void> sendTypingNotification(int recipientUserId) async {
    try {
      await _hubConnection.invoke('Typing', args: [recipientUserId]);
      print('Typing notification sent successfully');
    } catch (e) {
      print('Error sending typing notification: $e');
    }
  }

  // Existing methods...
  Future<void> editMessage(int messageId, String newContent) async {
    try {
      await _hubConnection.invoke('EditMessage', args: [messageId, newContent]);
      print('EditMessage invoked successfully');
    } catch (e) {
      print('Error invoking EditMessage: $e');
    }
  }

    Future<void> unsendMessage(int messageId) async {
    try {
      await _hubConnection.invoke('UnsendMessage', args: [messageId]);
      print('UnsendMessage invoked successfully');
    } catch (e) {
      print('Error invoking UnsendMessage: $e');
    }
  }

    // Method to mark messages as read
  Future<void> markMessagesAsRead(int chatId) async {
    try {
      await _hubConnection.invoke('MarkMessagesAsRead', args: [chatId]);
      print('MarkMessagesAsRead invoked successfully');
    } catch (e) {
      print('Error invoking MarkMessagesAsRead: $e');
    }
  }


  HubConnection get hubConnection => _hubConnection;
}
