class UserModel {
  final String fullName;
  final String email;
  final String gender;
  final DateTime dob;
  final String password;

  UserModel({
    required this.fullName,
    required this.email,

    required this.gender,
    required this.dob,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email.toLowerCase(),
      'gender': gender,
      'dob': dob.toIso8601String(),
      'password': password,
    };
  }
}
