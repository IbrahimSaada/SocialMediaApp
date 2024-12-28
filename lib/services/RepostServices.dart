import 'package:cook/services/apiService.dart';
import 'package:cook/services/SessionExpiredException.dart';

class RepostService {
  static const String baseUrl =
      'https://bace-185-97-92-44.ngrok-free.app/api';
  
  final ApiService _apiService = ApiService();

  Future<void> createRepost(int userId, int postId, String? comment) async {
    // Prepare data to sign
    String dataToSign = '$userId:$postId:${comment ?? ""}';

    try {
      final response = await _apiService.makeRequestWithToken(
        Uri.parse('$baseUrl/Shares'),
        dataToSign,
        'POST',
        body: {
          'userId': userId,
          'postId': postId,
          'comment': comment ?? '',
        },
      );

      if (response.statusCode == 403) {
        String reason = response.body;
        throw Exception('BLOCKED:$reason');
      }

      if (response.statusCode == 200) {
        print('Repost created successfully');
      } else {
        // If we get here, it means a non-201 (in some endpoints) or non-200
        // status code that wasn't handled by ApiService token refresh logic.
        // 401 after ApiService tries would have thrown SessionExpiredException.
        print('Failed to create repost: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to create repost: ${response.body}');
      }
    } on SessionExpiredException {
      // Propagate session expired exception to the caller (UI)
      rethrow;
    } catch (e) {
      print('Error in createRepost: $e');
      rethrow;
    }
  }
}
