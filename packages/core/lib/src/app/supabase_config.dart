/// Client configuration supplied at build time via --dart-define.
/// The anon key is safe to ship; it is guarded by RLS.
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
