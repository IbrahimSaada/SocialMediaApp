class UserModel {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String gender;
  final DateTime dob;
  final String password;

  UserModel({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.gender,
    required this.dob,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email.toLowerCase(),
      'phone_number': phoneNumber, // Ensure the correct field name is used
      'gender': gender,
      'dob': dob.toIso8601String(),
      'password': password,
    };
  }
}
