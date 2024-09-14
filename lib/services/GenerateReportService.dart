// ignore_for_file: file_names, avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ReportRequest_model.dart';
import 'LoginService.dart';
import 'SignatureService.dart';

class ReportService {
  final String apiUrl = 'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/Reports'; // Replace with your API URL

  // Instantiate the login and signature services
  static final LoginService _loginService = LoginService();
  static final SignatureService _signatureService = SignatureService();

  // Function to create a report with JWT token and HMAC signature
  Future<void> createReport(ReportRequest reportRequest) async {
    try {
      // Ensure the user is logged in and refresh the token if necessary
      if (!await _loginService.isLoggedIn()) {
        throw Exception("User not logged in.");
      }

      // Retrieve the updated JWT token
      String? token = await _loginService.getToken();
      if (token == null) {
        throw Exception("No valid token found.");
      }

      // Generate the HMAC signature using fields from the reportRequest
      String dataToSign =
          'ReportedBy=${reportRequest.reportedBy}&ReportedUser=${reportRequest.reportedUser}&ContentId=${reportRequest.contentId}';

      // Ensure that the signature is Base64-encoded
      String signature = await _signatureService.generateHMAC(dataToSign);

      // Send the POST request to create a report
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',  // JWT token in Authorization header
          'X-Signature': signature,          // Ensure X-Signature header is sent
        },
        body: jsonEncode(reportRequest.toJson()),
      );

      // Check for 401 Unauthorized (token expired)
      if (response.statusCode == 401) {
        print('JWT token is invalid or expired. Attempting to refresh token.');

        // Try to refresh the token
        try {
          await _loginService.refreshAccessToken();  // Refresh the token
          token = await _loginService.getToken();    // Get the new token
          print('Token refreshed successfully.');

          // Regenerate the HMAC signature with the same data
          signature = await _signatureService.generateHMAC(dataToSign);

          // Retry the request with the refreshed token
          final retryResponse = await http.post(
            Uri.parse(apiUrl),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',  // Refreshed JWT token
              'X-Signature': signature,          // Recomputed HMAC signature
            },
            body: jsonEncode(reportRequest.toJson()),
          );

          if (retryResponse.statusCode != 201) {
            throw Exception('Failed to create report after token refresh.');
          } else {
            print('Report created successfully after token refresh.');
          }
        } catch (e) {
          print('Failed to refresh token: $e');
          throw Exception('Failed to refresh token. Please log in again.');
        }
      } else if (response.statusCode != 201) {
        // Handle other errors
        final responseBody = jsonDecode(response.body);
        final errorDetails =
            responseBody['error'] ?? responseBody['message'] ?? 'Unknown error';
        throw Exception('Failed to create report: $errorDetails');
      } else {
        // Report created successfully
        print('Report created: ${response.body}');
      }
    } catch (e) {
      print('Error in createReport: $e');
      rethrow;
    }
  }
}
