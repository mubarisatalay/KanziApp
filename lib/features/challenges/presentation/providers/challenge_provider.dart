import 'dart:async';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/api_providers.dart';
import '../../data/models/challenge_model.dart';
import '../../data/models/reveal_result_model.dart';
import '../../data/models/submission_model.dart';
import '../../data/repositories/challenge_repository.dart';
import '../../domain/entities/challenge.dart';

/// Provider for challenge repository
final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepositoryImpl(ref.watch(apiClientProvider));
});

/// How often submissions are polled for near-real-time updates. Supabase Realtime
/// had no Spring equivalent, so we poll while a challenge's submissions are on screen.
const _submissionsPollInterval = Duration(seconds: 6);

/// Provider for today's challenge in a room
final todayChallengeProvider =
    FutureProvider.family<ChallengeModel?, String>((ref, roomId) async {
  final repository = ref.watch(challengeRepositoryProvider);
  return repository.getTodayChallenge(roomId);
});

/// Ceremony results for a revealed challenge (the server 409s before reveal).
final revealResultsProvider =
    FutureProvider.family<RevealResultModel, String>((ref, challengeId) async {
  final repository = ref.watch(challengeRepositoryProvider);
  return repository.getRevealResults(challengeId);
});

/// Provider for challenge history in a room
final challengeHistoryProvider =
    FutureProvider.family<List<ChallengeModel>, String>((ref, roomId) async {
  final repository = ref.watch(challengeRepositoryProvider);
  return repository.getChallengeHistory(roomId);
});

/// Provider for a single challenge by ID
final challengeByIdProvider =
    FutureProvider.family<ChallengeModel, String>((ref, challengeId) async {
  final repository = ref.watch(challengeRepositoryProvider);
  return repository.getChallengeById(challengeId);
});

/// Provider for submissions of a challenge with near-real-time updates via polling.
/// (Replaces the old Supabase Realtime subscription on the submissions/votes tables.)
final submissionsProvider =
    FutureProvider.family<List<SubmissionModel>, String>(
        (ref, challengeId) async {
  final repository = ref.watch(challengeRepositoryProvider);

  // Poll while this provider is alive; each tick re-fetches. Riverpod disposes the
  // previous timer on rebuild via onDispose.
  final timer = Timer.periodic(_submissionsPollInterval, (_) => ref.invalidateSelf());
  ref.onDispose(timer.cancel);

  return repository.getSubmissions(challengeId);
});

/// Provider for challenge loading state
final challengeLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider for challenge error message
final challengeErrorProvider = StateProvider<String?>((ref) => null);

/// Challenge actions class
class ChallengeActions {
  final Ref _ref;

  ChallengeActions(this._ref);

  /// Create a challenge (admin)
  Future<ChallengeModel> createChallenge({
    required String roomId,
    required String challengeText,
    required ChallengeType challengeType,
    required DateTime challengeDate,
  }) async {
    final repository = _ref.read(challengeRepositoryProvider);
    _ref.read(challengeLoadingProvider.notifier).state = true;
    _ref.read(challengeErrorProvider.notifier).state = null;

    try {
      final challenge = await repository.createChallenge(
        roomId: roomId,
        challengeText: challengeText,
        challengeType: challengeType,
        challengeDate: challengeDate,
      );
      _ref.invalidate(todayChallengeProvider(roomId));
      _ref.invalidate(challengeHistoryProvider(roomId));
      return challenge;
    } on ChallengeRepositoryException catch (e) {
      _ref.read(challengeErrorProvider.notifier).state = e.message;
      rethrow;
    } catch (e) {
      _ref.read(challengeErrorProvider.notifier).state =
          'Failed to create challenge';
      rethrow;
    } finally {
      _ref.read(challengeLoadingProvider.notifier).state = false;
    }
  }

  /// Submit a response
  Future<SubmissionModel> submitResponse({
    required String challengeId,
    required String roomId,
    String? textContent,
    XFile? image,
  }) async {
    final repository = _ref.read(challengeRepositoryProvider);
    _ref.read(challengeLoadingProvider.notifier).state = true;
    _ref.read(challengeErrorProvider.notifier).state = null;

    try {
      final submission = await repository.submitResponse(
        challengeId: challengeId,
        roomId: roomId,
        textContent: textContent,
        image: image,
      );
      _ref.invalidate(submissionsProvider(challengeId));
      _ref.invalidate(todayChallengeProvider(roomId));
      return submission;
    } on ChallengeRepositoryException catch (e) {
      _ref.read(challengeErrorProvider.notifier).state = e.message;
      rethrow;
    } catch (e) {
      _ref.read(challengeErrorProvider.notifier).state =
          'Failed to submit response';
      rethrow;
    } finally {
      _ref.read(challengeLoadingProvider.notifier).state = false;
    }
  }

  /// Vote on a submission
  Future<void> voteOnSubmission({
    required String submissionId,
    required String challengeId,
    required int voteValue,
  }) async {
    final repository = _ref.read(challengeRepositoryProvider);

    try {
      await repository.voteOnSubmission(
        submissionId: submissionId,
        voteValue: voteValue,
      );
      _ref.invalidate(submissionsProvider(challengeId));
    } on ChallengeRepositoryException catch (e) {
      _ref.read(challengeErrorProvider.notifier).state = e.message;
      rethrow;
    }
  }

  /// Remove vote
  Future<void> removeVote({
    required String submissionId,
    required String challengeId,
  }) async {
    final repository = _ref.read(challengeRepositoryProvider);

    try {
      await repository.removeVote(submissionId);
      _ref.invalidate(submissionsProvider(challengeId));
    } on ChallengeRepositoryException catch (e) {
      _ref.read(challengeErrorProvider.notifier).state = e.message;
      rethrow;
    }
  }

  /// Delete a submission
  Future<void> deleteSubmission({
    required String submissionId,
    required String challengeId,
    required String roomId,
  }) async {
    final repository = _ref.read(challengeRepositoryProvider);

    try {
      await repository.deleteSubmission(submissionId);
      _ref.invalidate(submissionsProvider(challengeId));
      _ref.invalidate(todayChallengeProvider(roomId));
    } on ChallengeRepositoryException catch (e) {
      _ref.read(challengeErrorProvider.notifier).state = e.message;
      rethrow;
    }
  }

  /// Refresh challenge data
  void refreshChallenge(String roomId) {
    _ref.invalidate(todayChallengeProvider(roomId));
  }

  /// Refresh submissions
  void refreshSubmissions(String challengeId) {
    _ref.invalidate(submissionsProvider(challengeId));
  }

  /// Clear error
  void clearError() {
    _ref.read(challengeErrorProvider.notifier).state = null;
  }
}

/// Provider for challenge actions
final challengeActionsProvider = Provider<ChallengeActions>((ref) {
  return ChallengeActions(ref);
});
