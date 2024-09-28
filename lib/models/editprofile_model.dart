// models/user_profile_model.dart
class EditUserProfile {
  final String? profilePic; // Allow null if not changed
  final String? fullName;   // Allow null if not changed
  final String? bio;        // Allow null if not changed

  EditUserProfile({
    this.profilePic,  // Optional field
    this.fullName,    // Optional field
    this.bio,         // Optional field
  });

  // Factory method to create an instance from JSON
  factory EditUserProfile.fromJson(Map<String, dynamic> json) {
    return EditUserProfile(
      profilePic: json['profile_pic'],
      fullName: json['fullname'],
      bio: json['bio'],
    );
  }

  // Method to convert an instance to JSON (omit null fields)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (profilePic != null) data['profile_pic'] = profilePic;
    if (fullName != null) data['fullname'] = fullName;
    if (bio != null) data['bio'] = bio;
    return data;
  }
}