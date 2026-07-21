import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/kor/kor.dart';
import '../../domain/entities/challenge.dart';
import '../providers/challenge_provider.dart';
import '../widgets/challenge_countdown.dart';
import '../widgets/submission_card.dart';
import '../widgets/submit_response_sheet.dart';
import 'reveal_ceremony_screen.dart';

/// Challenge detail — KOR "2a Challenge detail" (revealed) + "3a Blind day".
class ChallengeDetailScreen extends ConsumerWidget {
  final String challengeId;
  final String roomId;

  const ChallengeDetailScreen({
    super.key,
    required this.challengeId,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(challengeByIdProvider(challengeId));
    final submissionsAsync = ref.watch(submissionsProvider(challengeId));
    final l10n = AppLocalizations.of(context);

    return challengeAsync.when(
      data: (challenge) {
        final blindNow = challenge.blind && !challenge.isRevealedNow;
        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(challengeByIdProvider(challengeId));
                ref.invalidate(submissionsProvider(challengeId));
                await ref.read(submissionsProvider(challengeId).future);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row.
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
                                challenge.isToday
                                    ? l10n.todaysChallengeTitle
                                    : l10n.challengeTitle,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                challenge.challengeDate.formattedDate,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: AppColors.textFaint),
                              ),
                            ],
                          ),
                        ),
                        // Reveal countdown only shown while challenge is active.
                        if (challenge.isActive && challenge.revealAt != null)
                          RevealCountdown(revealAt: challenge.revealAt!),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Hero: upcoming (text hidden) / blind day / standard info.
                    if (!challenge.isScheduledNow)
                      _UpcomingHero(
                        challenge: challenge,
                        onExpired: () {
                          ref.invalidate(challengeByIdProvider(challengeId));
                          ref.invalidate(submissionsProvider(challengeId));
                        },
                      )
                    else if (blindNow)
                      _BlindHero(
                        challenge: challenge,
                        onRevealReached: () {
                          ref.invalidate(challengeByIdProvider(challengeId));
                          ref.invalidate(submissionsProvider(challengeId));
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RevealCeremonyScreen(
                                  challengeId: challengeId),
                            ),
                          );
                        },
                      )
                    else
                      _InfoHero(challenge: challenge),

                    // "See results" button — only after reveal, not during blind day.
                    if (challenge.isScheduledNow &&
                        !blindNow &&
                        challenge.isRevealedNow &&
                        challenge.submissionCount > 0) ...[
                      const SizedBox(height: 12),
                      GlassCard.amber(
                        radius: 16,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RevealCeremonyScreen(
                                  challengeId: challengeId),
                            ),
                          );
                        },
                        child: Text(
                          l10n.seeResults,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Submissions section — hidden until challenge has started.
                    if (challenge.isScheduledNow) ...[
                      SectionLabel(
                        l10n.sectionSubmissionsUpper,
                        trailing: blindNow
                            ? Text(
                                l10n.anonymousNote,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: AppColors.textFaint,
                                        fontSize: 11),
                              )
                            : Text(
                                '${challenge.submissionCount}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: AppColors.textTertiary),
                              ),
                      ),
                      const SizedBox(height: 12),
                      submissionsAsync.when(
                        data: (submissions) {
                          if (submissions.isEmpty) {
                            return GlassCard(
                              padding: const EdgeInsets.all(22),
                              child: Center(
                                child: Text(
                                  l10n.noSubmissionsYet,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: AppColors.textTertiary),
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: [
                              for (var i = 0; i < submissions.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: SubmissionCard(
                                    submission: submissions[i],
                                    index: i,
                                    isActive: challenge.isActive,
                                  ),
                                ),
                            ],
                          );
                        },
                        loading: () => const SubmissionListShimmer(),
                        error: (error, _) => ErrorStateWidget(
                          message: error.toString(),
                          onRetry: () =>
                              ref.invalidate(submissionsProvider(challengeId)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Submit CTA — only while active (started + not revealed) and not yet submitted.
          bottomNavigationBar:
              challenge.isActive && !challenge.hasUserSubmitted
                  ? SafeArea(
                      minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: CoralButton(
                        label: challenge.challengeType.requiresPhoto
                            ? l10n.submitYourPhoto
                            : l10n.submitYourAnswer,
                        height: 54,
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) =>
                                SubmitResponseSheet(challenge: challenge),
                          );
                        },
                      ),
                    )
                  : null,
        );
      },
      loading: () => const Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                ChallengeCardShimmer(),
                SizedBox(height: 24),
                SubmissionListShimmer(),
              ],
            ),
          ),
        ),
      ),
      error: (error, _) => Scaffold(
        body: SafeArea(
          child: ErrorStateWidget(
            message: error.toString(),
            onRetry: () => ref.invalidate(challengeByIdProvider(challengeId)),
          ),
        ),
      ),
    );
  }
}

/// Upcoming hero: challenge hasn't started yet — text stays hidden.
class _UpcomingHero extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback? onExpired;

  const _UpcomingHero({required this.challenge, this.onExpired});

  @override
  Widget build(BuildContext context) {
    return GlassCard.coral(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.lock_clock,
              size: 36, color: AppColors.textTertiary.withAlpha(180)),
          const SizedBox(height: 14),
          Text(
            "Challenge hasn't started yet",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'The challenge will be revealed when it starts.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 22),
          ChallengeCountdown(challenge: challenge, onExpired: onExpired),
        ],
      ),
    );
  }
}

/// Blind-day hero (3a): challenge text + big countdown to reveal.
class _BlindHero extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback? onRevealReached;

  const _BlindHero({required this.challenge, this.onRevealReached});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final revealAt = challenge.revealAt;
    final revealTime = revealAt != null
        ? '${revealAt.toLocal().hour.toString().padLeft(2, '0')}:'
            '${revealAt.toLocal().minute.toString().padLeft(2, '0')}'
        : '21:00';
    return GlassCard.coral(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            challenge.challengeText,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.revealCountdownLabelUpper,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 10.5,
                  letterSpacing: 1.6,
                  color: AppColors.textTertiary,
                ),
          ),
          const SizedBox(height: 6),
          if (revealAt != null)
            RevealCountdown.big(revealAt: revealAt, onDone: onRevealReached),
          const SizedBox(height: 10),
          Text(
            l10n.revealNote(revealTime),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// Standard hero (2a): status pill, type chip, challenge text, meta.
class _InfoHero extends StatelessWidget {
  final Challenge challenge;

  const _InfoHero({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = challenge.isActive;
    final label = challenge.isUpcoming
        ? l10n.statusUpcomingUpper
        : active
            ? l10n.statusActiveUpper
            : l10n.statusFinishedUpper;
    final highlighted = active && !challenge.isUpcoming;
    return GlassCard.coral(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: highlighted
                      ? AppColors.coralTint
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                      color: highlighted
                          ? AppColors.coralBorder
                          : AppColors.glassBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: highlighted
                            ? AppColors.primary
                            : AppColors.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: highlighted
                                ? AppColors.primaryText
                                : AppColors.textTertiary,
                          ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _typeLabel(l10n, challenge.challengeType),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            challenge.challengeText,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 14),
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
              if (challenge.isToday)
                Text(
                  challenge.hasUserSubmitted
                      ? l10n.youSubmitted
                      : l10n.youHaventSubmitted,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 12.5,
                        color: challenge.hasUserSubmitted
                            ? AppColors.accent
                            : AppColors.primaryText,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _typeLabel(AppLocalizations l10n, ChallengeType type) =>
      switch (type) {
        ChallengeType.photo => l10n.typePhoto,
        ChallengeType.text => l10n.typeText,
        ChallengeType.photoText => l10n.typePhotoText,
      };
}
