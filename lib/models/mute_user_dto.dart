// models/mute_user_dto.dart
class MuteUserDto {
  final int mutedByUserId;
  final int mutedUserId;

  MuteUserDto({
    required this.mutedByUserId,
    required this.mutedUserId,
  });

  Map<String, dynamic> toJson() {
    return {
      'mutedByUserId': mutedByUserId,
      'mutedUserId': mutedUserId,
    };
  }
}
