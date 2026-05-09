import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/submission.dart';
import '../providers/challenge_provider.dart';

/// Card displaying a user's submission with voting
class SubmissionCard extends ConsumerWidget {
  final Submission submission;
  final String currentUserId;
  final bool isActive; // Whether voting is still allowed

  const SubmissionCard({
    super.key,
    required this.submission,
    required this.currentUserId,
    this.isActive = true,
  });

  bool get _isOwnSubmission => submission.userId == currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (submission.imageUrl != null)
            CachedNetworkImage(
              imageUrl: submission.imageUrl!,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 250,
                color: AppColors.surfaceVariant,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 250,
                color: AppColors.surfaceVariant,
                child: const Center(
                  child: Icon(Icons.broken_image_outlined,
                      size: 48, color: AppColors.textTertiary),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _isOwnSubmission
                          ? AppColors.primary.withAlpha(25)
                          : AppColors.accent.withAlpha(25),
                      child: Text(
                        (submission.username ?? '?')[0].toUpperCase(),
                        style: TextStyle(
                          color: _isOwnSubmission
                              ? AppColors.primary
                              : AppColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            submission.displayName ??
                                submission.username ??
                                'Unknown',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            submission.submittedAt.timeAgo,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (_isOwnSubmission)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),

                // Text content
                if (submission.textContent != null &&
                    submission.textContent!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    submission.textContent!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],

                // Voting section
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),

                Row(
                  children: [
                    // Vote count & average
                    Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: submission.voteCount > 0
                          ? AppColors.winner
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      submission.voteCount > 0
                          ? '${submission.averageVote.toStringAsFixed(1)} (${submission.voteCount})'
                          : 'No votes yet',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),

                    const Spacer(),

                    // Vote buttons (only if not own submission and challenge is active)
                    if (!_isOwnSubmission && isActive)
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
            ),
          ),
        ],
      ),
    );
  }
}

/// Vote stars widget with optimistic UI updates
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

    // Animate the star tap
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
                      size: 24,
                      color: isSelected
                          ? AppColors.winner
                          : AppColors.textTertiary,
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
