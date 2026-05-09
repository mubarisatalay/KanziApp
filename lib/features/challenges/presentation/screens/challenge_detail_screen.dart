import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/challenge.dart';
import '../providers/challenge_provider.dart';
import '../widgets/submission_card.dart';
import '../widgets/submit_response_sheet.dart';

/// Screen showing challenge details and submissions
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
    final currentUser = ref.watch(currentUserProvider);

    return challengeAsync.when(
      data: (challenge) => Scaffold(
        appBar: AppBar(
          title: Text(challenge.isToday ? "Today's Challenge" : 'Challenge'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(challengeByIdProvider(challengeId));
                ref.invalidate(submissionsProvider(challengeId));
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(challengeByIdProvider(challengeId));
            ref.invalidate(submissionsProvider(challengeId));
            await ref.read(submissionsProvider(challengeId).future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Challenge card
                _ChallengeInfoCard(challenge: challenge),
                const SizedBox(height: 24),

                // Submissions header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Submissions',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      '${challenge.submissionCount}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Submissions list
                submissionsAsync.when(
                  data: (submissions) {
                    if (submissions.isEmpty) {
                      return _buildEmptySubmissions(context);
                    }

                    return Column(
                      children: submissions
                          .map((s) => SubmissionCard(
                                submission: s,
                                currentUserId: currentUser?.id ?? '',
                                isActive: challenge.isToday,
                              ))
                          .toList(),
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
            ),
          ),
        ),
        // FAB to submit if challenge is active and user hasn't submitted
        floatingActionButton: challenge.isToday && !challenge.hasUserSubmitted
            ? FloatingActionButton.extended(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (_) => SubmitResponseSheet(challenge: challenge),
                  );
                },
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Submit'),
              )
            : null,
      ),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Challenge')),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              ChallengeCardShimmer(),
              SizedBox(height: 24),
              SubmissionListShimmer(),
            ],
          ),
        ),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Challenge')),
        body: ErrorStateWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(challengeByIdProvider(challengeId)),
        ),
      ),
    );
  }

  Widget _buildEmptySubmissions(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'No submissions yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Be the first to submit!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeInfoCard extends StatelessWidget {
  final Challenge challenge;

  const _ChallengeInfoCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: challenge.isToday
                        ? AppColors.success.withAlpha(25)
                        : AppColors.textTertiary.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        challenge.isToday
                            ? Icons.play_circle_outline
                            : Icons.check_circle_outline,
                        size: 14,
                        color: challenge.isToday
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        challenge.isToday ? 'Active' : 'Completed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: challenge.isToday
                              ? AppColors.success
                              : AppColors.textSecondary,
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_typeIcon(challenge.challengeType),
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        challenge.challengeType.label,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Challenge text
            Text(
              challenge.challengeText,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),

            // Date
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  challenge.challengeDate.formattedDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.people_outline,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  '${challenge.submissionCount} submission${challenge.submissionCount == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
              ],
            ),

            // User submission status
            if (challenge.isToday) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: challenge.hasUserSubmitted
                      ? AppColors.success.withAlpha(15)
                      : AppColors.warning.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      challenge.hasUserSubmitted
                          ? Icons.check_circle_outline
                          : Icons.pending_outlined,
                      size: 18,
                      color: challenge.hasUserSubmitted
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      challenge.hasUserSubmitted
                          ? 'You have submitted!'
                          : 'You haven\'t submitted yet',
                      style: TextStyle(
                        fontSize: 13,
                        color: challenge.hasUserSubmitted
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(ChallengeType type) {
    switch (type) {
      case ChallengeType.photo:
        return Icons.photo_camera_outlined;
      case ChallengeType.text:
        return Icons.text_fields;
      case ChallengeType.photoText:
        return Icons.photo_library_outlined;
    }
  }
}
