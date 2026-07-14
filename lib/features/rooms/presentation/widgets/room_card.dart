import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/kor/kor.dart';
import '../../../challenges/domain/entities/challenge.dart';
import '../../../challenges/presentation/providers/challenge_provider.dart';
import '../../domain/entities/room.dart';

/// Room summary card — KOR design "2a Home".
///
/// Glass card: monogram tile + name/code/member row, hairline divider, then a
/// live status line driven by the room's today-challenge.
class RoomCard extends ConsumerWidget {
  final Room room;
  final VoidCallback? onTap;

  const RoomCard({
    super.key,
    required this.room,
    this.onTap,
  });

  /// Deterministic tint so the list gets varied (but stable) tile colors.
  MonogramTint get _tint =>
      MonogramTint.values[room.name.hashCode.abs() % MonogramTint.values.length];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayChallenge = ref.watch(todayChallengeProvider(room.id));

    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MonogramTile(name: room.name, tint: _tint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            room.code,
                            style: AppTheme.mono(
                              fontSize: 10.5,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context).members(room.memberCount) +
                                (room.isAdmin
                                    ? AppLocalizations.of(context).adminSuffix
                                    : ''),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textTertiary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: todayChallenge.when(
                  data: (challenge) => _StatusLine(
                    challenge: challenge,
                    memberCount: room.memberCount,
                  ),
                  loading: () => const _StatusText(
                    text: '…',
                    color: AppColors.textFaint,
                  ),
                  error: (_, __) => _StatusText(
                    text: AppLocalizations.of(context).noChallengeToday,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              Text(
                room.updatedAt.timeAgo,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textFaint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Coral status when there's an active challenge; tertiary when there's none.
class _StatusLine extends StatelessWidget {
  final Challenge? challenge;
  final int memberCount;

  const _StatusLine({required this.challenge, required this.memberCount});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = challenge;
    if (c == null) {
      return _StatusText(
        text: l10n.noChallengeToday,
        color: AppColors.textTertiary,
      );
    }
    final text = c.hasUserSubmitted
        ? l10n.activeChallengeProgress(c.submissionCount, memberCount)
        : l10n.challengeAwaitsYou;
    return _StatusText(text: text, color: AppColors.primaryText, dot: true);
  }
}

class _StatusText extends StatelessWidget {
  final String text;
  final Color color;
  final bool dot;

  const _StatusText({required this.text, required this.color, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (dot) ...[
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
        ],
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
