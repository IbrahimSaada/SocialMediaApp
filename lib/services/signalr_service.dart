import 'package:signalr_core/signalr_core.dart';
import 'package:cook/services/loginservice.dart';

class SignalRService {
  late HubConnection _hubConnection;
  final LoginService _loginService = LoginService();

  Future<void> initSignalR() async {
    String? accessToken = await _loginService.getToken();
    DateTime? expiration = await _loginService.getTokenExpiration();

    if (expiration == null || DateTime.now().isAfter(expiration)) {
      await _loginService.refreshAccessToken();
      accessToken = await _loginService.getToken();
    }

    if (accessToken == null) {
      throw Exception('Access token is null. User might not be logged in.');
    }

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          'https://fe3c-185-97-92-121.ngrok-free.app/chatHub',
          HttpConnectionOptions(
            accessTokenFactory: () async => accessToken,
          ),
        )
        .withAutomaticReconnect()
        .build();

    await _hubConnection.start();
    _setupConnectionEvents();
  }

  void _setupConnectionEvents() {
    _hubConnection.onclose((error) {
      print('Connection closed: $error');
    });

    _hubConnection.onreconnecting((error) {
      print('Reconnecting: $error');
    });

    _hubConnection.onreconnected((connectionId) {
      print('Reconnected: $connectionId');
    });
  }

  Future<void> stopConnection() async {
    await _hubConnection.stop();
    print('SignalR connection stopped.');
  }

  Future<void> sendTypingNotification(int recipientUserId) async {
    try {
      await _hubConnection.invoke('Typing', args: [recipientUserId]);
      print('Typing notification sent successfully');
    } catch (e) {
      print('Error sending typing notification: $e');
    }
  }

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

  Future<void> markMessagesAsRead(int chatId) async {
    try {
      await _hubConnection.invoke('MarkMessagesAsRead', args: [chatId]);
      print('MarkMessagesAsRead invoked successfully');
    } catch (e) {
      print('Error invoking MarkMessagesAsRead: $e');
    }
  }

  Future<void> createChat(int recipientUserId) async {
    try {
      await _hubConnection.invoke('CreateChat', args: [recipientUserId]);
      print('CreateChat invoked successfully');
    } catch (e) {
      print('Error invoking CreateChat: $e');
    }
  }

  // We add callbacks for the events that can affect the chat list (like last message and unread count)
  void setupListeners({
    Function(dynamic chatDto)? onChatCreated,
    Function(dynamic chatDto)? onNewChatNotification,
    Function(String errorMessage)? onError,

    // New callbacks to handle real-time updates to chat list
    Function()? onReceiveMessage,
    Function()? onMessageSent,
    Function()? onMessageEdited,
    Function()? onMessageUnsent,
    Function()? onMessagesRead,
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

    // New event listeners for real-time chat updates
    // These don't necessarily provide chatDto, but we know any of these events may affect the last message/unread counts.
    if (onReceiveMessage != null) {
      _hubConnection.on('ReceiveMessage', (args) {
        onReceiveMessage();
      });
    }

    if (onMessageSent != null) {
      _hubConnection.on('MessageSent', (args) {
        onMessageSent();
      });
    }

    if (onMessageEdited != null) {
      _hubConnection.on('MessageEdited', (args) {
        onMessageEdited();
      });
    }

    if (onMessageUnsent != null) {
      _hubConnection.on('MessageUnsent', (args) {
        onMessageUnsent();
      });
    }

    if (onMessagesRead != null) {
      _hubConnection.on('MessagesRead', (args) {
        onMessagesRead();
      });
    }
  }

  HubConnection get hubConnection => _hubConnection;
}
