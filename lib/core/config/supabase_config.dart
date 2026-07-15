// SmartMeal — Supabase Configuration
//
// ─────────────────────────────────────────────────────────────────
// SETUP INSTRUCTIONS:
//
// 1. Go to https://supabase.com and create a project.
// 2. Navigate to: Settings → API
// 3. Copy "Project URL"      → paste into [SupabaseConfig.projectUrl]
// 4. Copy "anon / public" key → paste into [SupabaseConfig.anonKey]
// 5. For Google Sign-In:
//    - Go to Google Cloud Console → APIs & Services → Credentials
//    - Create an OAuth 2.0 Web Client ID
//    - Paste the client ID into [SupabaseConfig.googleWebClientId]
//    - Enable the Google provider: Supabase Dashboard → Auth → Providers → Google
//
// ⚠️  NEVER commit real credentials to version control.
//     Use --dart-define or a secrets manager in CI/CD.
// ─────────────────────────────────────────────────────────────────

class SupabaseConfig {
  SupabaseConfig._(); // Prevent instantiation

  // TODO: Replace with your Supabase Project URL
  // Example: 'https://abcdefghijklmn.supabase.co'
  static const String projectUrl = 'https://YOUR_PROJECT_ID.supabase.co';

  // TODO: Replace with your Supabase anon/public key
  // This is safe to include in client code — it is intentionally public.
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';

  // TODO: Replace with your Google OAuth Web Client ID
  // Required for Google Sign-In on Android & iOS via Supabase.
  // Find at: console.cloud.google.com → APIs & Services → Credentials
  static const String googleWebClientId =
      'YOUR_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com';
}
