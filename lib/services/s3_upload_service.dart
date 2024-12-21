// ignore_for_file: avoid_print, duplicate_ignore

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import '***REMOVED***/models/presigned_url.dart';
import 'package:image_picker/image_picker.dart';
import '***REMOVED***/services/apiService.dart'; // Import the ApiService

class S3UploadService {
  final ApiService _apiService = ApiService();

  Future<List<PresignedUrl>> getPresignedUrls(
    List<String> fileNames, {
    String folderName = 'posts',
  }) async {
    // Join the file names into a single string separated by commas
    final String fileNamesString = fileNames.join(',');

    final Map<String, dynamic> payload = {
      'fileNames': fileNamesString,
      'folderName': folderName,
    };

    // Signature data
    final String signatureData = '$fileNamesString:$folderName';

    // Make the request with ApiService, which handles auth & signature
    final response = await _apiService.makeRequestWithToken(
      Uri.parse(
        '***REMOVED***/api/media/s3-presigned-upload-urls',
      ),
      signatureData,
      'POST',
      body: payload,
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

  Future<String> uploadFile(PresignedUrl urlData, XFile file) async {
    final fileLength = await File(file.path).length();
    final fileType = lookupMimeType(file.path);

    final request = http.Request('PUT', Uri.parse(urlData.url));
    request.headers.addAll({
      'Content-Length': fileLength.toString(),
      'Content-Type': fileType!,
    });
    request.bodyBytes = await File(file.path).readAsBytes();

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Failed to upload file: ${response.statusCode}');
    }

    print('File uploaded successfully');

    final objectKey = Uri.parse(urlData.url).path.replaceFirst('/', '');
    final objectUrl =
        '***REMOVED***/$objectKey';

    return objectUrl;
  }
}
