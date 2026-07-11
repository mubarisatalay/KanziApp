import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Profile actions class for updating user profile
class ProfileActions {
  final Ref _ref;

  ProfileActions(this._ref);

  /// Update current user's profile via the API, then refresh cached session/profile.
  Future<void> updateProfile({
    required String username,
    String? displayName,
  }) async {
    final repository = _ref.read(authRepositoryProvider);
    await repository.updateProfile(username: username, displayName: displayName);

    // Refresh the session user and the profile screen's provider.
    await _ref.read(authStateProvider.notifier).refreshProfile();
    _ref.invalidate(currentUserProfileProvider);
  }
}

/// Provider for profile actions
final profileActionsProvider = Provider<ProfileActions>((ref) {
  return ProfileActions(ref);
});
