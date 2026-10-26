import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// How a [ChoiceTile] shows its state.
enum ChoiceMark { none, selected, rejected }

/// A full-width answer card: label, optional hint, and a check (or cross)
/// when chosen. At least 56 dp tall, announced to screen readers as a
/// selectable button with its state.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    this.hint,
    required this.mark,
    required this.onTap,
    this.markLabel,
  });

  final String label;
  final String? hint;
  final ChoiceMark mark;
  final VoidCallback onTap;

  /// Extra words for the state, e.g. "Like" — shown and announced.
  final String? markLabel;

  @override
  Widget build(BuildContext context) {
    final isOn = mark != ChoiceMark.none;
    final accent = mark == ChoiceMark.rejected
        ? AppColors.error
        : AppColors.primary;

    return Semantics(
      button: true,
      selected: isOn,
      label: [label, ?hint, ?markLabel].join(', '),
      excludeSemantics: true,
      child: Material(
        color: isOn ? accent.withValues(alpha: 0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOn ? accent : AppColors.surfaceVariant,
                width: isOn ? 2 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (hint case final hint?) ...[
                        const SizedBox(height: 2),
                        Text(
                          hint,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (markLabel case final markLabel?) ...[
                  const SizedBox(width: 8),
                  Text(
                    markLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                Icon(
                  switch (mark) {
                    ChoiceMark.none => Icons.circle_outlined,
                    ChoiceMark.selected => Icons.check_circle_rounded,
                    ChoiceMark.rejected => Icons.cancel_rounded,
                  },
                  color: isOn ? accent : AppColors.textHint,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
