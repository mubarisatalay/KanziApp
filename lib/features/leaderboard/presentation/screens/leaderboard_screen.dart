import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../providers/leaderboard_provider.dart';

/// Leaderboard screen showing rankings for a room
class LeaderboardScreen extends ConsumerWidget {
  final String roomId;
  final String roomName;

  const LeaderboardScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(leaderboardTabProvider);

    return DefaultTabController(
      length: 2,
      initialIndex: selectedTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text('$roomName - Leaderboard'),
          bottom: TabBar(
            onTap: (index) {
              ref.read(leaderboardTabProvider.notifier).state = index;
            },
            tabs: const [
              Tab(text: 'Today'),
              Tab(text: 'All-Time'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DailyLeaderboardTab(roomId: roomId),
            _OverallLeaderboardTab(roomId: roomId),
          ],
        ),
      ),
    );
  }
}

/// Today's leaderboard tab
class _DailyLeaderboardTab extends ConsumerWidget {
  final String roomId;

  const _DailyLeaderboardTab({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (roomId: roomId, date: DateTime.now());
    final leaderboardAsync = ref.watch(dailyLeaderboardProvider(params));
    final currentUser = ref.watch(currentUserProvider);

    return leaderboardAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return _buildEmptyState(context, "No submissions today yet");
        }
        return _LeaderboardContent(
          entries: entries,
          currentUserId: currentUser?.id ?? '',
          onRefresh: () async {
            ref.invalidate(dailyLeaderboardProvider(params));
            await ref.read(dailyLeaderboardProvider(params).future);
          },
        );
      },
      loading: () => const LeaderboardShimmer(),
      error: (error, _) => ErrorStateWidget(
        message: error.toString(),
        onRetry: () => ref.invalidate(dailyLeaderboardProvider(params)),
      ),
    );
  }
}

/// All-time leaderboard tab
class _OverallLeaderboardTab extends ConsumerWidget {
  final String roomId;

  const _OverallLeaderboardTab({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(overallLeaderboardProvider(roomId));
    final currentUser = ref.watch(currentUserProvider);

    return leaderboardAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return _buildEmptyState(context, "No data yet");
        }
        return _LeaderboardContent(
          entries: entries,
          currentUserId: currentUser?.id ?? '',
          onRefresh: () async {
            ref.invalidate(overallLeaderboardProvider(roomId));
            await ref.read(overallLeaderboardProvider(roomId).future);
          },
        );
      },
      loading: () => const LeaderboardShimmer(),
      error: (error, _) => ErrorStateWidget(
        message: error.toString(),
        onRetry: () => ref.invalidate(overallLeaderboardProvider(roomId)),
      ),
    );
  }
}

Widget _buildEmptyState(BuildContext context, String message) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_outlined,
              size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Submit responses and vote to see rankings!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

/// Content widget showing podium + ranking list
class _LeaderboardContent extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String currentUserId;
  final Future<void> Function() onRefresh;

  const _LeaderboardContent({
    required this.entries,
    required this.currentUserId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final podiumEntries = entries.where((e) => e.isOnPodium).toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Podium section
            if (podiumEntries.isNotEmpty)
              _PodiumWidget(
                entries: podiumEntries,
                currentUserId: currentUserId,
              ),

            const SizedBox(height: 16),

            // Full ranking list
            ...entries.map(
              (entry) => _RankingTile(
                entry: entry,
                isCurrentUser: entry.userId == currentUserId,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Podium visualization with 1st, 2nd, 3rd place
class _PodiumWidget extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String currentUserId;

  const _PodiumWidget({
    required this.entries,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final first = entries.where((e) => e.rank == 1).firstOrNull;
    final second = entries.where((e) => e.rank == 2).firstOrNull;
    final third = entries.where((e) => e.rank == 3).firstOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place (left)
          if (second != null)
            _PodiumItem(
              entry: second,
              height: 100,
              color: const Color(0xFFC0C0C0), // Silver
              isCurrentUser: second.userId == currentUserId,
            )
          else
            const SizedBox(width: 100),

          const SizedBox(width: 8),

          // 1st place (center, tallest)
          if (first != null)
            _PodiumItem(
              entry: first,
              height: 140,
              color: const Color(0xFFFFD700), // Gold
              isCurrentUser: first.userId == currentUserId,
            )
          else
            const SizedBox(width: 100),

          const SizedBox(width: 8),

          // 3rd place (right)
          if (third != null)
            _PodiumItem(
              entry: third,
              height: 70,
              color: const Color(0xFFCD7F32), // Bronze
              isCurrentUser: third.userId == currentUserId,
            )
          else
            const SizedBox(width: 100),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final double height;
  final Color color;
  final bool isCurrentUser;

  const _PodiumItem({
    required this.entry,
    required this.height,
    required this.color,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              CircleAvatar(
                radius: entry.rank == 1 ? 32 : 24,
                backgroundColor: color.withAlpha(50),
                child: Text(
                  (entry.username)[0].toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: entry.rank == 1 ? 24 : 18,
                    color: color,
                  ),
                ),
              ),
              if (entry.rank == 1)
                const Positioned(
                  top: -4,
                  child: Text('👑', style: TextStyle(fontSize: 20)),
                ),
            ],
          ),
          const SizedBox(height: 4),

          // Username
          Text(
            entry.displayName ?? entry.username,
            style: TextStyle(
              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
              fontSize: 12,
              color: isCurrentUser ? AppColors.primary : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Votes
          Text(
            '${entry.totalVotes} votes',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
          ),
          const SizedBox(height: 4),

          // Pedestal
          Container(
            width: 100,
            height: height,
            decoration: BoxDecoration(
              color: color.withAlpha(40),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              border: Border.all(color: color.withAlpha(100)),
            ),
            child: Center(
              child: Text(
                _ordinalSuffix(entry.rank),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: entry.rank == 1 ? 28 : 22,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _ordinalSuffix(int rank) {
    switch (rank) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      default:
        return '${rank}th';
    }
  }
}

/// Single ranking row
class _RankingTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const _RankingTile({
    required this.entry,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      color: isCurrentUser ? AppColors.primary.withAlpha(15) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 36,
              child: _buildRank(entry.rank),
            ),
            const SizedBox(width: 12),

            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: entry.isOnPodium
                  ? _podiumColor(entry.rank).withAlpha(30)
                  : AppColors.surfaceVariant,
              child: Text(
                (entry.username)[0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: entry.isOnPodium
                      ? _podiumColor(entry.rank)
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.displayName ?? entry.username,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: isCurrentUser
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isCurrentUser ? AppColors.primary : null,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '${entry.submissionCount} submission${entry.submissionCount == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                  ),
                ],
              ),
            ),

            // Votes
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: entry.isOnPodium
                          ? AppColors.winner
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${entry.totalVotes}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: entry.isOnPodium ? AppColors.winner : null,
                          ),
                    ),
                  ],
                ),
                Text(
                  'votes',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRank(int rank) {
    if (rank <= 3) {
      return Text(
        _medal(rank),
        style: const TextStyle(fontSize: 22),
        textAlign: TextAlign.center,
      );
    }
    return Text(
      '#$rank',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
      textAlign: TextAlign.center,
    );
  }

  String _medal(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  Color _podiumColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.textSecondary;
    }
  }
}
