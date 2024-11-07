// signalr_service.dart

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
          'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/chatHub',
          HttpConnectionOptions(
            accessTokenFactory: () async => accessToken,
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

  // Method to fetch messages via SignalR
  Future<List<dynamic>> fetchMessages(int chatId, int pageNumber, int pageSize) async {
    try {
      var result = await _hubConnection.invoke('FetchMessages', args: [chatId, pageNumber, pageSize]);
      return result as List<dynamic>;
    } catch (e) {
      print('Error fetching messages via SignalR: $e');
      return [];
    }
  }

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

  // Method to create a new chat
  Future<void> createChat(int recipientUserId) async {
    try {
      await _hubConnection.invoke('CreateChat', args: [recipientUserId]);
      print('CreateChat invoked successfully');
    } catch (e) {
      print('Error invoking CreateChat: $e');
    }
  }

  // Method to listen for real-time events
  void setupListeners({
    Function(dynamic chatDto)? onChatCreated,
    Function(dynamic chatDto)? onNewChatNotification,
    Function(String errorMessage)? onError,
  }) {
    if (onChatCreated != null) {
      _hubConnection.on('ChatCreated', (args) {
        if (args != null && args.isNotEmpty) {
          var chatDto = args[0];
          if (chatDto != null) {
            onChatCreated(chatDto);
          } else {
            print('ChatCreated event received with null chatDto.');
          }
        } else {
          print('ChatCreated event received with null or empty args.');
        }
      });
    }

    if (onNewChatNotification != null) {
      _hubConnection.on('NewChatNotification', (args) {
        if (args != null && args.isNotEmpty) {
          var chatDto = args[0];
          if (chatDto != null) {
            onNewChatNotification(chatDto);
          } else {
            print('NewChatNotification event received with null chatDto.');
          }
        } else {
          print('NewChatNotification event received with null or empty args.');
        }
      });
    }

    // Handle Error messages from the server
    if (onError != null) {
      _hubConnection.on('Error', (args) {
        if (args != null && args.isNotEmpty) {
          var errorMessage = args[0];
          if (errorMessage != null) {
            print('Server Error: $errorMessage');
            onError(errorMessage);
          } else {
            print('Error event received with null errorMessage.');
          }
        } else {
          print('Error event received with null or empty args.');
        }
      });
    }
  }

  HubConnection get hubConnection => _hubConnection;
}
