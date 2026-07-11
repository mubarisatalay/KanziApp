import '../../domain/entities/leaderboard_entry.dart';

/// Leaderboard entry model for data layer. Maps the API's LeaderboardEntry (camelCase).
class LeaderboardEntryModel extends LeaderboardEntry {
  const LeaderboardEntryModel({
    required super.userId,
    required super.username,
    super.displayName,
    super.avatarUrl,
    required super.totalVotes,
    required super.rank,
    super.submissionCount,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      userId: json['userId'] as String,
      username: json['username'] as String? ?? 'Unknown',
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      totalVotes: (json['totalVotes'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      submissionCount: (json['submissionCount'] as num?)?.toInt() ?? 0,
    );
  }
}
