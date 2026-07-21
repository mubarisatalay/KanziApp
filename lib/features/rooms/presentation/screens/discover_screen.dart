import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/kor/kor.dart';
import '../../data/models/room_discover_model.dart';
import '../providers/room_provider.dart';
import '../widgets/join_room_dialog.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(discoverRoomsProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  GlassIconButton(
                    icon: Icons.chevron_left,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.discoverTitle,
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(l10n.discoverSubtitle,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.textFaint)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: roomsAsync.when(
                data: (rooms) => rooms.isEmpty
                    ? _EmptyDiscover()
                    : RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(discoverRoomsProvider),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                          itemCount: rooms.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) =>
                              _DiscoverCard(room: rooms[i]),
                        ),
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: RoomListShimmer(),
                ),
                error: (e, _) => ErrorStateWidget(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(discoverRoomsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDiscover extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore_off_outlined,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(l10n.discoverEmpty,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(l10n.discoverEmptySubtitle,
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

class _DiscoverCard extends StatelessWidget {
  final RoomDiscoverModel room;

  const _DiscoverCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (room.description != null &&
                        room.description!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        room.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.lock_outline,
                  size: 18, color: AppColors.textTertiary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.people_outline,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 5),
              Text(
                l10n.membersCount(room.memberCount),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
              if (room.hasChallengeToday) ...[
                const SizedBox(width: 12),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  l10n.challengeToday,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
              const Spacer(),
              CoralButton.inline(
                label: l10n.joinWithCode,
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const JoinRoomDialog(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
