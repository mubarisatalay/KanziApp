import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/challenge.dart';
import '../models/challenge_model.dart';
import '../models/reveal_result_model.dart';
import '../models/submission_model.dart';

class ChallengeRepositoryException implements Exception {
  final String message;
  ChallengeRepositoryException(this.message);

  @override
  String toString() => message;
}

abstract class ChallengeRepository {
  Future<ChallengeModel?> getTodayChallenge(String roomId);
  Future<List<ChallengeModel>> getChallengeHistory(String roomId);
  Future<ChallengeModel> getChallengeById(String challengeId);
  Future<ChallengeModel> createChallenge({
    required String roomId,
    required String challengeText,
    required ChallengeType challengeType,
    required DateTime challengeDate,
  });
  Future<List<SubmissionModel>> getSubmissions(String challengeId);
  Future<RevealResultModel> getRevealResults(String challengeId);
  Future<SubmissionModel> submitResponse({
    required String challengeId,
    required String roomId,
    String? textContent,
    XFile? image,
  });
  Future<SubmissionModel> updateSubmission({
    required String submissionId,
    String? textContent,
    XFile? image,
  });
  Future<void> deleteSubmission(String submissionId);
  Future<void> voteOnSubmission({required String submissionId, required int voteValue});
  Future<void> removeVote(String submissionId);
}

class ChallengeRepositoryImpl implements ChallengeRepository {
  ChallengeRepositoryImpl(this._api);

  final ApiClient _api;
  Dio get _dio => _api.dio;

  static String _dateOnly(DateTime d) => d.toIso8601String().split('T').first;

  @override
  Future<ChallengeModel?> getTodayChallenge(String roomId) async {
    try {
      final res = await _dio.get('/rooms/$roomId/challenges/today');
      if (res.statusCode == 204 || res.data == null) return null;
      return ChallengeModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ChallengeRepositoryException(messageFromDioError(e, 'Failed to load challenge'));
    }
  }

  @override
  Future<List<ChallengeModel>> getChallengeHistory(String roomId) async {
    try {
      final res = await _dio.get('/rooms/$roomId/challenges');
      return (res.data as List)
          .map((j) => ChallengeModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ChallengeRepositoryException(
          messageFromDioError(e, 'Failed to load challenge history'));
    }
  }

  @override
  Future<ChallengeModel> getChallengeById(String challengeId) async {
    try {
      final res = await _dio.get('/challenges/$challengeId');
      return ChallengeModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ChallengeRepositoryException(messageFromDioError(e, 'Failed to load challenge'));
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
      final res = await _dio.post('/rooms/$roomId/challenges', data: {
        'challengeText': challengeText.trim(),
        'challengeType': challengeType.toDbString(),
        'challengeDate': _dateOnly(challengeDate),
      });
      return ChallengeModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ChallengeRepositoryException(messageFromDioError(e, 'Failed to create challenge'));
    }
  }

  @override
  Future<List<SubmissionModel>> getSubmissions(String challengeId) async {
    try {
      final res = await _dio.get('/challenges/$challengeId/submissions');
      return (res.data as List)
          .map((j) => SubmissionModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ChallengeRepositoryException(messageFromDioError(e, 'Failed to load submissions'));
    }
  }

  @override
  Future<RevealResultModel> getRevealResults(String challengeId) async {
    try {
      final res = await _dio.get('/challenges/$challengeId/reveal');
      return RevealResultModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // 409 = not revealed yet; surfaces as a normal repository error.
      throw ChallengeRepositoryException(
          messageFromDioError(e, 'Failed to load reveal results'));
    }
  }

  @override
  Future<SubmissionModel> submitResponse({
    required String challengeId,
    required String roomId,
    String? textContent,
    XFile? image,
  }) async {
    try {
      final form = await _multipart(textContent, image);
      final res = await _dio.post('/challenges/$challengeId/submissions', data: form);
      return SubmissionModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ChallengeRepositoryException(messageFromDioError(e, 'Failed to submit response'));
    }
  }

  @override
  Future<SubmissionModel> updateSubmission({
    required String submissionId,
    String? textContent,
    XFile? image,
  }) async {
    try {
      final form = await _multipart(textContent, image);
      final res = await _dio.patch('/submissions/$submissionId', data: form);
      return SubmissionModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ChallengeRepositoryException(messageFromDioError(e, 'Failed to update submission'));
    }
  }

  @override
  Future<void> deleteSubmission(String submissionId) async {
    try {
      await _dio.delete('/submissions/$submissionId');
    } on DioException catch (e) {
      throw ChallengeRepositoryException(messageFromDioError(e, 'Failed to delete submission'));
    }
  }

  @override
  Future<void> voteOnSubmission({required String submissionId, required int voteValue}) async {
    try {
      await _dio.put('/submissions/$submissionId/vote', data: {'voteValue': voteValue});
    } on DioException catch (e) {
      throw ChallengeRepositoryException(messageFromDioError(e, 'Failed to submit vote'));
    }
  }

  @override
  Future<void> removeVote(String submissionId) async {
    try {
      await _dio.delete('/submissions/$submissionId/vote');
    } on DioException catch (e) {
      throw ChallengeRepositoryException(messageFromDioError(e, 'Failed to remove vote'));
    }
  }

  Future<FormData> _multipart(String? textContent, XFile? image) async {
    return FormData.fromMap({
      if (textContent != null && textContent.trim().isNotEmpty)
        'textContent': textContent.trim(),
      if (image != null)
        // Bytes-based so it works on every platform, including web.
        'image': MultipartFile.fromBytes(
          await image.readAsBytes(),
          filename: image.name,
        ),
    });
  }
}
