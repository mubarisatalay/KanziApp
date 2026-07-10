import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/leaderboard_entry_model.dart';

class LeaderboardRepositoryException implements Exception {
  final String message;
  LeaderboardRepositoryException(this.message);

  @override
  String toString() => message;
}

abstract class LeaderboardRepository {
  Future<List<LeaderboardEntryModel>> getDailyLeaderboard({
    required String roomId,
    required DateTime date,
  });

  Future<List<LeaderboardEntryModel>> getOverallLeaderboard(String roomId);
}

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  LeaderboardRepositoryImpl(this._api);

  final ApiClient _api;
  Dio get _dio => _api.dio;

  @override
  Future<List<LeaderboardEntryModel>> getDailyLeaderboard({
    required String roomId,
    required DateTime date,
  }) async {
    try {
      final res = await _dio.get(
        '/rooms/$roomId/leaderboard/daily',
        queryParameters: {'date': date.toIso8601String().split('T').first},
      );
      return (res.data as List)
          .map((j) => LeaderboardEntryModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw LeaderboardRepositoryException(
          messageFromDioError(e, 'Failed to load leaderboard'));
    }
  }

  @override
  Future<List<LeaderboardEntryModel>> getOverallLeaderboard(String roomId) async {
    try {
      final res = await _dio.get('/rooms/$roomId/leaderboard/overall');
      return (res.data as List)
          .map((j) => LeaderboardEntryModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw LeaderboardRepositoryException(
          messageFromDioError(e, 'Failed to load leaderboard'));
    }
  }
}
