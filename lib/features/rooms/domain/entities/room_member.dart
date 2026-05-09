/// Room member entity
class RoomMember {
  final String id;
  final String roomId;
  final String userId;
  final String role; // 'admin' or 'member'
  final DateTime joinedAt;

  /// Populated from join with profiles
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  const RoomMember({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  bool get isAdmin => role == 'admin';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoomMember && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RoomMember(userId: $userId, role: $role, username: $username)';
  }
}
