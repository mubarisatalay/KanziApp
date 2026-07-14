import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/kor/kor.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../providers/room_provider.dart';
import '../widgets/create_room_dialog.dart';
import '../widgets/join_room_dialog.dart';
import '../widgets/room_card.dart';
import 'room_detail_screen.dart';

/// Home screen showing list of joined rooms — KOR design "2a Home".
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(userRoomsProvider);
    final user = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context);
    final displayName =
        (user?.displayName?.trim().isNotEmpty ?? false)
            ? user!.displayName!.trim()
            : (user?.username ?? '');

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header: wordmark left, current-user monogram right.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  const KorWordmark(size: 24),
                  const Spacer(),
                  PressableScale(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                    child: MonogramAvatar(
                      name: displayName,
                      size: 38,
                      tint: MonogramTint.coral,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: rooms.when(
                data: (roomList) => RefreshIndicator(
                  onRefresh: () async {
                    ref.read(roomActionsProvider).refreshRooms();
                    // Wait for the provider to finish
                    await ref.read(userRoomsProvider.future);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
                    children: [
                      Text(
                        l10n.greeting(displayName),
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 4),
                      if (roomList.isNotEmpty)
                        Text(
                          l10n.roomsWaiting(roomList.length),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      const SizedBox(height: 18),
                      if (roomList.isEmpty)
                        _buildEmptyState(context)
                      else
                        for (final room in roomList)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: RoomCard(
                              room: room,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RoomDetailScreen(roomId: room.id),
                                  ),
                                );
                              },
                            ),
                          ),
                    ],
                  ),
                ),
                loading: () => const RoomListShimmer(),
                error: (error, _) => ErrorStateWidget(
                  message: error.toString(),
                  onRetry: () => ref.read(roomActionsProvider).refreshRooms(),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showRoomActions(context, ref);
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.roomFabLabel),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.noRoomsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noRoomsSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }

  void _showRoomActions(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _SheetAction(
                icon: Icons.add,
                iconColor: AppColors.primaryText,
                title: l10n.createRoomAction,
                subtitle: l10n.createRoomSubtitle,
                onTap: () {
                  Navigator.pop(context);
                  _showCreateRoomDialog(context, ref);
                },
              ),
              const SizedBox(height: 10),
              _SheetAction(
                icon: Icons.login,
                iconColor: AppColors.textSecondary,
                title: l10n.joinRoomAction,
                subtitle: l10n.joinRoomSubtitle,
                onTap: () {
                  Navigator.pop(context);
                  _showJoinRoomDialog(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateRoomDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const CreateRoomDialog(),
    );
  }

  void _showJoinRoomDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const JoinRoomDialog(),
    );
  }
}

/// KOR glass row inside the create/join bottom sheet.
class _SheetAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
