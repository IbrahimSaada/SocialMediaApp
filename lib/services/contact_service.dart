// contact_service.dart

import 'dart:convert';
import 'package:cook/models/usercontact_model.dart';
import 'package:cook/services/apiService.dart';
import 'package:cook/services/SessionExpiredException.dart';

class ContactService {
  final String baseUrl =
      'https://a291-185-97-92-44.ngrok-free.app/api/Chat';
  final ApiService _apiService = ApiService();

  Future<List<UserContact>> fetchContacts(
    int userId, {
    String search = '',
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    // Build the query
    final uri = Uri.parse('$baseUrl/$userId/contacts').replace(
      queryParameters: {
        if (search.isNotEmpty) 'search': search,
        'pageNumber': pageNumber.toString(),
        'pageSize': pageSize.toString(),
      },
    );

    final String dataToSign = '$userId:$search:$pageNumber:$pageSize';

    try {
      final response = await _apiService.makeRequestWithToken(
        uri,
        dataToSign,
        'GET',
      );

      if (response.statusCode == 403) {
        throw Exception('BLOCKED:${response.body}');
      } else if (response.statusCode == 401) {
        throw Exception('Session expired or refresh token invalid.');
      } else if (response.statusCode != 200) {
        throw Exception(
          'Failed to load contacts => '
          '${response.statusCode} => ${response.body}',
        );
      }

      // Response example: { contacts: [...] }
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> contactsJson = data['contacts'];
      return contactsJson
          .map((json) => UserContact.fromJson(json))
          .toList();
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      print('Error in fetchContacts => $e');
      rethrow;
    }
  }
}
