import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/room_model.dart';
import '../../data/models/room_member_model.dart';
import '../../data/repositories/room_repository.dart';

/// Provider for room repository
final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RoomRepositoryImpl(client);
});

/// Provider for user's rooms list — depends on currentUserProvider
/// so it auto-refreshes when the auth user changes (login/logout/switch)
final userRoomsProvider = FutureProvider<List<RoomModel>>((ref) async {
  // Watch the current user — if it changes, this provider re-runs
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repository = ref.watch(roomRepositoryProvider);
  return repository.getUserRooms();
});

/// Provider for a single room by ID
final roomByIdProvider =
    FutureProvider.family<RoomModel, String>((ref, roomId) async {
  final repository = ref.watch(roomRepositoryProvider);
  return repository.getRoomById(roomId);
});

/// Provider for room members
final roomMembersProvider =
    FutureProvider.family<List<RoomMemberModel>, String>((ref, roomId) async {
  final repository = ref.watch(roomRepositoryProvider);
  return repository.getRoomMembers(roomId);
});

/// Provider for room loading state
final roomLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider for room error message
final roomErrorProvider = StateProvider<String?>((ref) => null);

/// Room actions class
class RoomActions {
  final Ref _ref;

  RoomActions(this._ref);

  /// Create a new room
  Future<RoomModel> createRoom({
    required String name,
    String? description,
  }) async {
    final repository = _ref.read(roomRepositoryProvider);
    _ref.read(roomLoadingProvider.notifier).state = true;
    _ref.read(roomErrorProvider.notifier).state = null;

    try {
      final room = await repository.createRoom(
        name: name,
        description: description,
      );
      // Refresh the rooms list
      _ref.invalidate(userRoomsProvider);
      return room;
    } on RoomRepositoryException catch (e) {
      _ref.read(roomErrorProvider.notifier).state = e.message;
      rethrow;
    } catch (e) {
      _ref.read(roomErrorProvider.notifier).state = 'Failed to create room';
      rethrow;
    } finally {
      _ref.read(roomLoadingProvider.notifier).state = false;
    }
  }

  /// Join a room by code
  Future<RoomModel> joinRoom(String code) async {
    final repository = _ref.read(roomRepositoryProvider);
    _ref.read(roomLoadingProvider.notifier).state = true;
    _ref.read(roomErrorProvider.notifier).state = null;

    try {
      final room = await repository.joinRoomByCode(code);
      _ref.invalidate(userRoomsProvider);
      return room;
    } on RoomRepositoryException catch (e) {
      _ref.read(roomErrorProvider.notifier).state = e.message;
      rethrow;
    } catch (e) {
      _ref.read(roomErrorProvider.notifier).state = 'Failed to join room';
      rethrow;
    } finally {
      _ref.read(roomLoadingProvider.notifier).state = false;
    }
  }

  /// Leave a room
  Future<void> leaveRoom(String roomId) async {
    final repository = _ref.read(roomRepositoryProvider);
    _ref.read(roomLoadingProvider.notifier).state = true;
    _ref.read(roomErrorProvider.notifier).state = null;

    try {
      await repository.leaveRoom(roomId);
      _ref.invalidate(userRoomsProvider);
    } on RoomRepositoryException catch (e) {
      _ref.read(roomErrorProvider.notifier).state = e.message;
      rethrow;
    } catch (e) {
      _ref.read(roomErrorProvider.notifier).state = 'Failed to leave room';
      rethrow;
    } finally {
      _ref.read(roomLoadingProvider.notifier).state = false;
    }
  }

  /// Delete a room
  Future<void> deleteRoom(String roomId) async {
    final repository = _ref.read(roomRepositoryProvider);
    _ref.read(roomLoadingProvider.notifier).state = true;
    _ref.read(roomErrorProvider.notifier).state = null;

    try {
      await repository.deleteRoom(roomId);
      _ref.invalidate(userRoomsProvider);
    } on RoomRepositoryException catch (e) {
      _ref.read(roomErrorProvider.notifier).state = e.message;
      rethrow;
    } catch (e) {
      _ref.read(roomErrorProvider.notifier).state = 'Failed to delete room';
      rethrow;
    } finally {
      _ref.read(roomLoadingProvider.notifier).state = false;
    }
  }

  /// Remove a member from a room
  Future<void> removeMember({
    required String roomId,
    required String userId,
  }) async {
    final repository = _ref.read(roomRepositoryProvider);
    _ref.read(roomLoadingProvider.notifier).state = true;
    _ref.read(roomErrorProvider.notifier).state = null;

    try {
      await repository.removeMember(roomId: roomId, userId: userId);
      _ref.invalidate(roomMembersProvider(roomId));
    } on RoomRepositoryException catch (e) {
      _ref.read(roomErrorProvider.notifier).state = e.message;
      rethrow;
    } catch (e) {
      _ref.read(roomErrorProvider.notifier).state = 'Failed to remove member';
      rethrow;
    } finally {
      _ref.read(roomLoadingProvider.notifier).state = false;
    }
  }

  /// Clear error
  void clearError() {
    _ref.read(roomErrorProvider.notifier).state = null;
  }

  /// Refresh rooms list
  void refreshRooms() {
    _ref.invalidate(userRoomsProvider);
  }
}

/// Provider for room actions
final roomActionsProvider = Provider<RoomActions>((ref) {
  return RoomActions(ref);
});
