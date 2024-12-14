import 'package:signalr_core/signalr_core.dart';
import 'package:cook/services/loginservice.dart';
import 'package:cook/services/signatureservice.dart';

class SignalRService {
  late HubConnection _hubConnection;
  final LoginService _loginService = LoginService();
  final SignatureService _signatureService = SignatureService();

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
          'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/chatHub', // Replace with your actual URL
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

  // Helper method to generate signature and invoke a hub method with it
  Future<dynamic> _invokeWithSignature(String methodName, List<Object?> args, String dataToSign) async {
    String signature = await _signatureService.generateHMAC(dataToSign);
    args.add(signature);
    return await _hubConnection.invoke(methodName, args: args);
  }

  Future<void> sendTypingNotification(int recipientUserId) async {
    try {
      int senderId = await _loginService.getUserId() ?? 0;
      String dataToSign = "$senderId:$recipientUserId";

      await _invokeWithSignature('Typing', [recipientUserId], dataToSign);
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
      int userId = await _loginService.getUserId() ?? 0;
      String dataToSign = "$userId:$messageId:$newContent";

      await _invokeWithSignature('EditMessage', [messageId, newContent], dataToSign);
      print('EditMessage invoked successfully');
    } catch (e) {
      print('Error invoking EditMessage: $e');
    }
  }

  Future<void> unsendMessage(int messageId) async {
    try {
      int userId = await _loginService.getUserId() ?? 0;
      String dataToSign = "$userId:$messageId";

      await _invokeWithSignature('UnsendMessage', [messageId], dataToSign);
      print('UnsendMessage invoked successfully');
    } catch (e) {
      print('Error invoking UnsendMessage: $e');
    }
  }

  Future<void> markMessagesAsRead(int chatId) async {
    try {
      int userId = await _loginService.getUserId() ?? 0;
      String dataToSign = "$userId:$chatId";

      await _invokeWithSignature('MarkMessagesAsRead', [chatId], dataToSign);
      print('MarkMessagesAsRead invoked successfully');
    } catch (e) {
      print('Error invoking MarkMessagesAsRead: $e');
    }
  }

  Future<void> createChat(int recipientUserId) async {
    try {
      int initiatorUserId = await _loginService.getUserId() ?? 0;
      String dataToSign = "$initiatorUserId:$recipientUserId";

      await _invokeWithSignature('CreateChat', [recipientUserId], dataToSign);
      print('CreateChat invoked successfully');
    } catch (e) {
      print('Error invoking CreateChat: $e');
    }
  }

  // New method for sending a message with signature
  // Server method signature: SendMessage(int recipientUserId, string messageContent, string messageType, List<MediaItemDto> mediaItems, string signature)
  Future<void> sendMessage(int recipientUserId, String messageContent, String messageType, List<dynamic>? mediaItems) async {
    try {
      int senderId = await _loginService.getUserId() ?? 0;
      String dataToSign = "$senderId:$recipientUserId:$messageContent";

      await _invokeWithSignature('SendMessage', [recipientUserId, messageContent, messageType, mediaItems], dataToSign);
      print('SendMessage invoked successfully');
    } catch (e) {
      print('Error invoking SendMessage: $e');
      rethrow;
    }
  }

  void setupListeners({
    Function(dynamic chatDto)? onChatCreated,
    Function(dynamic chatDto)? onNewChatNotification,
    Function(String errorMessage)? onError,
    Function()? onReceiveMessage,
    Function()? onMessageSent,
    Function()? onMessageEdited,
    Function()? onMessageUnsent,
    Function()? onMessagesRead,
    Function(int senderId)? onUserTyping,
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

    if (onUserTyping != null) {
      _hubConnection.on('UserTyping', (args) {
        if (args != null && args.isNotEmpty) {
          int senderId = args[0] as int;
          onUserTyping(senderId);
        }
      });
    }
  }

  HubConnection get hubConnection => _hubConnection;
}