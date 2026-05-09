import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for Supabase client instance
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for Supabase Auth client
final supabaseAuthProvider = Provider<GoTrueClient>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth;
});

/// Provider for Supabase Storage client
final supabaseStorageProvider = Provider<SupabaseStorageClient>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.storage;
});
