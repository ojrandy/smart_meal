import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_meal/core/l10n/l10n.dart';
import 'package:smart_meal/core/validation/field_error_text.dart';
import 'package:smart_meal/core/validation/validators.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final fr = lookupAppLocalizations(const Locale('fr'));

  test('keeps the approved English messages', () {
    expect(fieldErrorText(en, null), isNull);
    expect(
      fieldErrorText(en, FieldError.emailInvalid),
      'Please enter a valid email',
    );
    expect(
      fieldErrorText(en, FieldError.newPasswordMissing),
      'Please enter a password',
    );
    expect(
      fieldErrorText(en, FieldError.passwordMissing),
      'Please enter your password',
    );
    expect(
      fieldErrorText(en, FieldError.passwordTooShort),
      'Password must be at least $minPasswordLength characters',
    );
    expect(
      fieldErrorText(en, FieldError.confirmationMismatch),
      "Passwords don't match",
    );
  });

  test('every error has distinct French text', () {
    final french = {
      for (final error in FieldError.values) fieldErrorText(fr, error),
    };
    expect(french, hasLength(FieldError.values.length));
    expect(
      fieldErrorText(fr, FieldError.passwordTooShort),
      contains('$minPasswordLength'),
    );
  });
}
