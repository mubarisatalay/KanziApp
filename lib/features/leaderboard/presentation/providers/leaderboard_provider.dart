import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../data/models/leaderboard_entry_model.dart';
import '../../data/repositories/leaderboard_repository.dart';

/// Provider for leaderboard repository
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return LeaderboardRepositoryImpl(client);
});

/// Provider for today's leaderboard for a room
final dailyLeaderboardProvider = FutureProvider.family<
    List<LeaderboardEntryModel>, ({String roomId, DateTime date})>(
  (ref, params) async {
    final repository = ref.watch(leaderboardRepositoryProvider);
    return repository.getDailyLeaderboard(
      roomId: params.roomId,
      date: params.date,
    );
  },
);

/// Provider for overall leaderboard for a room
final overallLeaderboardProvider =
    FutureProvider.family<List<LeaderboardEntryModel>, String>(
  (ref, roomId) async {
    final repository = ref.watch(leaderboardRepositoryProvider);
    return repository.getOverallLeaderboard(roomId);
  },
);

/// Currently selected leaderboard tab (0 = Today, 1 = All-time)
final leaderboardTabProvider = StateProvider<int>((ref) => 0);
