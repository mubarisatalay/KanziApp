import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/kor/kor.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../providers/leaderboard_provider.dart';

/// Leaderboard — KOR design "2a Leaderboard": segmented control, podium slabs,
/// coral-highlighted own row. No emoji medals, no crown.
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GlassIconButton(
                        icon: Icons.chevron_left,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.scoreboardTitle,
                                style:
                                    Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 2),
                            Text(
                              roomName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textTertiary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedTabs(
                    labels: [l10n.tabToday, l10n.tabAllTime],
                    selectedIndex: selectedTab,
                    onChanged: (index) => ref
                        .read(leaderboardTabProvider.notifier)
                        .state = index,
                  ),
                ],
              ),
            ),
            Expanded(
              child: selectedTab == 0
                  ? _DailyLeaderboardTab(roomId: roomId)
                  : _OverallLeaderboardTab(roomId: roomId),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyLeaderboardTab extends ConsumerWidget {
  final String roomId;

  const _DailyLeaderboardTab({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Day-truncated so the family key is stable across rebuilds — a raw
    // DateTime.now() key creates a new provider (and a new request) per build.
    final now = DateTime.now();
    final params = (roomId: roomId, date: DateTime(now.year, now.month, now.day));
    final leaderboardAsync = ref.watch(dailyLeaderboardProvider(params));
    final currentUser = ref.watch(currentUserProvider);

    return leaderboardAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return _EmptyBoard(
              message: AppLocalizations.of(context).noSubmissionsToday);
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
          return _EmptyBoard(
              message: AppLocalizations.of(context).noVotesYetBoard);
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

class _EmptyBoard extends StatelessWidget {
  final String message;

  const _EmptyBoard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).boardEmptyHint,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Podium (top three by list order — handles rank ties gracefully) + rows.
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
    final podium = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          children: [
            _Podium(entries: podium),
            const SizedBox(height: 20),
            for (final entry in rest) ...[
              _RankingRow(
                entry: entry,
                isCurrentUser: entry.userId == currentUserId,
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom-aligned 2-1-3 podium: glass slabs, amber center, bronze right.
class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;

  const _Podium({required this.entries});

  @override
  Widget build(BuildContext context) {
    final first = entries.isNotEmpty ? entries[0] : null;
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: second != null
              ? _PodiumColumn(entry: second, place: 2)
              : const SizedBox(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: first != null
              ? _PodiumColumn(entry: first, place: 1)
              : const SizedBox(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: third != null
              ? _PodiumColumn(entry: third, place: 3)
              : const SizedBox(),
        ),
      ],
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final LeaderboardEntry entry;
  final int place; // 1 = center

  const _PodiumColumn({required this.entry, required this.place});

  double get _slabHeight => switch (place) { 1 => 112, 2 => 80, _ => 58 };
  double get _avatarSize => place == 1 ? 60 : 50;

  Color get _slabFill => switch (place) {
        1 => AppColors.amberTint,
        2 => AppColors.surfaceGlass,
        _ => const Color(0x1AD89A72),
      };

  Color get _slabBorder => switch (place) {
        1 => AppColors.amberBorder,
        2 => AppColors.glassBorder,
        _ => const Color(0x40D89A72),
      };

  Color get _digitColor => switch (place) {
        1 => AppColors.accent,
        2 => AppColors.silver,
        _ => AppColors.bronze,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MonogramAvatar(
          name: entry.displayName ?? entry.username,
          size: _avatarSize,
          tint: place == 1 ? MonogramTint.amber : MonogramTint.neutral,
          ringColor: place == 1 ? AppColors.amberBorder : null,
        ),
        const SizedBox(height: 8),
        Text(
          entry.displayName ?? entry.username,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: _slabHeight,
          decoration: BoxDecoration(
            color: _slabFill,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border.all(color: _slabBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${entry.rank}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: place == 1 ? 26 : 22,
                      color: _digitColor,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(context).votesShort(entry.totalVotes),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Ranks 4+: glass row; the caller's row gets the coral treatment + SEN pill.
class _RankingRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const _RankingRow({
    required this.entry,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.coralTint : AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser ? AppColors.coralBorder : AppColors.glassBorder,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${entry.rank}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                  ),
            ),
          ),
          MonogramAvatar(
            name: entry.displayName ?? entry.username,
            size: 32,
            tint: MonogramTint
                .values[entry.username.hashCode.abs() % MonogramTint.values.length],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    entry.displayName ?? entry.username,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      AppLocalizations.of(context).youPillUpper,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${entry.totalVotes}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color:
                      isCurrentUser ? AppColors.accent : AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}
