import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/validation/field_error_text.dart';
import '../../../../core/validation/validators.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../domain/auth_notifier.dart';
import '../../domain/auth_state.dart';
import '../auth_error_text.dart';
import '../widgets/auth_screen_header.dart';

/// Sets a new password for the recovery session a reset link opened. The
/// router keeps a recovery session here until it succeeds; going back
/// signs out instead, which ends the recovery.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authNotifierProvider.notifier)
        .updatePassword(_passwordController.text);
  }

  // Leaving without a new password must not keep a recovery session around.
  Future<void> _cancel() async {
    FocusScope.of(context).unfocus();
    await ref.read(authNotifierProvider.notifier).signOut();
  }

  // ── Auth State Listener ────────────────────────────────────────────────────

  void _onAuthStateChanged(
    SmartMealAuthState? previous,
    SmartMealAuthState next,
  ) {
    if (!mounted) return;

    // The router moves on by itself once recovery ends.
    if (next is AuthPasswordUpdated) {
      showAppSnackBar(
        context,
        context.l10n.passwordUpdatedNotice,
        isError: false,
      );
    } else if (next is AuthError) {
      showAppSnackBar(context, authErrorText(context.l10n, next.reason));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SmartMealAuthState>(authNotifierProvider, _onAuthStateChanged);

    final isLoading = ref.watch(authNotifierProvider) is AuthLoading;
    final l10n = context.l10n;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isLoading) _cancel();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuthScreenHeader(
                    onBack: isLoading ? null : _cancel,
                    title: l10n.resetPasswordTitleLead,
                    highlight: l10n.resetPasswordTitleAccent,
                  ),
                  const SizedBox(height: 32),

                  CustomTextField(
                    label: l10n.newPasswordLabel,
                    prefixIcon: Iconsax.lock,
                    isPassword: true,
                    controller: _passwordController,
                    validator: (value) =>
                        fieldErrorText(l10n, validateNewPassword(value)),
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: l10n.confirmNewPasswordLabel,
                    prefixIcon: Iconsax.lock,
                    isPassword: true,
                    controller: _confirmController,
                    validator: (value) => fieldErrorText(
                      l10n,
                      validatePasswordConfirmation(
                        value,
                        _passwordController.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  CustomButton(
                    text: l10n.savePasswordButton,
                    onPressed: isLoading ? null : _save,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
