// ignore_for_file: avoid_print, duplicate_ignore

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:cook/models/presigned_url.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cook/services/LoginService.dart'; // Import LoginService
import 'SignatureService.dart'; // Import the SignatureService
import 'package:dio/dio.dart';

class S3UploadService {
  final SignatureService _signatureService = SignatureService();
  final LoginService _loginService = LoginService(); // Initialize LoginService

  // Method to retrieve token, refresh if expired
  Future<String?> _getToken() async {
    DateTime? expiration = await _loginService.getTokenExpiration();
    
    if (expiration == null || DateTime.now().isAfter(expiration)) {
      print('Token expired. Refreshing...');
      await _loginService.refreshAccessToken();
    }
    
    return await _loginService.getToken();
  }

  Future<List<PresignedUrl>> getPresignedUrls(List<String> fileNames,
      {String folderName = 'posts'}) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token not found');
    }

    final String fileNamesString = fileNames.join(',');
    final Map<String, dynamic> payload = {
      'fileNames': fileNamesString,
      'folderName': folderName,
    };

    // Generate data to sign
    final String dataToSign = '$fileNamesString:$folderName';

    // Generate HMAC signature using SignatureService
    final String signature = await _signatureService.generateHMAC(dataToSign);

    // Make the request with the JWT token and HMAC signature
    final response = await http.post(
      Uri.parse(
          'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/media/s3-presigned-upload-urls'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'X-Signature': signature,
      },
      body: jsonEncode(payload),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((json) => PresignedUrl.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get presigned URLs');
    }
  }

  Future<String> uploadFile(PresignedUrl urlData, XFile file, {Function(double)? onProgress}) async {
    final fileType = lookupMimeType(file.path);
    final fileSize = await File(file.path).length();

    Dio dio = Dio();
    try {
      await dio.put(
        urlData.url,
        data: File(file.path).openRead(),
        options: Options(headers: {
          'Content-Type': fileType,
          'Content-Length': fileSize.toString(),
        }),
        onSendProgress: (int sent, int total) {
          double progress = (sent / total) * 100;
          if (onProgress != null) onProgress(progress);
        },
      );
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }

    print('File uploaded successfully');

    final objectKey = Uri.parse(urlData.url).path.replaceFirst('/', '');

    final objectUrl =
        'https://homepagecooking.s3.eu-central-1.amazonaws.com/$objectKey';

    return objectUrl;
  }
}
