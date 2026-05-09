import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/challenge.dart';
import '../models/challenge_model.dart';
import '../models/submission_model.dart';

/// Challenge repository exception
class ChallengeRepositoryException implements Exception {
  final String message;
  ChallengeRepositoryException(this.message);

  @override
  String toString() => message;
}

/// Challenge repository interface
abstract class ChallengeRepository {
  /// Get today's challenge for a room
  Future<ChallengeModel?> getTodayChallenge(String roomId);

  /// Get challenge history for a room
  Future<List<ChallengeModel>> getChallengeHistory(String roomId);

  /// Get a single challenge by ID
  Future<ChallengeModel> getChallengeById(String challengeId);

  /// Create a challenge (admin only)
  Future<ChallengeModel> createChallenge({
    required String roomId,
    required String challengeText,
    required ChallengeType challengeType,
    required DateTime challengeDate,
  });

  /// Get submissions for a challenge
  Future<List<SubmissionModel>> getSubmissions(String challengeId);

  /// Submit a response to a challenge
  Future<SubmissionModel> submitResponse({
    required String challengeId,
    required String roomId,
    String? textContent,
    File? imageFile,
  });

  /// Update a submission
  Future<SubmissionModel> updateSubmission({
    required String submissionId,
    String? textContent,
    File? imageFile,
  });

  /// Delete a submission
  Future<void> deleteSubmission(String submissionId);

  /// Vote on a submission
  Future<void> voteOnSubmission({
    required String submissionId,
    required int voteValue,
  });

  /// Remove vote from a submission
  Future<void> removeVote(String submissionId);
}

/// Challenge repository implementation
class ChallengeRepositoryImpl implements ChallengeRepository {
  final SupabaseClient _client;

  ChallengeRepositoryImpl(this._client);

  String get _currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw ChallengeRepositoryException('Not authenticated');
    }
    return user.id;
  }

  @override
  Future<ChallengeModel?> getTodayChallenge(String roomId) async {
    try {
      final userId = _currentUserId;
      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _client
          .from('challenges')
          .select('*, submissions(user_id)')
          .eq('room_id', roomId)
          .eq('challenge_date', today)
          .maybeSingle();

      if (response == null) return null;

      return ChallengeModel.fromJson(response, currentUserId: userId);
    } on PostgrestException catch (e) {
      throw ChallengeRepositoryException(
        'Failed to load challenge: ${e.message}',
      );
    } catch (e) {
      if (e is ChallengeRepositoryException) rethrow;
      throw ChallengeRepositoryException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<List<ChallengeModel>> getChallengeHistory(String roomId) async {
    try {
      final userId = _currentUserId;

      final response = await _client
          .from('challenges')
          .select('*, submissions(user_id)')
          .eq('room_id', roomId)
          .order('challenge_date', ascending: false)
          .limit(30);

      return (response as List)
          .map((json) => ChallengeModel.fromJson(
                json as Map<String, dynamic>,
                currentUserId: userId,
              ))
          .toList();
    } on PostgrestException catch (e) {
      throw ChallengeRepositoryException(
        'Failed to load challenge history: ${e.message}',
      );
    } catch (e) {
      if (e is ChallengeRepositoryException) rethrow;
      throw ChallengeRepositoryException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<ChallengeModel> getChallengeById(String challengeId) async {
    try {
      final userId = _currentUserId;

      final response = await _client
          .from('challenges')
          .select('*, submissions(user_id)')
          .eq('id', challengeId)
          .single();

      return ChallengeModel.fromJson(response, currentUserId: userId);
    } on PostgrestException catch (e) {
      throw ChallengeRepositoryException(
        'Failed to load challenge: ${e.message}',
      );
    } catch (e) {
      if (e is ChallengeRepositoryException) rethrow;
      throw ChallengeRepositoryException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<ChallengeModel> createChallenge({
    required String roomId,
    required String challengeText,
    required ChallengeType challengeType,
    required DateTime challengeDate,
  }) async {
    try {
      final response = await _client
          .from('challenges')
          .insert({
            'room_id': roomId,
            'challenge_text': challengeText.trim(),
            'challenge_type': challengeType.toDbString(),
            'challenge_date': challengeDate.toIso8601String().split('T')[0],
          })
          .select()
          .single();

      return ChallengeModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw ChallengeRepositoryException(
          'A challenge already exists for this date.',
        );
      }
      throw ChallengeRepositoryException(
        'Failed to create challenge: ${e.message}',
      );
    } catch (e) {
      if (e is ChallengeRepositoryException) rethrow;
      throw ChallengeRepositoryException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<List<SubmissionModel>> getSubmissions(String challengeId) async {
    try {
      final userId = _currentUserId;

      final response = await _client
          .from('submissions')
          .select(
            '*, profiles(username, display_name, avatar_url), votes(voter_id, vote_value)',
          )
          .eq('challenge_id', challengeId)
          .order('submitted_at');

      return (response as List)
          .map((json) => SubmissionModel.fromJson(
                json as Map<String, dynamic>,
                currentUserId: userId,
              ))
          .toList();
    } on PostgrestException catch (e) {
      throw ChallengeRepositoryException(
        'Failed to load submissions: ${e.message}',
      );
    } catch (e) {
      if (e is ChallengeRepositoryException) rethrow;
      throw ChallengeRepositoryException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<SubmissionModel> submitResponse({
    required String challengeId,
    required String roomId,
    String? textContent,
    File? imageFile,
  }) async {
    try {
      final userId = _currentUserId;
      String? imageUrl;

      // Upload image if provided
      if (imageFile != null) {
        imageUrl = await _uploadImage(
          file: imageFile,
          roomId: roomId,
          challengeId: challengeId,
          userId: userId,
        );
      }

      final response = await _client
          .from('submissions')
          .insert({
            'challenge_id': challengeId,
            'user_id': userId,
            'room_id': roomId,
            if (textContent != null && textContent.trim().isNotEmpty)
              'text_content': textContent.trim(),
            if (imageUrl != null) 'image_url': imageUrl,
          })
          .select(
            '*, profiles(username, display_name, avatar_url), votes(voter_id, vote_value)',
          )
          .single();

      return SubmissionModel.fromJson(response, currentUserId: userId);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw ChallengeRepositoryException(
          'You have already submitted a response to this challenge.',
        );
      }
      throw ChallengeRepositoryException(
        'Failed to submit response: ${e.message}',
      );
    } catch (e) {
      if (e is ChallengeRepositoryException) rethrow;
      throw ChallengeRepositoryException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<SubmissionModel> updateSubmission({
    required String submissionId,
    String? textContent,
    File? imageFile,
  }) async {
    try {
      final userId = _currentUserId;
      final updates = <String, dynamic>{};

      if (textContent != null) {
        updates['text_content'] = textContent.trim();
      }

      if (imageFile != null) {
        // Get existing submission to know room/challenge IDs
        final existing = await _client
            .from('submissions')
            .select('room_id, challenge_id')
            .eq('id', submissionId)
            .single();

        final imageUrl = await _uploadImage(
          file: imageFile,
          roomId: existing['room_id'] as String,
          challengeId: existing['challenge_id'] as String,
          userId: userId,
        );
        updates['image_url'] = imageUrl;
      }

      if (updates.isEmpty) {
        throw ChallengeRepositoryException('Nothing to update');
      }

      final response = await _client
          .from('submissions')
          .update(updates)
          .eq('id', submissionId)
          .select(
            '*, profiles(username, display_name, avatar_url), votes(voter_id, vote_value)',
          )
          .single();

      return SubmissionModel.fromJson(response, currentUserId: userId);
    } on PostgrestException catch (e) {
      throw ChallengeRepositoryException(
        'Failed to update submission: ${e.message}',
      );
    } catch (e) {
      if (e is ChallengeRepositoryException) rethrow;
      throw ChallengeRepositoryException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> deleteSubmission(String submissionId) async {
    try {
      await _client.from('submissions').delete().eq('id', submissionId);
    } on PostgrestException catch (e) {
      throw ChallengeRepositoryException(
        'Failed to delete submission: ${e.message}',
      );
    } catch (e) {
      if (e is ChallengeRepositoryException) rethrow;
      throw ChallengeRepositoryException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> voteOnSubmission({
    required String submissionId,
    required int voteValue,
  }) async {
    try {
      final userId = _currentUserId;

      await _client.from('votes').upsert(
        {
          'submission_id': submissionId,
          'voter_id': userId,
          'vote_value': voteValue,
        },
        onConflict: 'submission_id,voter_id',
      );
    } on PostgrestException catch (e) {
      if (e.message.contains('submissions') && e.message.contains('user_id')) {
        throw ChallengeRepositoryException(
          'You cannot vote on your own submission.',
        );
      }
      throw ChallengeRepositoryException(
        'Failed to submit vote: ${e.message}',
      );
    } catch (e) {
      if (e is ChallengeRepositoryException) rethrow;
      throw ChallengeRepositoryException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> removeVote(String submissionId) async {
    try {
      final userId = _currentUserId;

      await _client
          .from('votes')
          .delete()
          .eq('submission_id', submissionId)
          .eq('voter_id', userId);
    } on PostgrestException catch (e) {
      throw ChallengeRepositoryException(
        'Failed to remove vote: ${e.message}',
      );
    } catch (e) {
      if (e is ChallengeRepositoryException) rethrow;
      throw ChallengeRepositoryException('An unexpected error occurred: $e');
    }
  }

  /// Upload an image to Supabase Storage
  Future<String> _uploadImage({
    required File file,
    required String roomId,
    required String challengeId,
    required String userId,
  }) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      final path =
          '$roomId/$challengeId/${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _client.storage.from('challenge-images').upload(
            path,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      return _client.storage.from('challenge-images').getPublicUrl(path);
    } on StorageException catch (e) {
      throw ChallengeRepositoryException(
        'Failed to upload image: ${e.message}',
      );
    }
  }
}
