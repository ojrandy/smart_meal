// SmartMeal — Supabase Configuration
//
// Every value here is a public identifier. Each one ships inside the app
// binary and is designed to be safe for clients to hold:
//   - project URL and publishable key: Supabase Dashboard → Settings → API Keys
//   - Google OAuth Web Client ID: Google Cloud Console → APIs & Services →
//     Credentials (also enable Supabase Dashboard → Auth → Providers → Google)
// Access control comes from Row Level Security, not from keeping these
// values hidden. They move to per-environment config in P07 (docs/prompt.md).
//
// Never put the secret / service-role key or any other secret here or
// anywhere else in the client. Secrets live only in server-side stores.

class SupabaseConfig {
  SupabaseConfig._(); // Prevent instantiation

  static const String projectUrl = 'https://svrelfdfonxwlfcljrag.supabase.co';

  static const String publishableKey =
      'sb_publishable_Ur6fIFyWtxKgubsnqk8ukA_FdsVCo4S';

  // Web Client ID — used as `serverClientId` in AuthRepository so the
  // native Google Sign-In SDK can request an ID token whose audience
  // Supabase will accept. Still needs a matching Android OAuth Client ID
  // (SHA-1) and iOS OAuth Client ID (Bundle ID) registered in Google
  // Cloud Console before native sign-in works on-device — see
  // context/progress-tracker.md.
  static const String googleWebClientId =
      '569732010135-d28ss0kahd0uo60prhn3rgf9m1in69rc.apps.googleusercontent.com';
}
