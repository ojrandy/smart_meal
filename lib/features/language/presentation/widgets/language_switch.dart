import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/app_language.dart';

/// Compact EN | FR switch. Shows the language on screen now (the phone's,
/// until the user picks one) and remembers a pick. Each language is named
/// in itself, so anyone can find theirs whatever the current language.
class LanguageSwitch extends ConsumerWidget {
  const LanguageSwitch({super.key});

  static const _names = {
    AppLanguage.english: 'English',
    AppLanguage.french: 'Français',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current =
        AppLanguage.fromCode(Localizations.localeOf(context).languageCode) ??
        AppLanguage.english;

    return Semantics(
      container: true,
      label: context.l10n.languageSwitchLabel,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final language in AppLanguage.values)
              _Option(
                code: language.code.toUpperCase(),
                name: _names[language]!,
                selected: language == current,
                onTap: () =>
                    ref.read(appLanguageProvider.notifier).choose(language),
              ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.code,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          // 48 dp tall with the container's padding: a full tap target.
          constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            code,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
