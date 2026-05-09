import '../../domain/entities/room.dart';

/// Room model for data layer
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

  /// Create from JSON (Supabase response)
  factory RoomModel.fromJson(Map<String, dynamic> json,
      {String? currentUserId}) {
    // Member count from aggregated data
    int memberCount = 0;
    if (json['room_members'] is List) {
      memberCount = (json['room_members'] as List).length;
    } else if (json['member_count'] != null) {
      memberCount = json['member_count'] as int;
    }

    // Current user's role
    String? currentUserRole;
    if (currentUserId != null && json['room_members'] is List) {
      final members = json['room_members'] as List;
      for (final member in members) {
        if (member['user_id'] == currentUserId) {
          currentUserRole = member['role'] as String?;
          break;
        }
      }
    } else if (json['current_user_role'] != null) {
      currentUserRole = json['current_user_role'] as String?;
    }

    return RoomModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      code: json['code'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      memberCount: memberCount,
      currentUserRole: currentUserRole,
    );
  }

  /// Convert to JSON for insert/update
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'code': code,
      'created_by': createdBy,
    };
  }

  /// Convert to entity
  Room toEntity() {
    return Room(
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
}
