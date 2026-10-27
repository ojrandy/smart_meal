import 'dart:convert';

/// Form validators shared by every screen. Each returns null when the value
/// is valid, or the [FieldError] found; `fieldErrorText` words it in the
/// user's language for `TextFormField.validator`. The server stays the
/// authority: these only catch mistakes early.

/// What is wrong with a form field.
enum FieldError {
  emailMissing,
  emailInvalid,
  passwordMissing,
  newPasswordMissing,
  passwordTooShort,
  passwordTooLong,
  passwordTooSimple,
  confirmationMissing,
  confirmationMismatch,
}

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

FieldError? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return FieldError.emailMissing;
  if (email.length > maxEmailLength || !_emailPattern.hasMatch(email)) {
    return FieldError.emailInvalid;
  }
  return null;
}

/// Sign-up and password-change policy, matching the Supabase project
/// setting recorded in docs/SECURITY.md §5.
FieldError? validateNewPassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return FieldError.newPasswordMissing;
  if (password.length < minPasswordLength) {
    return FieldError.passwordTooShort;
  }
  if (utf8.encode(password).length > maxPasswordBytes) {
    return FieldError.passwordTooLong;
  }
  final hasEveryClass =
      password.contains(RegExp('[a-z]')) &&
      password.contains(RegExp('[A-Z]')) &&
      password.contains(RegExp('[0-9]')) &&
      password.contains(_symbolPattern);
  if (!hasEveryClass) {
    return FieldError.passwordTooSimple;
  }
  return null;
}

/// Sign-in only checks that something was typed: the creation policy may
/// change, and existing accounts must still get in.
FieldError? validateLoginPassword(String? value) {
  if (value == null || value.isEmpty) return FieldError.passwordMissing;
  return null;
}

FieldError? validatePasswordConfirmation(String? value, String password) {
  if (value == null || value.isEmpty) return FieldError.confirmationMissing;
  if (value != password) return FieldError.confirmationMismatch;
  return null;
}
