import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/kor/kor.dart';
import '../../../challenges/domain/entities/challenge.dart';
import '../../../challenges/presentation/providers/challenge_provider.dart';
import '../../../challenges/presentation/screens/challenge_detail_screen.dart';
import '../../../challenges/presentation/screens/challenge_history_screen.dart';
import '../../../challenges/presentation/widgets/create_challenge_dialog.dart';
import '../../../challenges/presentation/widgets/submit_response_sheet.dart';
import '../../../leaderboard/presentation/screens/leaderboard_screen.dart';
import '../providers/room_provider.dart';
import '../widgets/create_room_dialog.dart' show KorDialogField;

/// Room detail — KOR design "2a Room detail".
class RoomDetailScreen extends ConsumerWidget {
  final String roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomByIdProvider(roomId));
    final membersAsync = ref.watch(roomMembersProvider(roomId));
    final l10n = AppLocalizations.of(context);

    return roomAsync.when(
      data: (room) => Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: back square, name + meta, overflow menu.
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
                          Text(
                            room.name,
                            style: Theme.of(context).textTheme.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.members(room.memberCount) +
                                (room.isAdmin ? l10n.youAreAdminSuffix : ''),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    _RoomMenu(room: room, roomId: roomId),
                  ],
                ),
                const SizedBox(height: 18),

                // Invite code row.
                GlassCard(
                  radius: 16,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Text(
                        l10n.inviteCodeLabel,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            room.code,
                            style: AppTheme.mono(
                              fontSize: 17,
                              letterSpacing: 5,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      ),
                      PressableScale(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: room.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.codeCopied)),
                          );
                        },
                        child: Text(
                          l10n.shareAction,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Today's challenge.
                SectionLabel(
                  l10n.sectionTodaysChallengeUpper,
                  trailing: PressableScale(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ChallengeHistoryScreen(roomId: roomId),
                        ),
                      );
                    },
                    child: Text(
                      l10n.historyLink,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 12.5,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _TodayChallengeHero(roomId: roomId, isAdmin: room.isAdmin),
                const SizedBox(height: 24),

                // Members.
                SectionLabel(
                  l10n.sectionMembersUpper,
                  trailing: PressableScale(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LeaderboardScreen(
                            roomId: room.id,
                            roomName: room.name,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      l10n.leaderboardLink,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.primaryText,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                membersAsync.when(
                  data: (members) => GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < members.length; i++) ...[
                          if (i > 0)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: Divider(),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                MonogramAvatar(
                                  name: members[i].displayName ??
                                      members[i].username,
                                  size: 34,
                                  tint: MonogramTint.values[
                                      (members[i].username ?? '?')
                                              .hashCode
                                              .abs() %
                                          MonogramTint.values.length],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        members[i].displayName ??
                                            members[i].username ??
                                            l10n.unknownUser,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        '@${members[i].username ?? ''}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                                color: AppColors.textFaint,
                                                fontSize: 11.5),
                                      ),
                                    ],
                                  ),
                                ),
                                if (members[i].isAdmin)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.coralTint,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      l10n.adminBadge,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => GlassCard(
                    child: Text(
                      l10n.membersLoadFailed(error.toString()),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      loading: () => const Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                ChallengeCardShimmer(),
                SizedBox(height: 16),
                RoomListShimmer(count: 3),
              ],
            ),
          ),
        ),
      ),
      error: (error, _) => Scaffold(
        body: SafeArea(
          child: ErrorStateWidget(
            message: error.toString(),
            onRetry: () => ref.invalidate(roomByIdProvider(roomId)),
          ),
        ),
      ),
    );
  }
}

/// Overflow menu (glass ⋯ square): admin gets edit/create/delete, members leave.
class _RoomMenu extends ConsumerWidget {
  final dynamic room;
  final String roomId;

  const _RoomMenu({required this.room, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.glassBorder),
      ),
      onSelected: (value) => _handle(context, ref, value),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceGlass,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: const Icon(Icons.more_horiz,
            size: 19, color: AppColors.textPrimary),
      ),
      itemBuilder: (context) => [
        if (room.isAdmin) ...[
          PopupMenuItem(
              value: 'create', child: Text(l10n.menuCreateChallenge)),
          PopupMenuItem(value: 'edit', child: Text(l10n.menuEditRoom)),
          PopupMenuItem(
            value: 'delete',
            child: Text(l10n.menuDeleteRoom,
                style: const TextStyle(color: AppColors.primaryText)),
          ),
        ] else
          PopupMenuItem(
            value: 'leave',
            child: Text(l10n.menuLeaveRoom,
                style: const TextStyle(color: AppColors.primaryText)),
          ),
      ],
    );
  }

  void _handle(BuildContext context, WidgetRef ref, String action) {
    final l10n = AppLocalizations.of(context);
    switch (action) {
      case 'create':
        showDialog(
          context: context,
          builder: (_) => CreateChallengeDialog(roomId: roomId),
        );
      case 'edit':
        _showEditDialog(context, ref);
      case 'delete':
        _confirm(
          context,
          title: l10n.deleteRoomTitle,
          message: l10n.deleteRoomConfirm(room.name as String),
          confirmLabel: l10n.delete,
          onConfirm: () async {
            await ref.read(roomActionsProvider).deleteRoom(roomId);
          },
          successMessage: l10n.roomDeleted,
        );
      case 'leave':
        _confirm(
          context,
          title: l10n.leaveRoomTitle,
          message: l10n.leaveRoomConfirm(room.name as String),
          confirmLabel: l10n.leave,
          onConfirm: () async {
            await ref.read(roomActionsProvider).leaveRoom(roomId);
          },
          successMessage: l10n.leftRoom,
        );
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: room.name as String);
    final descController =
        TextEditingController(text: (room.description as String?) ?? '');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.editRoomTitle,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              KorDialogField(
                label: l10n.labelRoomNameUpper,
                controller: nameController,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              KorDialogField(
                label: l10n.labelDescriptionUpper,
                controller: descController,
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              CoralButton(
                label: l10n.save,
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
                        SnackBar(content: Text(l10n.roomUpdated)),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text(l10n.updateFailed(e.toString()))),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      l10n.cancel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Future<void> Function() onConfirm,
    required String successMessage,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.textTertiary),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () async {
              try {
                await onConfirm();
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext); // close dialog
                  Navigator.pop(context); // back to home
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(successMessage)),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(AppLocalizations.of(context)
                            .actionFailed(e.toString()))),
                  );
                }
              }
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

/// The coral hero card for today's challenge (or the quiet no-challenge state).
class _TodayChallengeHero extends ConsumerWidget {
  final String roomId;
  final bool isAdmin;

  const _TodayChallengeHero({required this.roomId, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(todayChallengeProvider(roomId));

    return challengeAsync.when(
      data: (challenge) => challenge == null
          ? _NoChallengeCard(roomId: roomId, isAdmin: isAdmin)
          : _HeroCard(challenge: challenge, roomId: roomId),
      loading: () => const ChallengeCardShimmer(),
      error: (error, _) => GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).challengeLoadFailed,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            CoralButton.inline(
              label: AppLocalizations.of(context).retry,
              onPressed: () => ref.invalidate(todayChallengeProvider(roomId)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoChallengeCard extends StatelessWidget {
  final String roomId;
  final bool isAdmin;

  const _NoChallengeCard({required this.roomId, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.noChallengeToday,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            isAdmin ? l10n.noChallengeAdminHint : l10n.noChallengeMemberHint,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 14),
            CoralButton.inline(
              label: l10n.menuCreateChallenge,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => CreateChallengeDialog(roomId: roomId),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Challenge challenge;
  final String roomId;

  const _HeroCard({required this.challenge, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GlassCard.coral(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // AKTİF pill.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.coralTint,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.coralBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      challenge.isActive
                          ? l10n.statusActiveUpper
                          : l10n.statusFinishedUpper,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: AppColors.primaryText,
                          ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (challenge.isActive && challenge.revealAt != null)
                RevealCountdown(revealAt: challenge.revealAt!),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            challenge.challengeText,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                l10n.submissionsCount(challenge.submissionCount),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontSize: 12.5),
              ),
              const Spacer(),
              if (challenge.hasUserSubmitted)
                Text(
                  l10n.submitted,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                )
              else if (challenge.isActive)
                CoralButton.inline(
                  label: l10n.submitAction,
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => SubmitResponseSheet(challenge: challenge),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

