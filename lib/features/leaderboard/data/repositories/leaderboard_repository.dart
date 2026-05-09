import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/leaderboard_entry_model.dart';

/// Leaderboard repository exception
class LeaderboardRepositoryException implements Exception {
  final String message;
  LeaderboardRepositoryException(this.message);

  @override
  String toString() => message;
}

/// Leaderboard repository interface
abstract class LeaderboardRepository {
  /// Get daily leaderboard for a room on a specific date
  Future<List<LeaderboardEntryModel>> getDailyLeaderboard({
    required String roomId,
    required DateTime date,
  });

  /// Get overall (all-time) leaderboard for a room
  Future<List<LeaderboardEntryModel>> getOverallLeaderboard(String roomId);
}

/// Leaderboard repository implementation
class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final SupabaseClient _client;

  LeaderboardRepositoryImpl(this._client);

  @override
  Future<List<LeaderboardEntryModel>> getDailyLeaderboard({
    required String roomId,
    required DateTime date,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      // Try using the RPC function first
      try {
        final response = await _client.rpc(
          'get_daily_leaderboard',
          params: {
            'p_room_id': roomId,
            'p_date': dateStr,
          },
        );

        if (response is List) {
          return response
              .map((json) => LeaderboardEntryModel.fromJson(
                    json as Map<String, dynamic>,
                  ))
              .toList();
        }
      } on PostgrestException {
        // RPC not available, fall through to manual query
      }

      // Fallback: manual aggregation query
      return _getDailyLeaderboardManual(roomId, dateStr);
    } on PostgrestException catch (e) {
      throw LeaderboardRepositoryException(
        'Failed to load leaderboard: ${e.message}',
      );
    } catch (e) {
      if (e is LeaderboardRepositoryException) rethrow;
      throw LeaderboardRepositoryException('An unexpected error occurred: $e');
    }
  }

  Future<List<LeaderboardEntryModel>> _getDailyLeaderboardManual(
    String roomId,
    String dateStr,
  ) async {
    // Get the challenge for this date first
    final challengeResponse = await _client
        .from('challenges')
        .select('id')
        .eq('room_id', roomId)
        .eq('challenge_date', dateStr)
        .maybeSingle();

    if (challengeResponse == null) return [];

    final challengeId = challengeResponse['id'] as String;

    final submissionsResponse = await _client
        .from('submissions')
        .select(
          'user_id, profiles(username, display_name, avatar_url), votes(vote_value)',
        )
        .eq('challenge_id', challengeId);

    // Aggregate votes per user
    final userVotes = <String, _UserVoteData>{};

    for (final sub in submissionsResponse as List) {
      final userId = sub['user_id'] as String;
      final profile = sub['profiles'] as Map<String, dynamic>?;
      final votes = sub['votes'] as List? ?? [];

      final totalVotes = votes.fold<int>(
          0, (sum, v) => sum + ((v['vote_value'] as int?) ?? 0));

      userVotes.putIfAbsent(
        userId,
        () => _UserVoteData(
          userId: userId,
          username: profile?['username'] as String? ?? 'Unknown',
          displayName: profile?['display_name'] as String?,
          avatarUrl: profile?['avatar_url'] as String?,
        ),
      );
      userVotes[userId]!.totalVotes += totalVotes;
      userVotes[userId]!.submissionCount += 1;
    }

    // Sort and rank
    final sorted = userVotes.values.toList()
      ..sort((a, b) => b.totalVotes.compareTo(a.totalVotes));

    final entries = <LeaderboardEntryModel>[];
    int rank = 0;
    int previousVotes = -1;

    for (int i = 0; i < sorted.length; i++) {
      final data = sorted[i];
      if (data.totalVotes != previousVotes) {
        rank = i + 1;
        previousVotes = data.totalVotes;
      }
      entries.add(LeaderboardEntryModel.fromAggregation(
        userId: data.userId,
        username: data.username,
        displayName: data.displayName,
        avatarUrl: data.avatarUrl,
        totalVotes: data.totalVotes,
        rank: rank,
        submissionCount: data.submissionCount,
      ));
    }

    return entries;
  }

  @override
  Future<List<LeaderboardEntryModel>> getOverallLeaderboard(
      String roomId) async {
    try {
      // Get all submissions for this room with votes
      final submissionsResponse = await _client
          .from('submissions')
          .select(
            'user_id, profiles(username, display_name, avatar_url), votes(vote_value)',
          )
          .eq('room_id', roomId);

      // Aggregate votes per user across all challenges
      final userVotes = <String, _UserVoteData>{};

      for (final sub in submissionsResponse as List) {
        final userId = sub['user_id'] as String;
        final profile = sub['profiles'] as Map<String, dynamic>?;
        final votes = sub['votes'] as List? ?? [];

        final totalVotes = votes.fold<int>(
            0, (sum, v) => sum + ((v['vote_value'] as int?) ?? 0));

        userVotes.putIfAbsent(
          userId,
          () => _UserVoteData(
            userId: userId,
            username: profile?['username'] as String? ?? 'Unknown',
            displayName: profile?['display_name'] as String?,
            avatarUrl: profile?['avatar_url'] as String?,
          ),
        );
        userVotes[userId]!.totalVotes += totalVotes;
        userVotes[userId]!.submissionCount += 1;
      }

      // Sort and rank
      final sorted = userVotes.values.toList()
        ..sort((a, b) => b.totalVotes.compareTo(a.totalVotes));

      final entries = <LeaderboardEntryModel>[];
      int rank = 0;
      int previousVotes = -1;

      for (int i = 0; i < sorted.length; i++) {
        final data = sorted[i];
        if (data.totalVotes != previousVotes) {
          rank = i + 1;
          previousVotes = data.totalVotes;
        }
        entries.add(LeaderboardEntryModel.fromAggregation(
          userId: data.userId,
          username: data.username,
          displayName: data.displayName,
          avatarUrl: data.avatarUrl,
          totalVotes: data.totalVotes,
          rank: rank,
          submissionCount: data.submissionCount,
        ));
      }

      return entries;
    } on PostgrestException catch (e) {
      throw LeaderboardRepositoryException(
        'Failed to load leaderboard: ${e.message}',
      );
    } catch (e) {
      if (e is LeaderboardRepositoryException) rethrow;
      throw LeaderboardRepositoryException('An unexpected error occurred: $e');
    }
  }
}

/// Helper class for aggregating vote data
class _UserVoteData {
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  int totalVotes = 0;
  int submissionCount = 0;

  _UserVoteData({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });
}
