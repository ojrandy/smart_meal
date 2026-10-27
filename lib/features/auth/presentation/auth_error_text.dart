import '../../../core/l10n/l10n.dart';
import '../domain/auth_state.dart';

/// What the user reads for each [AuthErrorReason], in their language.
String authErrorText(AppLocalizations l10n, AuthErrorReason reason) =>
    switch (reason) {
      AuthErrorReason.noConnection => l10n.errorNoConnection,
      AuthErrorReason.invalidCredentials => l10n.authErrorInvalidCredentials,
      AuthErrorReason.emailExists => l10n.authErrorEmailExists,
      AuthErrorReason.weakPassword => l10n.authErrorWeakPassword,
      AuthErrorReason.emailNotConfirmed => l10n.authErrorEmailNotConfirmed,
      AuthErrorReason.tooManyAttempts => l10n.authErrorTooManyAttempts,
      AuthErrorReason.signupDisabled => l10n.authErrorSignupDisabled,
      AuthErrorReason.emailAddressInvalid => l10n.authErrorEmailAddressInvalid,
      AuthErrorReason.validationFailed => l10n.authErrorValidationFailed,
      AuthErrorReason.samePassword => l10n.authErrorSamePassword,
      AuthErrorReason.sessionExpired => l10n.authErrorSessionExpired,
      AuthErrorReason.userBanned => l10n.authErrorUserBanned,
      AuthErrorReason.googleSignInFailed => l10n.authErrorGoogleSignInFailed,
      AuthErrorReason.signOutFailed => l10n.authErrorSignOutFailed,
      AuthErrorReason.accountDeletionFailed =>
        l10n.authErrorAccountDeletionFailed,
      AuthErrorReason.generic => l10n.errorGeneric,
    };
