// services/contact_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cook/models/usercontact_model.dart';

class ContactService {
  final String baseUrl = 'https://fe3c-185-97-92-121.ngrok-free.app/api/Chat';

  // Fetch contacts with pagination and optional search
  Future<List<UserContact>> fetchContacts(
    int userId, {
    String search = '',
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final Uri url = Uri.parse('$baseUrl/$userId/contacts').replace(
      queryParameters: {
        if (search.isNotEmpty) 'search': search,
        'pageNumber': pageNumber.toString(),
        'pageSize': pageSize.toString(),
      },
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> contactsJson = data['contacts'];

        return contactsJson
            .map((json) => UserContact.fromJson(json))
            .toList();
      } else {
        throw Exception(
            'Failed to load contacts. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchContacts: $e');
      throw Exception('Error fetching contacts: $e');
    }
  }
}
