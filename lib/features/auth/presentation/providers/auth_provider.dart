import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/api_providers.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../rooms/presentation/providers/room_provider.dart';
import '../../../challenges/presentation/providers/challenge_provider.dart';
import '../../../leaderboard/presentation/providers/leaderboard_provider.dart';

/// Auth repository backed by the REST API.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(apiClientProvider));
});

/// The session: the signed-in user's profile, or null when logged out.
/// This is the router's source of truth for authentication.
final authStateProvider =
    AsyncNotifierProvider<SessionNotifier, UserProfileModel?>(SessionNotifier.new);

class SessionNotifier extends AsyncNotifier<UserProfileModel?> {
  @override
  Future<UserProfileModel?> build() async {
    final api = ref.watch(apiClientProvider);
    // If a background refresh fails, drop to logged-out so the router redirects.
    api.onSessionExpired = () => state = const AsyncData(null);
    await api.loadSession();
    return ref.watch(authRepositoryProvider).getCurrentUserProfile();
  }

  void setUser(UserProfileModel user) => state = AsyncData(user);

  void clearUser() => state = const AsyncData(null);

  Future<void> refreshProfile() async {
    state = AsyncData(await ref.read(authRepositoryProvider).getCurrentUserProfile());
  }
}

/// The current signed-in user (null if logged out or still loading).
final currentUserProvider = Provider<UserProfileModel?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Re-fetchable profile for the profile screen; re-runs when the session changes.
final currentUserProfileProvider = FutureProvider<UserProfileModel?>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).getCurrentUserProfile();
});

final authLoadingProvider = StateProvider<bool>((ref) => false);
final authErrorProvider = StateProvider<String?>((ref) => null);

final authActionsProvider = Provider<AuthActions>((ref) => AuthActions(ref));

class AuthActions {
  final Ref _ref;
  AuthActions(this._ref);

  Future<void> signIn({required String email, required String password}) async {
    final repository = _ref.read(authRepositoryProvider);
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;
    try {
      final user = await repository.signInWithEmail(email: email, password: password);
      _ref.read(authStateProvider.notifier).setUser(user);
    } on AuthRepositoryException catch (e) {
      _ref.read(authErrorProvider.notifier).state = e.message;
      rethrow;
    } catch (e) {
      _ref.read(authErrorProvider.notifier).state = 'An unexpected error occurred';
      rethrow;
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  /// Returns true if email confirmation is required before signing in.
  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final repository = _ref.read(authRepositoryProvider);
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;
    try {
      return await repository.signUpWithEmail(
        email: email,
        password: password,
        username: username,
      );
    } on AuthRepositoryException catch (e) {
      _ref.read(authErrorProvider.notifier).state = e.message;
      rethrow;
    } catch (e) {
      _ref.read(authErrorProvider.notifier).state = 'An unexpected error occurred';
      rethrow;
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<void> signOut() async {
    final repository = _ref.read(authRepositoryProvider);
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;
    try {
      await repository.signOut();
      _ref.read(authStateProvider.notifier).clearUser();
      // Clear all user-specific cached data to prevent cross-user leaks.
      _ref.invalidate(currentUserProfileProvider);
      _ref.invalidate(userRoomsProvider);
      _ref.invalidate(challengeLoadingProvider);
      _ref.invalidate(challengeErrorProvider);
      _ref.invalidate(leaderboardTabProvider);
    } on AuthRepositoryException catch (e) {
      _ref.read(authErrorProvider.notifier).state = e.message;
      rethrow;
    } catch (e) {
      _ref.read(authErrorProvider.notifier).state = 'Failed to sign out';
      rethrow;
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<void> resendConfirmationEmail({required String email}) async {
    final repository = _ref.read(authRepositoryProvider);
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;
    try {
      await repository.resendConfirmationEmail(email: email);
    } on AuthRepositoryException catch (e) {
      _ref.read(authErrorProvider.notifier).state = e.message;
      rethrow;
    } catch (e) {
      _ref.read(authErrorProvider.notifier).state = 'Failed to resend confirmation email';
      rethrow;
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  void clearError() {
    _ref.read(authErrorProvider.notifier).state = null;
  }
}
