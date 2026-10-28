import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';

/// A styled text field that integrates with Flutter's [Form] widget
/// via the optional [validator] parameter.
///
/// Wraps a [TextFormField] inside a custom-styled container.
class CustomTextField extends StatefulWidget {
  final String label;
  final IconData prefixIcon;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType keyboardType;

  /// Optional validator for use inside a [Form]. Returns an error string
  /// or null if the value is valid.
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.label,
    required this.prefixIcon,
    this.isPassword = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final field = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(widget.prefixIcon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // TextFormField allows participation in the Form validation chain.
                TextFormField(
                  controller: widget.controller,
                  obscureText: _obscureText,
                  keyboardType: widget.keyboardType,
                  validator: widget.validator,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    errorStyle: TextStyle(color: AppColors.error, fontSize: 11),
                  ),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Keeps the 24 dp icon slot; the toggle is laid over it below so its
          // 48 dp touch target does not make the field taller.
          if (widget.isPassword) ...[
            const SizedBox(width: 8),
            const SizedBox(width: 24, height: 24),
          ],
        ],
      ),
    );

    if (!widget.isPassword) return field;

    return Stack(
      children: [
        field,
        Positioned(
          top: 0,
          bottom: 0,
          // Centres the 48 dp button on the slot: 1.5 border + 16 padding +
          // 12 half-icon - 24 half-button.
          right: 5.5,
          child: Center(
            child: IconButton(
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
              icon: Icon(
                _obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
                size: 24,
                semanticLabel: _obscureText
                    ? context.l10n.showPasswordLabel
                    : context.l10n.hidePasswordLabel,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
