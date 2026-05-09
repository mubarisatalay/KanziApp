import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Profile actions class for updating user profile
class ProfileActions {
  final Ref _ref;

  ProfileActions(this._ref);

  /// Update current user's profile
  Future<void> updateProfile({
    required String username,
    String? displayName,
  }) async {
    final client = _ref.read(supabaseClientProvider);
    final currentUser = _ref.read(currentUserProvider);

    if (currentUser == null) {
      throw Exception('Not authenticated');
    }

    try {
      await client.from('profiles').update({
        'username': username,
        'display_name': displayName ?? username,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', currentUser.id);

      // Refresh the profile
      _ref.invalidate(currentUserProfileProvider);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}

/// Provider for profile actions
final profileActionsProvider = Provider<ProfileActions>((ref) {
  return ProfileActions(ref);
});
