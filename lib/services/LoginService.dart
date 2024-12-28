import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'SignatureService.dart';
import 'SessionExpiredException.dart';
import 'pushnotificationservice.dart';
import 'BannedException.dart';

class LoginService {
  final String baseUrl =
      '***REMOVED***/api';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final SignatureService _signatureService = SignatureService();

  // Singleton pattern
  static final LoginService _instance = LoginService._internal();
  factory LoginService() => _instance;
  LoginService._internal();

  Future<void> loginUser(String email, String password) async {
    String? fcmToken = await PushNotificationService().getFcmToken();
    String dataToSign = '$email:$password:$fcmToken';
    String signature = await _signatureService.generateHMAC(dataToSign);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'X-Signature': signature,
        },
        body: jsonEncode(<String, dynamic>{
          'Email': email,
          'Password': password,
          'FcmToken': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        // Check if user is banned
        if (data['isBanned'] == true) {
          final banReason = data['banReason'] ?? 'Violation of the rules.';
          final banExpiresAt = data['banExpiresAt'] ?? 'N/A';
          throw BannedException(banReason, banExpiresAt);
        }

        // Check if user is verified
        if (data['isVerified'] == false) {
          throw Exception(data['message'] ??
              'Account not verified. Please verify your account to proceed.');
        }

        var token = data['token'];
        var refreshToken = data['refreshToken'];
        var userId = data['userId'];
        var fullname = data['fullname'];
        var profilePic = data['profilePic'];

        // For demo, we set expiration to 2 minutes from now. Adjust as needed.
        var expiration = DateTime.now().add(const Duration(minutes: 2));

        // Store the tokens & user info
        await _storeTokenAndUserId(
          token,
          refreshToken,
          userId,
          expiration,
          profilePic,
        );

        // Also store the user's fullname for convenience
        await _secureStorage.write(key: 'fullname', value: fullname);

      } else if (response.statusCode == 401) {
        // Check if body indicates ban
        final responseBody = response.body.toLowerCase();
        if (responseBody.contains('banned')) {
          throw BannedException('You have been banned', 'N/A');
        } else {
          throw Exception('Unauthorized: ${response.body}');
        }
      } else if (response.statusCode == 500) {
        throw Exception('Server error (500). Please try again later.');
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } on SocketException {
      throw Exception('No network connection. Please check your internet.');
    }
  }

  Future<void> refreshAccessToken() async {
    var refreshToken = await getRefreshToken();
    if (refreshToken == null) {
      throw Exception('Refresh token not found');
    }

    String signature = await _signatureService.generateHMAC(refreshToken);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Login/RefreshToken'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'X-Signature': signature,
        },
        body: jsonEncode(<String, dynamic>{
          'Token': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var token = data['accessToken'];
        var newRefreshToken = data['refreshToken'];
        // For demo, set shorter token expiration
        var expiration = DateTime.now().add(const Duration(minutes: 1));

        final userId = await getUserId();
        if (userId != null) {
          await _storeTokenAndUserId(token, newRefreshToken, userId, expiration);
        } else {
          throw Exception('User ID not found');
        }
      } else if (response.statusCode == 401) {
        await logout(); // triggers the logic below
        throw SessionExpiredException();
      } else if (response.statusCode == 500) {
        throw Exception('Server error (500). Please try again later.');
      } else {
        throw Exception('Failed to refresh token: ${response.body}');
      }
    } on SocketException {
      throw Exception('No network connection. Please check your internet.');
    }
  }

  /// NEW logout logic that respects "rememberMe"
  Future<void> logout() async {
    final String logoutUrl = '$baseUrl/Login/Logout';
    final String? refreshToken = await _secureStorage.read(key: 'refreshToken');
    final int? userId = await getUserId();

    // 1) Read whether user had 'rememberMe' set
    final String? rememberMeValue = await _secureStorage.read(key: 'rememberMe');
    final bool rememberMe = (rememberMeValue == 'true');

    if (refreshToken != null && userId != null) {
      String dataToSign = '$userId:$refreshToken';
      String signature = await _signatureService.generateHMAC(dataToSign);
      try {
        final response = await http.post(
          Uri.parse(logoutUrl),
          headers: {
            'Content-Type': 'application/json',
            'X-Signature': signature,
          },
          body: jsonEncode({
            'UserId': userId,
            'RefreshToken': refreshToken,
          }),
        );

        if (response.statusCode == 200) {
          // 2) Delete tokens, userId, expiration always
          await _secureStorage.delete(key: 'jwt');
          await _secureStorage.delete(key: 'refreshToken');
          await _secureStorage.delete(key: 'userId');
          await _secureStorage.delete(key: 'expiration');
          await _secureStorage.delete(key: 'fullname');
          await _secureStorage.delete(key: 'profilePic');

          // 3) If user did NOT choose rememberMe, also clear savedEmail/savedPassword
          if (!rememberMe) {
            await _secureStorage.delete(key: 'savedEmail');
            await _secureStorage.delete(key: 'savedPassword');
          }

          print('Logged out successfully.');
        } else if (response.statusCode == 500) {
          throw Exception('Server error (500). Please try again later.');
        } else {
          print('Failed to log out: ${response.body}');
        }
      } on SocketException {
        throw Exception('No network connection. Please check your internet.');
      }
    } else {
      print('No refresh token found or user ID is null.');
    }
  }

  Future<void> _storeTokenAndUserId(
    String token,
    String refreshToken,
    int userId,
    DateTime expiration, [
    String? profilePic,
  ]) async {
    await _secureStorage.write(key: 'jwt', value: token);
    await _secureStorage.write(key: 'refreshToken', value: refreshToken);
    await _secureStorage.write(key: 'userId', value: userId.toString());
    await _secureStorage.write(
      key: 'expiration',
      value: expiration.toIso8601String(),
    );
    if (profilePic != null) {
      await _secureStorage.write(key: 'profilePic', value: profilePic);
      print('Profile Pic URL saved: $profilePic');
    } else {
      print('Profile pic is null');
    }
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'jwt');
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refreshToken');
  }

  Future<int?> getUserId() async {
    String? userIdString = await _secureStorage.read(key: 'userId');
    if (userIdString != null) {
      return int.parse(userIdString);
    }
    return null;
  }

  Future<String> getFullname() async {
    String? fullname = await _secureStorage.read(key: 'fullname');
    return fullname ?? "User";
  }

  Future<DateTime?> getTokenExpiration() async {
    String? expirationString = await _secureStorage.read(key: 'expiration');
    if (expirationString != null) {
      return DateTime.parse(expirationString);
    }
    return null;
  }

  Future<String?> getProfilePic() async {
    return await _secureStorage.read(key: 'profilePic');
  }

  Future<bool> isLoggedIn() async {
    var token = await getToken();
    var expiration = await getTokenExpiration();
    if (token != null && expiration != null) {
      if (DateTime.now().isBefore(expiration)) {
        // Token still valid
        return true;
      } else {
        // Token expired, try to refresh
        await refreshAccessToken();
        return true; // If refresh fails, it throws and logs out
      }
    }
    return false;
  }

  Future<void> updateFcmToken(String newToken) async {
    final userId = await getUserId();
    final token = await getToken();

    if (userId == null || token == null) {
      print('User is not logged in.');
      return;
    }

    String dataToSign = newToken;
    String signature = await _signatureService.generateHMAC(dataToSign);

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/Login/UpdateFcmToken/$userId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'X-Signature': signature,
        },
        body: jsonEncode(<String, dynamic>{
          'FcmToken': newToken,
        }),
      );

      if (response.statusCode == 200) {
        print('FCM token updated on the backend.');
      } else if (response.statusCode == 500) {
        throw Exception('Server error (500). Please try again later.');
      } else {
        throw Exception('Failed to update FCM token: ${response.body}');
      }
    } on SocketException {
      throw Exception('No network connection. Please check your internet.');
    }
  }
}
