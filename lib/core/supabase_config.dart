/// Supabase configuration for GABAY
///
/// Set your Supabase URL and anon key here, or use dart-define:
/// flutter run --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_ANON_KEY=xxx
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://pttvxcsrgljcvvfdplrw.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_b6outFkUxt9LQ_xIfUrXog_nTubIZag',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
