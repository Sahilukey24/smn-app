/// Supabase configuration. No secrets in code.
///
/// Provide at runtime via:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
/// Or set [SupabaseConfig.supabaseUrl] and [SupabaseConfig.supabaseAnonKey]
/// before calling [Supabase.initialize] (e.g. from a remote config or env file).
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '', // Set by user before production
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '', // Set by user before production
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
