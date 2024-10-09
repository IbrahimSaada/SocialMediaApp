import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'SignatureService.dart';  // Import the SignatureService class

class LoginService {
  final String baseUrl =
      '***REMOVED***/api'; // Base URL for API
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final SignatureService _signatureService = SignatureService();  // Using SignatureService for HMAC

  // Login function
  Future<void> loginUser(String emailOrPhoneNumber, String password) async {
    // Prepare the data for HMAC signature
    String dataToSign = '$emailOrPhoneNumber:$password';

    // Generate HMAC signature using SignatureService
    String signature = await _signatureService.generateHMAC(dataToSign);

    // Perform login API request
    final response = await http.post(
      Uri.parse('$baseUrl/Login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'X-Signature': signature,  // Include signature in headers
      },
      body: jsonEncode(<String, dynamic>{
        'EmailOrPhoneNumber': emailOrPhoneNumber,
        'Password': password,
      }),
    );

    // Check if login is successful
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      var token = data['token']; // Access token
      var refreshToken = data['refreshToken']; // Refresh token
      var userId = data['userId']; // Get user ID from the response
      var profilePic = data['profilePic'];
      var expiration = DateTime.now().add(Duration(minutes: 2)); // Set token expiration time
      await _storeTokenAndUserId(token, refreshToken, userId, expiration, profilePic);
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  // Refresh Access Token
  Future<void> refreshAccessToken() async {
    var refreshToken = await getRefreshToken();

    if (refreshToken == null) {
      throw Exception('Refresh token not found');
    }

    // Generate signature using the refresh token
    String signature = await _signatureService.generateHMAC(refreshToken);

    // Perform token refresh API request
    final response = await http.post(
      Uri.parse('$baseUrl/Login/RefreshToken'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'X-Signature': signature,  // Include signature in headers
      },
      body: jsonEncode(<String, dynamic>{
        'Token': refreshToken,
      }),
    );

    // Check if refresh is successful
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      var token = data['accessToken']; // New access token
      var newRefreshToken = data['refreshToken']; // New refresh token
      var expiration = DateTime.now().add(Duration(minutes: 1)); // Set new expiration time

      // Retrieve the user ID from secure storage
      final userId = await getUserId();

      // Ensure userId is not null before storing
      if (userId != null) {
        await _storeTokenAndUserId(token, newRefreshToken, userId, expiration);
      } else {
        throw Exception('User ID not found');
      }
    } else if (response.statusCode == 401) {
      // Refresh token is invalid or expired
      await logout(); // Log the user out
      throw Exception('Session expired: Please log in again.');
    } else {
      throw Exception('Failed to refresh token: ${response.body}');
    }
  }

  // Logout function
  Future<void> logout() async {
    final String logoutUrl = '$baseUrl/Login/Logout';
    final String? refreshToken = await _secureStorage.read(key: 'refreshToken');
    final int? userId = await getUserId();

    if (refreshToken != null && userId != null) {
      // Generate signature using refreshToken and userId
      String dataToSign = '$userId:$refreshToken';
      String signature = await _signatureService.generateHMAC(dataToSign);

      // Perform logout API request
      final response = await http.post(
        Uri.parse(logoutUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Signature': signature,  // Include signature in headers
        },
        body: jsonEncode({
          'UserId': userId,
          'RefreshToken': refreshToken,
        }),
      );

      // Check if logout is successful
      if (response.statusCode == 200) {
        await _secureStorage.deleteAll(); // Clear all stored tokens
        print('Logged out successfully.');
      } else {
        print('Failed to log out: ${response.body}');
      }
    } else {
      print('No refresh token found or user ID is null.');
    }
  }

  // Store token, refresh token, user ID, and profile picture in secure storage
  Future<void> _storeTokenAndUserId(String token, String refreshToken,
      int userId, DateTime expiration, [String? profilePic]) async {
    await _secureStorage.write(key: 'jwt', value: token);
    await _secureStorage.write(key: 'refreshToken', value: refreshToken);
    await _secureStorage.write(key: 'userId', value: userId.toString());
    await _secureStorage.write(
        key: 'expiration', value: expiration.toIso8601String());
  if (profilePic != null) {
    await _secureStorage.write(key: 'profilePic', value: profilePic);
    print('Profile Pic URL saved: $profilePic');
  }
  else {
    print('Profile pic is null');
  }
  }

  // Get the JWT token from secure storage
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'jwt');
  }

  // Get the refresh token from secure storage
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refreshToken');
  }

  // Get the user ID from secure storage
  Future<int?> getUserId() async {
    String? userIdString = await _secureStorage.read(key: 'userId');
    if (userIdString != null) {
      return int.parse(userIdString);
    }
    return null;
  }

  // Get the token expiration time from secure storage
  Future<DateTime?> getTokenExpiration() async {
    String? expirationString = await _secureStorage.read(key: 'expiration');
    if (expirationString != null) {
      return DateTime.parse(expirationString);
    }
    return null;
  }

  // Get profile picture URL from secure storage
  Future<String?> getProfilePic() async {
    return await _secureStorage.read(key: 'profilePic');
  }

  // Check if the user is logged in
  Future<bool> isLoggedIn() async {
    var token = await getToken();
    var expiration = await getTokenExpiration();

    if (token != null && expiration != null) {
      if (DateTime.now().isBefore(expiration)) {
        return true;
      } else {
        await refreshAccessToken();
        return true;
      }
    }
    return false;
  }
}
