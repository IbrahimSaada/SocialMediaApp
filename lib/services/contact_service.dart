import 'dart:convert';
import '***REMOVED***/models/usercontact_model.dart';
import '***REMOVED***/services/apiService.dart';

class ContactService {
  final String baseUrl = 'https://bace-185-97-92-44.ngrok-free.app/api/Chat'; 
  final ApiService _apiService = ApiService();

  // Fetch contacts with pagination and optional search
  Future<List<UserContact>> fetchContacts(
    int userId, {
    String search = '',
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/$userId/contacts').replace(
      queryParameters: {
        if (search.isNotEmpty) 'search': search,
        'pageNumber': pageNumber.toString(),
        'pageSize': pageSize.toString(),
      },
    );

    // dataToSign = "userId:search:pageNumber:pageSize"
    String dataToSign = "$userId:$search:$pageNumber:$pageSize";

    final response = await _apiService.makeRequestWithToken(
      uri,
      dataToSign,
      'GET',
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      List<dynamic> contactsJson = data['contacts'];
      return contactsJson
          .map((json) => UserContact.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load contacts: ${response.body}');
    }
  }
}