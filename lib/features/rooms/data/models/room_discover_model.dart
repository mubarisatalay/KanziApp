class RoomDiscoverModel {
  final String id;
  final String name;
  final String? description;
  final int memberCount;
  final bool hasChallengeToday;

  const RoomDiscoverModel({
    required this.id,
    required this.name,
    this.description,
    required this.memberCount,
    required this.hasChallengeToday,
  });

  factory RoomDiscoverModel.fromJson(Map<String, dynamic> json) {
    return RoomDiscoverModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      hasChallengeToday: json['hasChallengeToday'] as bool? ?? false,
    );
  }
}
