import '../../domain/entities/room.dart';

/// Room model for data layer. Maps the API's RoomResponse (camelCase, flat).
class RoomModel extends Room {
  const RoomModel({
    required super.id,
    required super.name,
    super.description,
    required super.code,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    super.memberCount,
    super.currentUserRole,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      code: json['code'] as String,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      currentUserRole: json['currentUserRole'] as String?,
    );
  }

  Room toEntity() => Room(
        id: id,
        name: name,
        description: description,
        code: code,
        createdBy: createdBy,
        createdAt: createdAt,
        updatedAt: updatedAt,
        memberCount: memberCount,
        currentUserRole: currentUserRole,
      );
}
