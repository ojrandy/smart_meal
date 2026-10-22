import 'dart:convert';

/// Form validators shared by every screen. Each returns null when the value
/// is valid, or a user-facing message, so they plug straight into
/// `TextFormField.validator`. The server stays the authority: these only
/// catch mistakes early.

/// RFC 5321 caps a whole address at 254 characters.
const maxEmailLength = 254;

/// Supabase Auth hashes passwords with bcrypt, which reads at most 72 bytes.
const maxPasswordBytes = 72;

const minPasswordLength = 8;

// Pragmatic on purpose: one @, no spaces, a dot in the domain and a TLD of
// two or more characters. Accepts plus-addressing and long TLDs.
final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@.]{2,}$');

// The symbol set Supabase Auth checks for its "digits, lowercase, uppercase
// and symbols" requirement, so the client never accepts what it rejects.
final _symbolPattern = RegExp(r'''[!@#$%^&*()_+\-=\[\]{};'\\:"|<>?,./`~]''');

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Please enter your email';
  if (email.length > maxEmailLength || !_emailPattern.hasMatch(email)) {
    return 'Please enter a valid email';
  }
  return null;
}

/// Sign-up and password-change policy, matching the Supabase project
/// setting recorded in docs/SECURITY.md §5.
String? validateNewPassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Please enter a password';
  if (password.length < minPasswordLength) {
    return 'Password must be at least $minPasswordLength characters';
  }
  if (utf8.encode(password).length > maxPasswordBytes) {
    return 'Password is too long';
  }
  final hasEveryClass =
      password.contains(RegExp('[a-z]')) &&
      password.contains(RegExp('[A-Z]')) &&
      password.contains(RegExp('[0-9]')) &&
      password.contains(_symbolPattern);
  if (!hasEveryClass) {
    return 'Use upper- and lowercase letters, a number and a symbol';
  }
  return null;
}

/// Sign-in only checks that something was typed: the creation policy may
/// change, and existing accounts must still get in.
String? validateLoginPassword(String? value) {
  if (value == null || value.isEmpty) return 'Please enter your password';
  return null;
}

String? validatePasswordConfirmation(String? value, String password) {
  if (value == null || value.isEmpty) return 'Please confirm your password';
  if (value != password) return 'Passwords do not match';
  return null;
}
