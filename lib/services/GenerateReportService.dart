// ignore_for_file: file_names, avoid_print

import 'dart:convert';
import 'package:cook/models/ReportRequest_model.dart';
import 'package:cook/services/apiService.dart';
import 'package:cook/services/SessionExpiredException.dart';

class ReportService {
  final String apiUrl = 'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/Reports'; 
  
  final ApiService _apiService = ApiService();

  Future<void> createReport(ReportRequest reportRequest) async {
    // Prepare the signature data
    // Using the same format as originally: 'ReportedBy={x}&ReportedUser={y}&ContentId={z}'
    final String signatureData =
        'ReportedBy=${reportRequest.reportedBy}&ReportedUser=${reportRequest.reportedUser}&ContentId=${reportRequest.contentId}';

    try {
      // Make the POST request using ApiService
      final response = await _apiService.makeRequestWithToken(
        Uri.parse(apiUrl),
        signatureData,
        'POST',
        body: reportRequest.toJson(),
      );

      if (response.statusCode == 403) {
        // BLOCKED scenario
        final reason = response.body;
        throw Exception('BLOCKED:$reason');
      }

      if (response.statusCode == 201) {
        print('Report created: ${response.body}');
      } else {
        // Handle errors other than 201 (Created)
        final responseBody = jsonDecode(response.body);
        final errorDetails = responseBody['error'] ?? responseBody['message'] ?? 'Unknown error';
        throw Exception('Failed to create report: $errorDetails');
      }
    } on SessionExpiredException {
      // If session is expired, rethrow to let the UI handle it
      rethrow;
    } catch (e) {
      print('Error in createReport: $e');
      rethrow;
    }
  }
}
