import 'package:dio/dio.dart';

import 'token_store.dart';

/// Extracts the server's error message ({"message": ...}) from a DioException,
/// falling back to a caller-supplied default.
String messageFromDioError(DioException e, String fallback) {
  final data = e.response?.data;
  if (data is Map && data['message'] is String) {
    return data['message'] as String;
  }
  return fallback;
}

/// Thin wrapper around Dio that owns the JWT session lifecycle:
/// attaches the bearer token, transparently refreshes on 401, and persists
/// tokens via [TokenStore].
class ApiClient {
  ApiClient({required String baseUrl, required TokenStore tokenStore})
      : _tokenStore = tokenStore,
        dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null && !options.headers.containsKey('Authorization')) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        final isAuthPath = e.requestOptions.path.startsWith('/auth/');
        final alreadyRetried = e.requestOptions.extra['__retried__'] == true;
        if (e.response?.statusCode == 401 &&
            !isAuthPath &&
            !alreadyRetried &&
            _refreshToken != null) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            try {
              return handler.resolve(await _retry(e.requestOptions));
            } on DioException catch (err) {
              return handler.next(err);
            }
          }
          await clearSession();
          onSessionExpired?.call();
        }
        handler.next(e);
      },
    ));
  }

  final Dio dio;
  final TokenStore _tokenStore;

  String? _accessToken;
  String? _refreshToken;

  /// Invoked when a refresh fails and the session can no longer be recovered.
  void Function()? onSessionExpired;

  String? get refreshToken => _refreshToken;
  bool get hasSession => _accessToken != null;

  /// Load any persisted tokens into memory (call once at startup).
  Future<void> loadSession() async {
    final tokens = await _tokenStore.read();
    _accessToken = tokens.access;
    _refreshToken = tokens.refresh;
  }

  Future<void> setSession({required String accessToken, required String refreshToken}) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _tokenStore.save(accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<void> clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    await _tokenStore.clear();
  }

  Future<bool> _tryRefresh() async {
    try {
      // A bare Dio avoids recursing back through this interceptor.
      final bare = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
      final res = await bare.post('/auth/refresh', data: {'refreshToken': _refreshToken});
      final data = res.data as Map<String, dynamic>;
      await setSession(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions o) {
    return dio.request(
      o.path,
      data: o.data,
      queryParameters: o.queryParameters,
      options: Options(
        method: o.method,
        headers: {...o.headers, 'Authorization': 'Bearer $_accessToken'},
        extra: {...o.extra, '__retried__': true},
        contentType: o.contentType,
        responseType: o.responseType,
      ),
    );
  }
}
