import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cook/models/SearchUserModel.dart';

class SearchService {
  static const String baseUrl = 'http://development.eba-pue89yyk.eu-central-1.elasticbeanstalk.com/api/Users/search';

  // Method to fetch search results with pagination and currentUserId from the backend
  Future<List<SearchUserModel>> searchUsers(String query, int currentUserId, int pageNumber, int pageSize) async {
    final Uri uri = Uri.parse(baseUrl).replace(queryParameters: {
      'fullname': query,
      'currentUserId': currentUserId.toString(), // Add currentUserId as part of the query
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
