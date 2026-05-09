/// Room entity
class Room {
  final String id;
  final String name;
  final String? description;
  final String code;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Additional fields populated from joins
  final int memberCount;
  final String? currentUserRole; // 'admin' or 'member'

  const Room({
    required this.id,
    required this.name,
    this.description,
    required this.code,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.memberCount = 0,
    this.currentUserRole,
  });

  bool get isAdmin => currentUserRole == 'admin';

  Room copyWith({
    String? id,
    String? name,
    String? description,
    String? code,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? memberCount,
    String? currentUserRole,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      code: code ?? this.code,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memberCount: memberCount ?? this.memberCount,
      currentUserRole: currentUserRole ?? this.currentUserRole,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Room && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Room(id: $id, name: $name, code: $code, memberCount: $memberCount)';
  }
}
