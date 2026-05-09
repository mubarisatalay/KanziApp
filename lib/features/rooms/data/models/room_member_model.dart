import '../../domain/entities/room_member.dart';

/// Room member model for data layer
class RoomMemberModel extends RoomMember {
  const RoomMemberModel({
    required super.id,
    required super.roomId,
    required super.userId,
    required super.role,
    required super.joinedAt,
    super.username,
    super.displayName,
    super.avatarUrl,
  });

  /// Create from JSON (Supabase response with joined profile data)
  factory RoomMemberModel.fromJson(Map<String, dynamic> json) {
    // Profile data may be nested under 'profiles' key from a join
    final profile = json['profiles'] as Map<String, dynamic>?;

    return RoomMemberModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      username: profile?['username'] as String?,
      displayName: profile?['display_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }

  /// Convert to entity
  RoomMember toEntity() {
    return RoomMember(
      id: id,
      roomId: roomId,
      userId: userId,
      role: role,
      joinedAt: joinedAt,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }
}
