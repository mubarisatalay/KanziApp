import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/kor/kor.dart';
import '../../domain/entities/submission.dart';
import '../providers/challenge_provider.dart';

/// Submission card — KOR. Two personalities:
/// revealed (author row + rating) and anonymous ("GÖNDERİ #n" + lock, content
/// still fully visible — that's what gets voted on).
class SubmissionCard extends ConsumerWidget {
  final Submission submission;

  /// Position in the (server-shuffled) list; names anonymous entries.
  final int index;
  final bool isActive; // whether voting is still open

  const SubmissionCard({
    super.key,
    required this.submission,
    this.index = 0,
    this.isActive = true,
  });

  bool get _canVote => !submission.isOwn && isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final imageHeight = submission.anonymous ? 130.0 : 150.0;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (submission.imageUrl != null)
              CachedNetworkImage(
                imageUrl: submission.imageUrl!,
                width: double.infinity,
                height: imageHeight,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: imageHeight,
                  color: AppColors.surfaceVariant,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: imageHeight,
                  color: AppColors.surfaceVariant,
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        size: 34, color: AppColors.textTertiary),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author row (or anonymous identity).
                  if (submission.anonymous)
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_outline_rounded,
                              size: 14, color: AppColors.textTertiary),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.anonymousEntry(index + 1),
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontSize: 12,
                                    letterSpacing: 1.2,
                                    color: AppColors.textTertiary,
                                  ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        MonogramAvatar(
                          name: submission.displayName ?? submission.username,
                          size: 30,
                          tint: submission.isOwn
                              ? MonogramTint.coral
                              : MonogramTint.values[
                                  (submission.username ?? '?').hashCode.abs() %
                                      MonogramTint.values.length],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  submission.displayName ??
                                      submission.username ??
                                      l10n.unknownUser,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (submission.isOwn) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    l10n.youPillUpper,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.onPrimary,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 6),
                              Text(
                                '· ${submission.submittedAt.timeAgo}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: AppColors.textFaint),
                              ),
                            ],
                          ),
                        ),
                        _RatingLabel(submission: submission),
                      ],
                    ),

                  // Text content — always visible, blind or not.
                  if (submission.textContent != null &&
                      submission.textContent!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      submission.textContent!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],

                  // Own-submission notice while voting is open.
                  if (submission.isOwn && isActive) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.amberTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.ownSubmissionNotice,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],

                  // Voting footer.
                  if (_canVote) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          submission.anonymous ? l10n.yourVote : l10n.vote,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  fontSize: 12,
                                  color: AppColors.textTertiary),
                        ),
                        const Spacer(),
                        _VoteStars(
                          currentVote: submission.currentUserVote,
                          onVote: (value) {
                            ref.read(challengeActionsProvider).voteOnSubmission(
                                  submissionId: submission.id,
                                  challengeId: submission.challengeId,
                                  voteValue: value,
                                );
                          },
                          onRemoveVote: () {
                            ref.read(challengeActionsProvider).removeVote(
                                  submissionId: submission.id,
                                  challengeId: submission.challengeId,
                                );
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "4.2 (5 oy)" — amber when rated, only meaningful post-reveal (pre-reveal
/// the API seals aggregates to zero, which renders as "Oy yok").
class _RatingLabel extends StatelessWidget {
  final Submission submission;

  const _RatingLabel({required this.submission});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rated = submission.voteCount > 0;
    return Text(
      rated
          ? l10n.ratingLabel(
              submission.averageVote.toStringAsFixed(1), submission.voteCount)
          : l10n.noVotesYet,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: rated ? AppColors.accent : AppColors.textFaint,
          ),
    );
  }
}

/// Five-star voting row with optimistic updates and a tap bounce.
/// Selected = amber; unselected = white 16%.
class _VoteStars extends StatefulWidget {
  final int? currentVote;
  final ValueChanged<int> onVote;
  final VoidCallback onRemoveVote;

  const _VoteStars({
    required this.currentVote,
    required this.onVote,
    required this.onRemoveVote,
  });

  @override
  State<_VoteStars> createState() => _VoteStarsState();
}

class _VoteStarsState extends State<_VoteStars>
    with SingleTickerProviderStateMixin {
  late int? _optimisticVote;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  static const _unselected = Color(0x29FFFFFF); // white 16%

  @override
  void initState() {
    super.initState();
    _optimisticVote = widget.currentVote;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(_VoteStars oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync with server data when it arrives
    _optimisticVote = widget.currentVote;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap(int starValue) {
    HapticFeedback.selectionClick();

    setState(() {
      if (_optimisticVote == starValue) {
        _optimisticVote = null;
        widget.onRemoveVote();
      } else {
        _optimisticVote = starValue;
        widget.onVote(starValue);
      }
    });

    _animationController.forward().then((_) => _animationController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isSelected =
            _optimisticVote != null && starValue <= _optimisticVote!;

        return GestureDetector(
          onTap: () => _handleTap(starValue),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              final scale = (isSelected &&
                      starValue == _optimisticVote &&
                      _animationController.isAnimating)
                  ? _scaleAnimation.value
                  : 1.0;
              return Transform.scale(
                scale: scale,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      isSelected
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      key: ValueKey('$starValue-$isSelected'),
                      size: 22,
                      color: isSelected ? AppColors.accent : _unselected,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
