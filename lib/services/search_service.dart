import 'dart:convert';
import 'package:http/http.dart' as http;
import '***REMOVED***/models/SearchUserModel.dart';

class SearchService {
  static const String baseUrl = 'https://cc2e-185-97-92-77.ngrok-free.app/api/Users/search';

  // Method to fetch search results with pagination from the backend
  Future<List<SearchUserModel>> searchUsers(String query, int pageNumber, int pageSize) async {
    final Uri uri = Uri.parse(baseUrl).replace(queryParameters: {
      'fullname': query,
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
    });

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);

        // Parse the users and return the list of SearchUserModel
        List<SearchUserModel> users = (data['users'] as List<dynamic>)
            .map((userJson) => SearchUserModel.fromJson(userJson as Map<String, dynamic>))
            .toList();

        return users;
      } else {
        throw Exception('Failed to load search results');
      }
    } catch (e) {
      throw Exception('Error occurred during search: $e');
    }
  }
}
