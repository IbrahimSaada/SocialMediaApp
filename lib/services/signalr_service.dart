// signalr_service.dart

import 'package:signalr_core/signalr_core.dart';
import 'package:cook/services/LoginService.dart';
import 'package:cook/services/SignatureService.dart';
import 'package:cook/services/SessionExpiredException.dart';

class SignalRService {
  late HubConnection _hubConnection;
  final LoginService _loginService = LoginService();
  final SignatureService _signatureService = SignatureService();

  /// Initialize the SignalR connection with session expiration checks
  Future<void> initSignalR() async {
    // 1) Check if token is valid or refresh it
    String? accessToken = await _ensureValidToken();
    if (accessToken == null) {
      // If we cannot get a valid token, explicitly throw
      throw SessionExpiredException('No valid token for SignalR connection');
    }

    // 2) Build the HubConnection
    _hubConnection = HubConnectionBuilder()
        .withUrl(
          'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/chatHub',
          HttpConnectionOptions(
            accessTokenFactory: () async => accessToken,
          ),
        )
        .withAutomaticReconnect()
        .build();

    // 3) Start the connection
    await _hubConnection.start();
    // If the token is invalid, typically the server might close the socket,
    // but we do our best to validate before building.

    // 4) Setup local events
    _setupConnectionEvents();

    print('SignalR connection started successfully');
  }

  /// Helper method to ensure the token is valid or refresh it
  Future<String?> _ensureValidToken() async {
    String? accessToken = await _loginService.getToken();
    final DateTime? expiration = await _loginService.getTokenExpiration();

    // If the token is missing or expired, attempt refresh
    if (accessToken == null ||
        expiration == null ||
        DateTime.now().isAfter(expiration)) {
      print('Access token is invalid or expired. Attempting refresh...');
      try {
        await _loginService.refreshAccessToken();
        accessToken = await _loginService.getToken();
      } catch (e) {
        print('Failed to refresh token => $e');
        // If we fail here, we throw SessionExpired so UI can handle re-login
        throw SessionExpiredException('Failed to refresh token for SignalR');
      }
    }

    // If still null, session is expired
    if (accessToken == null) {
      throw SessionExpiredException('No valid token found for SignalR');
    }

    return accessToken;
  }

  /// Setup connection events (close, reconnected, reconnecting)
  void _setupConnectionEvents() {
    _hubConnection.onclose((error) {
      print('Connection closed: $error');
    });

    _hubConnection.onreconnecting((error) {
      print('Reconnecting: $error');
    });

    _hubConnection.onreconnected((connectionId) {
      print('Reconnected with connectionId=$connectionId');
    });
  }

  /// Stop the SignalR connection
  Future<void> stopConnection() async {
    await _hubConnection.stop();
    print('SignalR connection stopped.');
  }

  /// Private helper to generate signature & invoke a Hub method
  Future<dynamic> _invokeWithSignature(
    String methodName,
    List<Object?> args,
    String dataToSign,
  ) async {
    final String signature = await _signatureService.generateHMAC(dataToSign);
    // Append signature as last argument
    args.add(signature);

    // If we suspect the token might be expired in the middle, we can re-check it:
    await _ensureValidToken(); // optional extra check

    return await _hubConnection.invoke(methodName, args: args);
  }

  /// --------------- TYPING ---------------
  Future<void> sendTypingNotification(int recipientUserId) async {
    try {
      final int senderId = await _loginService.getUserId() ?? 0;
      final String dataToSign = '$senderId:$recipientUserId';

      await _invokeWithSignature('Typing', [recipientUserId], dataToSign);
      print('Typing notification sent successfully');
    } on SessionExpiredException {
      rethrow; // Let UI handle session expired
    } catch (e) {
      print('Error sending typing notification: $e');
    }
  }

  /// --------------- MESSAGES CRUD ---------------
  Future<void> sendMessage(
    int recipientUserId,
    String messageContent,
    String messageType,
    List<dynamic>? mediaItems,
  ) async {
    try {
      final int senderId = await _loginService.getUserId() ?? 0;
      final String dataToSign = '$senderId:$recipientUserId:$messageContent';

      await _invokeWithSignature(
        'SendMessage',
        [recipientUserId, messageContent, messageType, mediaItems],
        dataToSign,
      );
      print('SendMessage invoked successfully');
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      print('Error invoking SendMessage: $e');
      rethrow; // Rethrow so UI can handle error events (like blocked)
    }
  }

  Future<void> editMessage(int messageId, String newContent) async {
    try {
      final int userId = await _loginService.getUserId() ?? 0;
      final String dataToSign = '$userId:$messageId:$newContent';

      await _invokeWithSignature('EditMessage', [messageId, newContent], dataToSign);
      print('EditMessage invoked successfully');
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      print('Error invoking EditMessage: $e');
    }
  }

  Future<void> unsendMessage(int messageId) async {
    try {
      final int userId = await _loginService.getUserId() ?? 0;
      final String dataToSign = '$userId:$messageId';

      await _invokeWithSignature('UnsendMessage', [messageId], dataToSign);
      print('UnsendMessage invoked successfully');
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      print('Error invoking UnsendMessage: $e');
    }
  }

  Future<void> markMessagesAsRead(int chatId) async {
    try {
      final int userId = await _loginService.getUserId() ?? 0;
      final String dataToSign = '$userId:$chatId';

      await _invokeWithSignature('MarkMessagesAsRead', [chatId], dataToSign);
      print('MarkMessagesAsRead invoked successfully');
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      print('Error invoking MarkMessagesAsRead: $e');
    }
  }

  /// --------------- CHATS ---------------
  Future<void> createChat(int recipientUserId) async {
    try {
      final int initiatorUserId = await _loginService.getUserId() ?? 0;
      final String dataToSign = '$initiatorUserId:$recipientUserId';

      await _invokeWithSignature('CreateChat', [recipientUserId], dataToSign);
      print('CreateChat invoked successfully');
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      print('Error invoking CreateChat: $e');
      rethrow; // Let UI handle blocked or other errors
    }
  }

  /// If you needed to fetch messages via Hub calls
  Future<List<dynamic>> fetchMessages(int chatId, int pageNumber, int pageSize) async {
    try {
      // This method doesn't do signature in your code, but you can do so if the server requires it
      return await _hubConnection.invoke(
        'FetchMessages',
        args: [chatId, pageNumber, pageSize],
      ) as List<dynamic>;
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      print('Error fetching messages via SignalR: $e');
      return [];
    }
  }

  /// Setup listeners for server events
  void setupListeners({
    Function(dynamic)? onChatCreated,
    Function(dynamic)? onNewChatNotification,
    Function(String)? onError,
    Function()? onReceiveMessage,
    Function()? onMessageSent,
    Function()? onMessageEdited,
    Function()? onMessageUnsent,
    Function()? onMessagesRead,
    Function(int)? onUserTyping,
  }) {
    // ChatCreated
    if (onChatCreated != null) {
      _hubConnection.on('ChatCreated', (args) {
        if (args != null && args.isNotEmpty) {
          final chatDto = args[0];
          if (chatDto != null) {
            onChatCreated(chatDto);
          } else {
            print('ChatCreated event => null chatDto');
          }
        }
      });
    }

    // NewChatNotification
    if (onNewChatNotification != null) {
      _hubConnection.on('NewChatNotification', (args) {
        if (args != null && args.isNotEmpty) {
          final chatDto = args[0];
          if (chatDto != null) {
            onNewChatNotification(chatDto);
          }
        }
      });
    }

    // Error
    if (onError != null) {
      _hubConnection.on('Error', (args) {
        if (args != null && args.isNotEmpty) {
          final errorMessage = args[0];
          if (errorMessage != null) {
            print('Server Error: $errorMessage');
            onError(errorMessage);
          }
        }
      });
    }

    // Some events just signal “something changed”; no data
    if (onReceiveMessage != null) {
      _hubConnection.on('ReceiveMessage', (args) => onReceiveMessage());
    }
    if (onMessageSent != null) {
      _hubConnection.on('MessageSent', (args) => onMessageSent());
    }
    if (onMessageEdited != null) {
      _hubConnection.on('MessageEdited', (args) => onMessageEdited());
    }
    if (onMessageUnsent != null) {
      _hubConnection.on('MessageUnsent', (args) => onMessageUnsent());
    }
    if (onMessagesRead != null) {
      _hubConnection.on('MessagesRead', (args) => onMessagesRead());
    }

    if (onUserTyping != null) {
      _hubConnection.on('UserTyping', (args) {
        if (args != null && args.isNotEmpty) {
          final senderId = args[0] as int;
          onUserTyping(senderId);
        }
      });
    }
  }

  HubConnection get hubConnection => _hubConnection;
}
