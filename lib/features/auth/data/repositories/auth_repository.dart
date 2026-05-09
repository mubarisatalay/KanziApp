import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';

/// Authentication repository interface
abstract class AuthRepository {
  /// Sign in with email and password
  Future<User> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign up with email, password, and username
  /// Returns a record with the user and whether email confirmation is required
  Future<({User user, bool emailConfirmationRequired})> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  });

  /// Resend confirmation email
  Future<void> resendConfirmationEmail({required String email});

  /// Sign out
  Future<void> signOut();

  /// Get current user
  User? getCurrentUser();

  /// Get current user profile
  Future<UserProfileModel?> getCurrentUserProfile();

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges;

  /// Check if user is authenticated
  bool get isAuthenticated;
}

/// Authentication repository implementation
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;

  AuthRepositoryImpl(this._client);

  @override
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        throw AuthRepositoryException('Failed to sign in');
      }

      // Ensure profile exists (handles users who signed up before trigger was set up,
      // or confirmed email and signing in for the first time)
      final username = response.user!.userMetadata?['username'] as String?;
      await _ensureProfileExists(
        userId: response.user!.id,
        username: username ?? 'user_${response.user!.id.substring(0, 8)}',
      );

      return response.user!;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } on AuthRepositoryException {
      rethrow;
    } catch (e) {
      throw AuthRepositoryException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<({User user, bool emailConfirmationRequired})> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Sign up the user with username in metadata
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'username': username.trim()},
      );

      if (response.user == null) {
        throw AuthRepositoryException('Failed to sign up');
      }

      // Detect fake signup: Supabase returns a user with empty identities
      // when the email is already registered (to prevent email enumeration)
      final identities = response.user!.identities;
      if (identities == null || identities.isEmpty) {
        throw AuthRepositoryException(
          'This email is already registered. Please sign in instead.',
        );
      }

      // If session is null, email confirmation is required
      final emailConfirmationRequired = response.session == null;

      // If we have an active session, ensure profile exists
      if (!emailConfirmationRequired) {
        await _ensureProfileExists(
          userId: response.user!.id,
          username: username.trim(),
        );
      }

      return (
        user: response.user!,
        emailConfirmationRequired: emailConfirmationRequired,
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } on AuthRepositoryException {
      rethrow;
    } catch (e) {
      throw AuthRepositoryException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> resendConfirmationEmail({required String email}) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthRepositoryException(
        'Failed to resend confirmation email: $e',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthRepositoryException('Failed to sign out: $e');
    }
  }

  @override
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  @override
  Future<UserProfileModel?> getCurrentUserProfile() async {
    try {
      final user = getCurrentUser();
      if (user == null) return null;

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return null;

      return UserProfileModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw AuthRepositoryException('Failed to fetch profile: ${e.message}');
    } catch (e) {
      throw AuthRepositoryException('An unexpected error occurred: $e');
    }
  }

  @override
  Stream<AuthState> get authStateChanges {
    return _client.auth.onAuthStateChange;
  }

  @override
  bool get isAuthenticated {
    return _client.auth.currentUser != null;
  }

  /// Ensure a profile exists for the given user.
  /// First checks via SELECT (allowed for everyone), then creates via RPC if missing.
  Future<void> _ensureProfileExists({
    required String userId,
    required String username,
  }) async {
    try {
      // Step 1: Check if profile already exists (SELECT is allowed for everyone)
      final existing = await _client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existing != null) return; // Profile already exists, nothing to do

      // Step 2: Profile doesn't exist — create it via RPC to bypass RLS
      try {
        await _client.rpc('ensure_profile_exists', params: {
          'user_id': userId,
          'user_name': username,
        });
      } catch (_) {
        // RPC not available, try direct insert as last resort
        try {
          await _client.from('profiles').insert({
            'id': userId,
            'username': username,
            'display_name': username,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {
          // Silently ignore — the trigger should handle this
        }
      }
    } catch (_) {
      // Non-critical: profile creation is best-effort from client side
    }
  }

  /// Handle auth exceptions and provide user-friendly messages
  AuthRepositoryException _handleAuthException(AuthException e) {
    final message = e.message.toLowerCase();

    if (message.contains('invalid login credentials') ||
        message.contains('invalid credentials')) {
      return AuthRepositoryException('Invalid email or password');
    }
    if (message.contains('rate limit') ||
        message.contains('rate_limit') ||
        message.contains('too many requests') ||
        message.contains('exceeded')) {
      return AuthRepositoryException(
        'Too many attempts. Please wait a few minutes before trying again.',
      );
    }
    if (message.contains('user already registered')) {
      return AuthRepositoryException('This email is already registered');
    }
    if (message.contains('email not confirmed')) {
      return AuthRepositoryException('Please verify your email address');
    }
    if (message.contains('weak password') ||
        message.contains('low security') ||
        message.contains('password') && message.contains('strength') ||
        message.contains('password should contain') ||
        message.contains('password is too')) {
      return AuthRepositoryException(
        'Password is too weak. Use at least 8 characters with uppercase, lowercase, numbers, and special characters.',
      );
    }
    if (message.contains('row-level security') ||
        message.contains('row level security') ||
        message.contains('policy')) {
      return AuthRepositoryException(
        'Unable to create your profile. Please try again or contact support.',
      );
    }
    if (message.contains('unique') ||
        message.contains('already exists') ||
        message.contains('23505')) {
      return AuthRepositoryException('Username already exists');
    }

    return AuthRepositoryException(e.message);
  }
}

/// Custom exception for authentication errors
class AuthRepositoryException implements Exception {
  final String message;

  AuthRepositoryException(this.message);

  @override
  String toString() => message;
}
