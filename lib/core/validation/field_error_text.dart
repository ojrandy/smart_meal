import '../l10n/l10n.dart';
import 'validators.dart';

/// [error] in the user's language, or null when the field is valid, as
/// `TextFormField.validator` expects:
/// `validator: (v) => fieldErrorText(l10n, validateEmail(v))`.
String? fieldErrorText(AppLocalizations l10n, FieldError? error) =>
    switch (error) {
      null => null,
      FieldError.emailMissing => l10n.fieldEmailMissing,
      FieldError.emailInvalid => l10n.fieldEmailInvalid,
      FieldError.passwordMissing => l10n.fieldPasswordMissing,
      FieldError.newPasswordMissing => l10n.fieldNewPasswordMissing,
      FieldError.passwordTooShort => l10n.fieldPasswordTooShort(
        minPasswordLength,
      ),
      FieldError.passwordTooLong => l10n.fieldPasswordTooLong,
      FieldError.passwordTooSimple => l10n.fieldPasswordTooSimple,
      FieldError.confirmationMissing => l10n.fieldConfirmationMissing,
      FieldError.confirmationMismatch => l10n.fieldConfirmationMismatch,
    };
