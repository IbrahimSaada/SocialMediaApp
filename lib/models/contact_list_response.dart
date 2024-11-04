// models/contact_list_response.dart

import 'usercontact_model.dart';

class ContactListResponse {
  final int totalRecords;
  final int pageNumber;
  final int pageSize;
  final List<UserContact> contacts;

  ContactListResponse({
    required this.totalRecords,
    required this.pageNumber,
    required this.pageSize,
    required this.contacts,
  });

  factory ContactListResponse.fromJson(Map<String, dynamic> json) {
    return ContactListResponse(
      totalRecords: json['totalRecords'],
      pageNumber: json['pageNumber'],
      pageSize: json['pageSize'],
      contacts: (json['contacts'] as List<dynamic>)
          .map((contactJson) => UserContact.fromJson(contactJson))
          .toList(),
    );
  }
}
