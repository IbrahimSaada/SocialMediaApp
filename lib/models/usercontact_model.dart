// models/user_contact.dart

class UserContact {
  final int userId;
  final String fullname;
  final String profilePicUrl;

  UserContact({
    required this.userId,
    required this.fullname,
    required this.profilePicUrl,
  });

  factory UserContact.fromJson(Map<String, dynamic> json) {
    return UserContact(
      userId: json['userId'],
      fullname: json['fullname'],
      profilePicUrl: json['profilePicUrl'],
    );
  }
}