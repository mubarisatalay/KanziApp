import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../rooms/presentation/providers/room_provider.dart';
import '../../../challenges/presentation/providers/challenge_provider.dart';
import '../../../leaderboard/presentation/providers/leaderboard_provider.dart';

/// Provider for auth repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepositoryImpl(client);
});

/// Provider for auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges.map((state) => state.session?.user);
});

/// Provider for current user
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider for current user profile — depends on currentUserProvider
/// so it auto-refreshes when the auth user changes (login/logout/switch)
final currentUserProfileProvider =
    FutureProvider<UserProfileModel?>((ref) async {
  // Watch the current user — if it changes, this provider re-runs
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final repository = ref.watch(authRepositoryProvider);
  return await repository.getCurrentUserProfile();
});

/// Provider for auth loading state
final authLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider for auth error message
final authErrorProvider = StateProvider<String?>((ref) => null);

/// Auth actions provider
final authActionsProvider = Provider<AuthActions>((ref) {
  return AuthActions(ref);
});

/// Auth actions class
class AuthActions {
  final Ref _ref;

  AuthActions(this._ref);

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final repository = _ref.read(authRepositoryProvider);
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      await repository.signInWithEmail(
        email: email,
        password: password,
      );
    } on AuthRepositoryException catch (e) {
      _ref.read(authErrorProvider.notifier).state = e.message;
      rethrow;
    } catch (e) {
      _ref.read(authErrorProvider.notifier).state =
          'An unexpected error occurred';
      rethrow;
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  /// Sign up with email, password, and username
  /// Returns true if email confirmation is required
  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final repository = _ref.read(authRepositoryProvider);
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      final result = await repository.signUpWithEmail(
        email: email,
        password: password,
        username: username,
      );
      return result.emailConfirmationRequired;
    } on AuthRepositoryException catch (e) {
      _ref.read(authErrorProvider.notifier).state = e.message;
      rethrow;
    } catch (e) {
      _ref.read(authErrorProvider.notifier).state =
          'An unexpected error occurred';
      rethrow;
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  /// Sign out — invalidates ALL user-specific providers to prevent
  /// stale data from showing when a different user signs in.
  Future<void> signOut() async {
    final repository = _ref.read(authRepositoryProvider);
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      await repository.signOut();

      // Clear ALL user-specific cached data to prevent cross-user data leaks
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

  /// Resend confirmation email
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
      _ref.read(authErrorProvider.notifier).state =
          'Failed to resend confirmation email';
      rethrow;
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  /// Clear error
  void clearError() {
    _ref.read(authErrorProvider.notifier).state = null;
  }
}
