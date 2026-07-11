import '../../domain/entities/room_member.dart';

/// Room member model for data layer. Maps the API's RoomMemberResponse (camelCase, flat).
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

  factory RoomMemberModel.fromJson(Map<String, dynamic> json) {
    return RoomMemberModel(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      userId: json['userId'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  RoomMember toEntity() => RoomMember(
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
