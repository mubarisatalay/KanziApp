import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/room_model.dart';
import '../models/room_member_model.dart';

class RoomRepositoryException implements Exception {
  final String message;
  RoomRepositoryException(this.message);

  @override
  String toString() => message;
}

abstract class RoomRepository {
  Future<List<RoomModel>> getUserRooms();
  Future<RoomModel> getRoomById(String roomId);
  Future<RoomModel> createRoom({required String name, String? description});
  Future<RoomModel> joinRoomByCode(String code);
  Future<void> leaveRoom(String roomId);
  Future<void> deleteRoom(String roomId);
  Future<RoomModel> updateRoom({required String roomId, String? name, String? description});
  Future<List<RoomMemberModel>> getRoomMembers(String roomId);
  Future<void> removeMember({required String roomId, required String userId});
}

class RoomRepositoryImpl implements RoomRepository {
  RoomRepositoryImpl(this._api);

  final ApiClient _api;
  Dio get _dio => _api.dio;

  @override
  Future<List<RoomModel>> getUserRooms() async {
    try {
      final res = await _dio.get('/rooms');
      return (res.data as List)
          .map((j) => RoomModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw RoomRepositoryException(messageFromDioError(e, 'Failed to load rooms'));
    }
  }

  @override
  Future<RoomModel> getRoomById(String roomId) async {
    try {
      final res = await _dio.get('/rooms/$roomId');
      return RoomModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw RoomRepositoryException(messageFromDioError(e, 'Failed to load room'));
    }
  }

  @override
  Future<RoomModel> createRoom({required String name, String? description}) async {
    try {
      final res = await _dio.post('/rooms', data: {
        'name': name.trim(),
        if (description != null) 'description': description.trim(),
      });
      return RoomModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw RoomRepositoryException(messageFromDioError(e, 'Failed to create room'));
    }
  }

  @override
  Future<RoomModel> joinRoomByCode(String code) async {
    try {
      final res = await _dio.post('/rooms/join', data: {'code': code.trim().toUpperCase()});
      return RoomModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw RoomRepositoryException(messageFromDioError(e, 'Failed to join room'));
    }
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    try {
      await _dio.delete('/rooms/$roomId/membership');
    } on DioException catch (e) {
      throw RoomRepositoryException(messageFromDioError(e, 'Failed to leave room'));
    }
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    try {
      await _dio.delete('/rooms/$roomId');
    } on DioException catch (e) {
      throw RoomRepositoryException(messageFromDioError(e, 'Failed to delete room'));
    }
  }

  @override
  Future<RoomModel> updateRoom({required String roomId, String? name, String? description}) async {
    try {
      final res = await _dio.patch('/rooms/$roomId', data: {
        if (name != null) 'name': name.trim(),
        if (description != null) 'description': description.trim(),
      });
      return RoomModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw RoomRepositoryException(messageFromDioError(e, 'Failed to update room'));
    }
  }

  @override
  Future<List<RoomMemberModel>> getRoomMembers(String roomId) async {
    try {
      final res = await _dio.get('/rooms/$roomId/members');
      return (res.data as List)
          .map((j) => RoomMemberModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw RoomRepositoryException(messageFromDioError(e, 'Failed to load members'));
    }
  }

  @override
  Future<void> removeMember({required String roomId, required String userId}) async {
    try {
      await _dio.delete('/rooms/$roomId/members/$userId');
    } on DioException catch (e) {
      throw RoomRepositoryException(messageFromDioError(e, 'Failed to remove member'));
    }
  }
}
