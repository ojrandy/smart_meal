import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

/// `context.l10n.someKey`: the UI text for the language on screen. Every
/// user-facing string comes from here (keys in `app_en.arb`, French in
/// `app_fr.arb`); never a literal in a widget.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
