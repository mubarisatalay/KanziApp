import '../../domain/entities/leaderboard_entry.dart';

/// Leaderboard entry model for data layer
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

  /// Create from JSON (Supabase RPC response)
  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? 'Unknown',
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      totalVotes: (json['total_votes'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      submissionCount: (json['submission_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Create from manual aggregation (when RPC is not available)
  factory LeaderboardEntryModel.fromAggregation({
    required String userId,
    required String username,
    String? displayName,
    String? avatarUrl,
    required int totalVotes,
    required int rank,
    int submissionCount = 0,
  }) {
    return LeaderboardEntryModel(
      userId: userId,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      totalVotes: totalVotes,
      rank: rank,
      submissionCount: submissionCount,
    );
  }
}
