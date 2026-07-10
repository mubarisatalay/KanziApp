import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/user_profile_model.dart';

/// Custom exception for authentication errors.
class AuthRepositoryException implements Exception {
  final String message;
  AuthRepositoryException(this.message);

  @override
  String toString() => message;
}

/// Authentication repository interface (client-agnostic; no transport types leak out).
abstract class AuthRepository {
  /// Sign in; on success the session tokens are stored and the profile returned.
  Future<UserProfileModel> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign up. Returns whether email confirmation is required before signing in.
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  });

  Future<void> resendConfirmationEmail({required String email});

  Future<void> signOut();

  /// The current user's profile, or null if there is no valid session.
  Future<UserProfileModel?> getCurrentUserProfile();

  Future<UserProfileModel> updateProfile({
    required String username,
    String? displayName,
  });

  bool get isAuthenticated;
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api);

  final ApiClient _api;
  Dio get _dio => _api.dio;

  @override
  bool get isAuthenticated => _api.hasSession;

  @override
  Future<UserProfileModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': email.trim(),
        'password': password,
      });
      final data = res.data as Map<String, dynamic>;
      await _api.setSession(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return UserProfileModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthRepositoryException(messageFromDioError(e, 'Failed to sign in'));
    }
  }

  @override
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final res = await _dio.post('/auth/signup', data: {
        'email': email.trim(),
        'password': password,
        'username': username.trim(),
      });
      final data = res.data as Map<String, dynamic>;
      return data['emailConfirmationRequired'] as bool? ?? true;
    } on DioException catch (e) {
      throw AuthRepositoryException(messageFromDioError(e, 'Failed to sign up'));
    }
  }

  @override
  Future<void> resendConfirmationEmail({required String email}) async {
    try {
      await _dio.post('/auth/resend-verification', data: {'email': email.trim()});
    } on DioException catch (e) {
      throw AuthRepositoryException(
          messageFromDioError(e, 'Failed to resend confirmation email'));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      final refresh = _api.refreshToken;
      if (refresh != null) {
        await _dio.post('/auth/logout', data: {'refreshToken': refresh});
      }
    } catch (_) {
      // Best-effort; we clear the local session regardless.
    } finally {
      await _api.clearSession();
    }
  }

  @override
  Future<UserProfileModel?> getCurrentUserProfile() async {
    if (!_api.hasSession) return null;
    try {
      final res = await _dio.get('/auth/me');
      return UserProfileModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _api.clearSession();
        return null;
      }
      throw AuthRepositoryException(messageFromDioError(e, 'Failed to fetch profile'));
    }
  }

  @override
  Future<UserProfileModel> updateProfile({
    required String username,
    String? displayName,
  }) async {
    try {
      final res = await _dio.patch('/auth/me', data: {
        'username': username.trim(),
        if (displayName != null) 'displayName': displayName.trim(),
      });
      return UserProfileModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthRepositoryException(messageFromDioError(e, 'Failed to update profile'));
    }
  }
}
