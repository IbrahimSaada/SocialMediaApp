// apiService.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'LoginService.dart';
import 'SignatureService.dart';
import 'SessionExpiredException.dart';

class ApiService {
  final LoginService _loginService = LoginService();
  final SignatureService _signatureService = SignatureService();

  Future<http.Response> makeRequestWithToken(
    Uri uri,
    String signatureData,
    String method, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      if (!await _loginService.isLoggedIn()) {
        throw Exception("User not logged in.");
      }

      String? token = await _loginService.getToken();
      String signature = await _signatureService.generateHMAC(signatureData);

      final requestHeaders = {
        'Content-Type': 'application/json',
        'X-Signature': signature,
        'Authorization': 'Bearer $token',
        ...?headers,
      };

      http.Response response;

      // Send the HTTP request based on the method type
      response = await _sendHttpRequest(
        uri,
        method,
        requestHeaders,
        body: body,
      );

      // Check for 401 Unauthorized
      if (response.statusCode == 401) {
        print("401 Unauthorized detected. Attempting to refresh token...");

        // Attempt to refresh the token
        await _loginService.refreshAccessToken();

        // Get the new token and update the headers
        token = await _loginService.getToken();
        requestHeaders['Authorization'] = 'Bearer $token';

        print("Token refresh successful, retrying request...");

        // Retry the request with the new token
        response = await _sendHttpRequest(
          uri,
          method,
          requestHeaders,
          body: body,
        );

        // If it still fails with 401, throw SessionExpired exception
        if (response.statusCode == 401) {
          print("Retry failed with 401 Unauthorized");
          throw SessionExpiredException();
        }
      }

      return response;
    } catch (e) {
      print("Error in makeRequestWithToken: $e");
      rethrow; // Propagate the exception to the caller
    }
  }

  Future<http.Response> _sendHttpRequest(
    Uri uri,
    String method,
    Map<String, String> headers, {
    dynamic body,
  }) async {
    try {
      print("Sending $method request to $uri");
      print("Headers: $headers");
      if (body != null) {
        print("Body: $body");
      }

      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      print("Received response with status code ${response.statusCode}");
      print("Response body: ${response.body}");

      return response;
    } catch (e) {
      print("HTTP request failed: $e");
      rethrow; // Propagate the exception to be handled in makeRequestWithToken
    }
  }
}
