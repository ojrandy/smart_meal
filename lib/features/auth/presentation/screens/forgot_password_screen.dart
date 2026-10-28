import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

/// Requests a password reset email. Whatever the account state, a request
/// that reaches Supabase gets the same neutral confirmation, so the screen
/// never reveals whether an email is registered.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  /// Matches Supabase's default minimum interval between emails to one
  /// address, so a resend tapped as soon as it is offered goes through.
  static const resendCooldown = Duration(seconds: 60);

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _sent = false;
  int _secondsLeft = 0;
  Timer? _cooldown;

  @override
  void dispose() {
    _cooldown?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authNotifierProvider.notifier)
        .resetPassword(_emailController.text.trim());
  }

  void _startCooldown() {
    _cooldown?.cancel();
    setState(
      () => _secondsLeft = ForgotPasswordScreen.resendCooldown.inSeconds,
    );
    _cooldown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  // After context.go there is nothing to pop, so fall back to sign-in.
  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/auth/login');
    }
  }

  // ── Auth State Listener ────────────────────────────────────────────────────

  void _onAuthStateChanged(
    SmartMealAuthState? previous,
    SmartMealAuthState next,
  ) {
    if (!mounted) return;

    if (next is AuthResetEmailSent) {
      setState(() => _sent = true);
      _startCooldown();
    } else if (next is AuthError) {
      showAppSnackBar(context, authErrorText(context.l10n, next.reason));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SmartMealAuthState>(authNotifierProvider, _onAuthStateChanged);

    final isLoading = ref.watch(authNotifierProvider) is AuthLoading;
    final isCoolingDown = _secondsLeft > 0;
    final l10n = context.l10n;

    final String buttonText;
    if (!_sent) {
      buttonText = l10n.sendResetLinkButton;
    } else if (isCoolingDown) {
      buttonText = l10n.resendInSeconds(_secondsLeft);
    } else {
      buttonText = l10n.resendLinkButton;
    }

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
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
                    onBack: _goBack,
                    title: l10n.forgotPasswordTitleLead,
                    highlight: l10n.forgotPasswordTitleAccent,
                    subtitle: l10n.forgotPasswordSubtitle,
                  ),
                  const SizedBox(height: 32),

                  CustomTextField(
                    label: l10n.emailLabel,
                    prefixIcon: Iconsax.sms,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        fieldErrorText(l10n, validateEmail(value)),
                  ),
                  const SizedBox(height: 24),

                  if (_sent) ...[
                    // Announced to screen readers when it appears.
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Iconsax.sms_tracking,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.resetEmailSentNotice,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  CustomButton(
                    text: buttonText,
                    onPressed: isLoading || isCoolingDown ? null : _send,
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
