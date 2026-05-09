import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../challenges/presentation/providers/challenge_provider.dart';
import '../../../challenges/presentation/screens/challenge_detail_screen.dart';
import '../../../challenges/presentation/screens/challenge_history_screen.dart';
import '../../../challenges/presentation/widgets/create_challenge_dialog.dart';
import '../../../challenges/presentation/widgets/submit_response_sheet.dart';
import '../../../leaderboard/presentation/screens/leaderboard_screen.dart';
import '../providers/room_provider.dart';

/// Room detail screen showing room info, members, and challenges
class RoomDetailScreen extends ConsumerWidget {
  final String roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomByIdProvider(roomId));
    final membersAsync = ref.watch(roomMembersProvider(roomId));

    return roomAsync.when(
      data: (room) => Scaffold(
        appBar: AppBar(
          title: Text(room.name),
          actions: [
            // Share code button
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share room code',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: room.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Room code "${room.code}" copied!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
            // More options
            if (room.isAdmin)
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleMenuAction(context, ref, value, room.id, room.name),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit Room'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading:
                          Icon(Icons.delete_outline, color: AppColors.error),
                      title: Text('Delete Room',
                          style: TextStyle(color: AppColors.error)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              )
            else
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleMenuAction(context, ref, value, room.id, room.name),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'leave',
                    child: ListTile(
                      leading: Icon(Icons.exit_to_app, color: AppColors.error),
                      title: Text('Leave Room',
                          style: TextStyle(color: AppColors.error)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Room code
                      Row(
                        children: [
                          const Icon(Icons.tag,
                              size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'Invite Code',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.primary.withAlpha(50)),
                            ),
                            child: Text(
                              room.code,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                letterSpacing: 6,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: room.code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Code copied!')),
                              );
                            },
                            icon: const Icon(Icons.copy),
                            tooltip: 'Copy code',
                          ),
                        ],
                      ),

                      // Description
                      if (room.description != null &&
                          room.description!.isNotEmpty) ...[
                        const Divider(height: 24),
                        Text(
                          room.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],

                      const Divider(height: 24),

                      // Stats row
                      Row(
                        children: [
                          _StatItem(
                            icon: Icons.people_outline,
                            label: '${room.memberCount}',
                            subtitle: 'Members',
                          ),
                          const SizedBox(width: 24),
                          _StatItem(
                            icon: Icons.calendar_today_outlined,
                            label: room.createdAt.formattedDate,
                            subtitle: 'Created',
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Leaderboard button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LeaderboardScreen(
                                  roomId: room.id,
                                  roomName: room.name,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.leaderboard_outlined),
                          label: const Text('View Leaderboard'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.winner,
                            side: BorderSide(
                              color: AppColors.winner.withAlpha(100),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Today's Challenge section
              _TodayChallengeSection(
                roomId: room.id,
                isAdmin: room.isAdmin,
              ),

              const SizedBox(height: 24),

              // Members section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Members',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    '${room.memberCount}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              membersAsync.when(
                data: (members) => Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: member.isAdmin
                              ? AppColors.primary.withAlpha(25)
                              : AppColors.accent.withAlpha(25),
                          child: Text(
                            (member.username ?? '?')[0].toUpperCase(),
                            style: TextStyle(
                              color: member.isAdmin
                                  ? AppColors.primary
                                  : AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          member.displayName ?? member.username ?? 'Unknown',
                        ),
                        subtitle: Text('@${member.username ?? ''}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: member.isAdmin
                                ? AppColors.primary.withAlpha(25)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            member.isAdmin ? 'Admin' : 'Member',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: member.isAdmin
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Failed to load members: $error'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Room')),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              ChallengeCardShimmer(),
              SizedBox(height: 16),
              RoomListShimmer(count: 3),
            ],
          ),
        ),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Room')),
        body: ErrorStateWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(roomByIdProvider(roomId)),
        ),
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    String roomId,
    String roomName,
  ) {
    switch (action) {
      case 'edit':
        _showEditDialog(context, ref, roomId);
        break;
      case 'delete':
        _showDeleteConfirmation(context, ref, roomId, roomName);
        break;
      case 'leave':
        _showLeaveConfirmation(context, ref, roomId, roomName);
        break;
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, String roomId) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final room = ref.read(roomByIdProvider(roomId)).value;
    if (room != null) {
      nameController.text = room.name;
      descController.text = room.description ?? '';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Room'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Room Name',
                prefixIcon: Icon(Icons.groups_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 2,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(roomRepositoryProvider).updateRoom(
                      roomId: roomId,
                      name: nameController.text,
                      description: descController.text,
                    );
                ref.invalidate(roomByIdProvider(roomId));
                ref.read(roomActionsProvider).refreshRooms();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Room updated!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    String roomId,
    String roomName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Room'),
        content: Text(
          'Are you sure you want to delete "$roomName"? This action cannot be undone and all room data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(roomActionsProvider).deleteRoom(roomId);
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to home
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Room deleted'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showLeaveConfirmation(
    BuildContext context,
    WidgetRef ref,
    String roomId,
    String roomName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Leave Room'),
        content: Text('Are you sure you want to leave "$roomName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(roomActionsProvider).leaveRoom(roomId);
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to home
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You left the room'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to leave: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget showing today's challenge in room detail
class _TodayChallengeSection extends ConsumerWidget {
  final String roomId;
  final bool isAdmin;

  const _TodayChallengeSection({
    required this.roomId,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(todayChallengeProvider(roomId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Challenge",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // History button
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChallengeHistoryScreen(roomId: roomId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('History'),
                ),
                // Create challenge button (admin only)
                if (isAdmin)
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => CreateChallengeDialog(roomId: roomId),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Create Challenge',
                    color: AppColors.primary,
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Challenge content
        challengeAsync.when(
          data: (challenge) {
            if (challenge == null) {
              return _buildNoChallenge(context);
            }

            return _buildChallengeCard(context, challenge, ref);
          },
          loading: () => const ChallengeCardShimmer(),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(height: 8),
                  Text('Failed to load challenge: $error'),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(todayChallengeProvider(roomId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoChallenge(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 48,
                color: AppColors.primary.withAlpha(100),
              ),
              const SizedBox(height: 12),
              Text(
                'No challenge today',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                isAdmin
                    ? 'Tap + to create a challenge'
                    : 'Challenges will appear here daily',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeCard(
    BuildContext context,
    dynamic challenge,
    WidgetRef ref,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChallengeDetailScreen(
                challengeId: challenge.id,
                roomId: roomId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_circle_outline,
                            size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        const Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      challenge.challengeType.label,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Challenge text
              Text(
                challenge.challengeText,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),

              // Stats
              Row(
                children: [
                  const Icon(Icons.people_outline,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    '${challenge.submissionCount} submission${challenge.submissionCount == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                  ),
                  const Spacer(),
                  if (challenge.hasUserSubmitted)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle,
                            size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          'Submitted',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    )
                  else
                    TextButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          builder: (_) =>
                              SubmitResponseSheet(challenge: challenge),
                        );
                      },
                      child: const Text('Submit Now →'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
