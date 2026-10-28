import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/auth_notifier.dart';
import '../../domain/auth_state.dart';
import '../auth_error_text.dart';
import 'forgot_password_screen.dart';

/// Shown after an email sign-up while the confirmation email is on its way
/// (owner request, 2026-10-27): an animated envelope, where the link went,
/// a short introduction to Smart Meal, and a resend button with a cooldown.
///
/// Supabase answers the same way for an address that is already registered,
/// so nothing here claims the account is new. Opening the link on this phone
/// signs the user in, and the router then leaves this screen by itself.
class CheckEmailScreen extends ConsumerStatefulWidget {
  const CheckEmailScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends ConsumerState<CheckEmailScreen> {
  int _secondsLeft = 0;
  Timer? _cooldown;

  @override
  void initState() {
    super.initState();
    // The first email just went out: same wait as before a resend.
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldown?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldown?.cancel();
    _secondsLeft = ForgotPasswordScreen.resendCooldown.inSeconds;
    _cooldown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _resend() => ref
      .read(authNotifierProvider.notifier)
      .resendSignupConfirmation(widget.email);

  void _backToSignIn() => context.go('/auth/login');

  void _onAuthStateChanged(
    SmartMealAuthState? previous,
    SmartMealAuthState next,
  ) {
    if (!mounted || previous is! AuthLoading) return;

    if (next is AuthAwaitingEmailConfirmation) {
      setState(_startCooldown);
      showAppSnackBar(context, context.l10n.checkEmailResent, isError: false);
    } else if (next is AuthError) {
      showAppSnackBar(context, authErrorText(context.l10n, next.reason));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SmartMealAuthState>(authNotifierProvider, _onAuthStateChanged);

    final isLoading = ref.watch(authNotifierProvider) is AuthLoading;
    final isCoolingDown = _secondsLeft > 0;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final l10n = context.l10n;

    final perks = [
      (
        Iconsax.reserve,
        l10n.checkEmailPerkTasteTitle,
        l10n.checkEmailPerkTasteBody,
      ),
      (
        Iconsax.wallet_3,
        l10n.checkEmailPerkBudgetTitle,
        l10n.checkEmailPerkBudgetBody,
      ),
      (
        Iconsax.heart,
        l10n.checkEmailPerkHealthTitle,
        l10n.checkEmailPerkHealthBody,
      ),
    ];

    Widget enter(Widget child, int order) => reduceMotion
        ? child
        : child
              .animate(delay: (150 * order).ms)
              .fadeIn(duration: 450.ms)
              .slideY(
                begin: 0.15,
                end: 0,
                duration: 450.ms,
                curve: Curves.easeOutCubic,
              );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToSignIn();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              children: [
                _EnvelopeHero(animate: !reduceMotion),
                const SizedBox(height: 28),
                enter(
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.checkEmailTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ),
                  1,
                ),
                const SizedBox(height: 12),
                enter(
                  Text(
                    l10n.checkEmailBody(widget.email),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  2,
                ),
                const SizedBox(height: 28),
                enter(
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.surfaceVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.checkEmailWhileYouWait,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.primary,
                          ),
                        ),
                        for (final (index, (icon, title, body))
                            in perks.indexed) ...[
                          const SizedBox(height: 16),
                          enter(
                            _Perk(icon: icon, title: title, body: body),
                            4 + index,
                          ),
                        ],
                      ],
                    ),
                  ),
                  3,
                ),
                const SizedBox(height: 16),
                enter(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Iconsax.info_circle,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l10n.checkEmailSpamTip,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  7,
                ),
                const SizedBox(height: 28),
                CustomButton(
                  text: isCoolingDown
                      ? l10n.resendInSeconds(_secondsLeft)
                      : l10n.checkEmailResendButton,
                  isLoading: isLoading,
                  onPressed: isLoading || isCoolingDown ? null : _resend,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _backToSignIn,
                  child: Text(
                    l10n.backToSignInButton,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An envelope in a soft green disc with two rings rippling out of it, like
/// a message on its way. Still when the system asks for less motion.
class _EnvelopeHero extends StatelessWidget {
  const _EnvelopeHero({required this.animate});

  final bool animate;

  static const _disc = 112.0;

  @override
  Widget build(BuildContext context) {
    Widget ring(Duration delay) =>
        Container(
              width: _disc,
              height: _disc,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
            )
            .animate(delay: delay, onPlay: (c) => c.repeat())
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.6, 1.6),
              duration: 2400.ms,
              curve: Curves.easeOut,
            )
            .fadeOut(begin: 0.6, duration: 2400.ms);

    final envelope = Container(
      width: _disc,
      height: _disc,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryLight,
      ),
      child: const Icon(
        Iconsax.sms_tracking,
        size: 48,
        color: AppColors.primary,
      ),
    );

    return ExcludeSemantics(
      child: SizedBox(
        width: _disc * 1.7,
        height: _disc * 1.7,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (animate) ...[ring(Duration.zero), ring(1200.ms)],
            if (animate)
              envelope
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(
                    begin: 0,
                    end: -6,
                    duration: 1600.ms,
                    curve: Curves.easeInOut,
                  )
                  .animate()
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  )
            else
              envelope,
          ],
        ),
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
