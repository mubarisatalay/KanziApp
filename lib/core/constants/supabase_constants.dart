/// Supabase configuration constants
/// These credentials are safe to expose in client-side code (anon key only)
class SupabaseConstants {
  SupabaseConstants._();

  /// Supabase project URL
  static const String supabaseUrl = 'https://euiktyguherpcjziaxya.supabase.co';

  /// Supabase anonymous/public key (safe for client-side use)
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV1aWt0eWd1aGVycGNqemlheHlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxMzgwMDYsImV4cCI6MjA4NTcxNDAwNn0.rvbKOUxxodhkmU8oRzggyvogcQmd64kgHVfQUQ-_xGI';

  /// Storage bucket name for challenge images
  static const String imagesBucket = 'challenge-images';
}
