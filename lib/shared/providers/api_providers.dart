import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/token_store.dart';

/// Secure token storage.
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

/// Shared HTTP client for the whole app. Owns the JWT session lifecycle.
final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStore = ref.watch(tokenStoreProvider);
  return ApiClient(baseUrl: ApiConstants.baseUrl, tokenStore: tokenStore);
});
