import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/room_model.dart';
import '../models/room_member_model.dart';

/// Room repository exception
class RoomRepositoryException implements Exception {
  final String message;
  RoomRepositoryException(this.message);

  @override
  String toString() => message;
}

/// Room repository interface
abstract class RoomRepository {
  /// Get all rooms the current user is a member of
  Future<List<RoomModel>> getUserRooms();

  /// Get a single room by ID
  Future<RoomModel> getRoomById(String roomId);

  /// Create a new room (user becomes admin)
  Future<RoomModel> createRoom({
    required String name,
    String? description,
  });

  /// Join a room by invitation code
  Future<RoomModel> joinRoomByCode(String code);

  /// Leave a room
  Future<void> leaveRoom(String roomId);

  /// Delete a room (admin only)
  Future<void> deleteRoom(String roomId);

  /// Update room details (admin only)
  Future<RoomModel> updateRoom({
    required String roomId,
    String? name,
    String? description,
  });

  /// Get members of a room
  Future<List<RoomMemberModel>> getRoomMembers(String roomId);

  /// Remove a member from room (admin only)
  Future<void> removeMember({
    required String roomId,
    required String userId,
  });
}

/// Room repository implementation
class RoomRepositoryImpl implements RoomRepository {
  final SupabaseClient _client;

  RoomRepositoryImpl(this._client);

  String get _currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) throw RoomRepositoryException('Not authenticated');
    return user.id;
  }

  @override
  Future<List<RoomModel>> getUserRooms() async {
    try {
      final userId = _currentUserId;

      // Step 1: Explicitly get room IDs where THIS user is a member
      final memberships = await _client
          .from('room_members')
          .select('room_id')
          .eq('user_id', userId);

      final membershipList = memberships as List;
      if (membershipList.isEmpty) return [];

      final roomIds =
          membershipList.map((m) => m['room_id'] as String).toList();

      // Step 2: Fetch full room data with ALL members for those rooms
      final response = await _client
          .from('rooms')
          .select('*, room_members(user_id, role)')
          .inFilter('id', roomIds)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => RoomModel.fromJson(
                json as Map<String, dynamic>,
                currentUserId: userId,
              ))
          .toList();
    } on PostgrestException catch (e) {
      throw RoomRepositoryException('Failed to load rooms: ${e.message}');
    } catch (e) {
      if (e is RoomRepositoryException) rethrow;
      throw RoomRepositoryException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<RoomModel> getRoomById(String roomId) async {
    try {
      final userId = _currentUserId;

      final response = await _client
          .from('rooms')
          .select('*, room_members(user_id, role)')
          .eq('id', roomId)
          .single();

      return RoomModel.fromJson(response, currentUserId: userId);
    } on PostgrestException catch (e) {
      throw RoomRepositoryException('Failed to load room: ${e.message}');
    } catch (e) {
      if (e is RoomRepositoryException) rethrow;
      throw RoomRepositoryException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<RoomModel> createRoom({
    required String name,
    String? description,
  }) async {
    try {
      final userId = _currentUserId;

      // Generate a room code using the DB function
      final codeResponse = await _client.rpc('generate_room_code') as String;

      // Create the room
      final roomResponse = await _client
          .from('rooms')
          .insert({
            'name': name.trim(),
            'description': description?.trim(),
            'code': codeResponse,
            'created_by': userId,
          })
          .select()
          .single();

      final roomId = roomResponse['id'] as String;

      // Add creator as admin member
      await _client.from('room_members').insert({
        'room_id': roomId,
        'user_id': userId,
        'role': 'admin',
      });

      // Return the room with member data
      return await getRoomById(roomId);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Unique constraint violation on room code — retry with new code
        return createRoom(name: name, description: description);
      }
      throw RoomRepositoryException('Failed to create room: ${e.message}');
    } catch (e) {
      if (e is RoomRepositoryException) rethrow;
      throw RoomRepositoryException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<RoomModel> joinRoomByCode(String code) async {
    try {
      final userId = _currentUserId;

      // Find the room by code
      final roomResponse = await _client
          .from('rooms')
          .select('id')
          .eq('code', code.trim().toUpperCase())
          .maybeSingle();

      if (roomResponse == null) {
        throw RoomRepositoryException(
          'No room found with that code. Please check and try again.',
        );
      }

      final roomId = roomResponse['id'] as String;

      // Check if already a member
      final existingMember = await _client
          .from('room_members')
          .select('id')
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMember != null) {
        throw RoomRepositoryException('You are already a member of this room.');
      }

      // Join the room as a member
      await _client.from('room_members').insert({
        'room_id': roomId,
        'user_id': userId,
        'role': 'member',
      });

      return await getRoomById(roomId);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw RoomRepositoryException('You are already a member of this room.');
      }
      throw RoomRepositoryException('Failed to join room: ${e.message}');
    } catch (e) {
      if (e is RoomRepositoryException) rethrow;
      throw RoomRepositoryException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    try {
      final userId = _currentUserId;

      // Check if user is the only admin
      final admins = await _client
          .from('room_members')
          .select('id')
          .eq('room_id', roomId)
          .eq('role', 'admin');

      final isOnlyAdmin =
          (admins as List).length == 1 && await _isUserAdmin(roomId, userId);

      if (isOnlyAdmin) {
        // Check if there are other members
        final allMembers = await _client
            .from('room_members')
            .select('id')
            .eq('room_id', roomId);

        if ((allMembers as List).length > 1) {
          throw RoomRepositoryException(
            'You are the only admin. Please assign another admin before leaving, or delete the room.',
          );
        }

        // Only member left — delete the room entirely
        await _client.from('rooms').delete().eq('id', roomId);
        return;
      }

      // Leave the room
      await _client
          .from('room_members')
          .delete()
          .eq('room_id', roomId)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw RoomRepositoryException('Failed to leave room: ${e.message}');
    } catch (e) {
      if (e is RoomRepositoryException) rethrow;
      throw RoomRepositoryException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    try {
      final userId = _currentUserId;

      // Verify user is admin
      if (!await _isUserAdmin(roomId, userId)) {
        throw RoomRepositoryException('Only admins can delete a room.');
      }

      await _client.from('rooms').delete().eq('id', roomId);
    } on PostgrestException catch (e) {
      throw RoomRepositoryException('Failed to delete room: ${e.message}');
    } catch (e) {
      if (e is RoomRepositoryException) rethrow;
      throw RoomRepositoryException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<RoomModel> updateRoom({
    required String roomId,
    String? name,
    String? description,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name.trim();
      if (description != null) updates['description'] = description.trim();

      if (updates.isEmpty) {
        return await getRoomById(roomId);
      }

      await _client.from('rooms').update(updates).eq('id', roomId);
      return await getRoomById(roomId);
    } on PostgrestException catch (e) {
      throw RoomRepositoryException('Failed to update room: ${e.message}');
    } catch (e) {
      if (e is RoomRepositoryException) rethrow;
      throw RoomRepositoryException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<List<RoomMemberModel>> getRoomMembers(String roomId) async {
    try {
      final response = await _client
          .from('room_members')
          .select('*, profiles(username, display_name, avatar_url)')
          .eq('room_id', roomId)
          .order('joined_at');

      return (response as List)
          .map((json) => RoomMemberModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw RoomRepositoryException('Failed to load members: ${e.message}');
    } catch (e) {
      if (e is RoomRepositoryException) rethrow;
      throw RoomRepositoryException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> removeMember({
    required String roomId,
    required String userId,
  }) async {
    try {
      final currentUserId = _currentUserId;

      if (userId == currentUserId) {
        throw RoomRepositoryException('Use "Leave Room" instead to leave.');
      }

      if (!await _isUserAdmin(roomId, currentUserId)) {
        throw RoomRepositoryException('Only admins can remove members.');
      }

      await _client
          .from('room_members')
          .delete()
          .eq('room_id', roomId)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw RoomRepositoryException('Failed to remove member: ${e.message}');
    } catch (e) {
      if (e is RoomRepositoryException) rethrow;
      throw RoomRepositoryException('An unexpected error occurred: $e');
    }
  }

  /// Check if a user is an admin of a room
  Future<bool> _isUserAdmin(String roomId, String userId) async {
    final result = await _client
        .from('room_members')
        .select('role')
        .eq('room_id', roomId)
        .eq('user_id', userId)
        .maybeSingle();

    return result != null && result['role'] == 'admin';
  }
}
