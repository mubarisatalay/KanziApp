import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/kor/kor.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/weekly_mvp_model.dart';
import '../providers/leaderboard_provider.dart';

/// Weekly MVP screen — two tabs: room-scoped and global (cross-room normalized).
class MvpScreen extends ConsumerWidget {
  final String roomId;
  final String roomName;

  const MvpScreen({super.key, required this.roomId, required this.roomName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  children: [
                    GlassIconButton(
                      icon: Icons.chevron_left,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.mvpTitle,
                              style: Theme.of(context).textTheme.titleLarge),
                          Text(
                            l10n.mvpWeekLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppColors.textFaint),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Tab bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    labelStyle: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    unselectedLabelStyle:
                        Theme.of(context).textTheme.labelMedium,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: AppColors.onPrimary,
                    unselectedLabelColor: AppColors.textSecondary,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: l10n.mvpTabRoom),
                      Tab(text: l10n.mvpTabGlobal),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    _RoomMvpTab(roomId: roomId, roomName: roomName),
                    _GlobalMvpTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Room tab ──────────────────────────────────────────────────────────────────

class _RoomMvpTab extends ConsumerWidget {
  final String roomId;
  final String roomName;
  const _RoomMvpTab({required this.roomId, required this.roomName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(weeklyRoomMvpProvider(roomId));
    final currentUser = ref.watch(currentUserProvider);

    return entriesAsync.when(
      data: (entries) => entries.isEmpty
          ? _EmptyMvp()
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(weeklyRoomMvpProvider(roomId)),
              child: _MvpList(
                entries: entries,
                currentUserId: currentUser?.id,
                showRoomContext: false,
              ),
            ),
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: LeaderboardShimmer(),
      ),
      error: (e, _) => ErrorStateWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(weeklyRoomMvpProvider(roomId)),
      ),
    );
  }
}

// ── Global tab ────────────────────────────────────────────────────────────────

class _GlobalMvpTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(weeklyGlobalMvpProvider);
    final currentUser = ref.watch(currentUserProvider);

    return entriesAsync.when(
      data: (entries) => entries.isEmpty
          ? _EmptyMvp()
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(weeklyGlobalMvpProvider),
              child: _MvpList(
                entries: entries,
                currentUserId: currentUser?.id,
                showRoomContext: true,
              ),
            ),
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: LeaderboardShimmer(),
      ),
      error: (e, _) => ErrorStateWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(weeklyGlobalMvpProvider),
      ),
    );
  }
}

// ── List + podium ─────────────────────────────────────────────────────────────

class _MvpList extends StatelessWidget {
  final List<WeeklyMvpEntry> entries;
  final String? currentUserId;
  final bool showRoomContext;

  const _MvpList({
    required this.entries,
    required this.currentUserId,
    required this.showRoomContext,
  });

  @override
  Widget build(BuildContext context) {
    final podium = entries.where((e) => e.isOnPodium).toList();
    final rest = entries.where((e) => !e.isOnPodium).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        if (podium.isNotEmpty) ...[
          _MvpPodium(entries: podium, currentUserId: currentUserId),
          const SizedBox(height: 20),
        ],
        for (final entry in rest)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MvpRow(
              entry: entry,
              isCurrentUser: entry.userId == currentUserId,
              showRoomContext: showRoomContext,
            ),
          ),
      ],
    );
  }
}

// ── Podium ────────────────────────────────────────────────────────────────────

class _MvpPodium extends StatelessWidget {
  final List<WeeklyMvpEntry> entries;
  final String? currentUserId;
  const _MvpPodium({required this.entries, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final first = entries.firstWhere((e) => e.rank == 1, orElse: () => entries.first);
    final second = entries.where((e) => e.rank == 2).firstOrNull;
    final third = entries.where((e) => e.rank == 3).firstOrNull;

    return SizedBox(
      height: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null)
            Expanded(child: _PodiumSlab(entry: second, height: 96, isCurrentUser: second.userId == currentUserId))
          else
            const Expanded(child: SizedBox()),
          const SizedBox(width: 8),
          Expanded(child: _PodiumSlab(entry: first, height: 128, isCurrentUser: first.userId == currentUserId, isFirst: true)),
          const SizedBox(width: 8),
          if (third != null)
            Expanded(child: _PodiumSlab(entry: third, height: 72, isCurrentUser: third.userId == currentUserId))
          else
            const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

class _PodiumSlab extends StatelessWidget {
  final WeeklyMvpEntry entry;
  final double height;
  final bool isCurrentUser;
  final bool isFirst;

  const _PodiumSlab({
    required this.entry,
    required this.height,
    required this.isCurrentUser,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = entry.displayName?.trim().isNotEmpty == true
        ? entry.displayName!
        : entry.username;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        MonogramAvatar(
          name: name,
          size: isFirst ? 48 : 38,
          tint: isFirst ? MonogramTint.coral : MonogramTint.neutral,
        ),
        const SizedBox(height: 6),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isCurrentUser ? AppColors.primary : AppColors.primaryText,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          '${entry.score.toStringAsFixed(1)}/10',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: isFirst
                ? AppColors.coralTint
                : AppColors.surfaceVariant,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(
              color: isFirst ? AppColors.coralBorder : AppColors.glassBorder,
            ),
          ),
          child: Center(
            child: Text(
              '#${entry.rank}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isFirst ? AppColors.primary : AppColors.textSecondary,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Row (rank 4+) ─────────────────────────────────────────────────────────────

class _MvpRow extends StatelessWidget {
  final WeeklyMvpEntry entry;
  final bool isCurrentUser;
  final bool showRoomContext;

  const _MvpRow({
    required this.entry,
    required this.isCurrentUser,
    required this.showRoomContext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = entry.displayName?.trim().isNotEmpty == true
        ? entry.displayName!
        : entry.username;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#${entry.rank}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          MonogramAvatar(name: name, size: 36, tint: MonogramTint.neutral),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: isCurrentUser
                                  ? AppColors.primary
                                  : AppColors.primaryText,
                            ),
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.coralTint,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(l10n.mvpYouLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: AppColors.primary, fontSize: 10)),
                      ),
                    ],
                  ],
                ),
                if (showRoomContext && entry.roomContext != null)
                  Text(
                    entry.roomContext!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textTertiary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.score.toStringAsFixed(1)}/10',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                    ),
              ),
              Text(
                l10n.mvpSubmissionsLabel(entry.submissionCount),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textTertiary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyMvp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(l10n.mvpNoData,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(l10n.mvpNoDataSub,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}
