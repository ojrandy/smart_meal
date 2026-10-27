import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/validation/field_error_text.dart';
import '../../../../core/validation/validators.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/social_auth_button.dart';
import '../../domain/auth_notifier.dart';
import '../auth_error_text.dart';
import '../../domain/auth_state.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authNotifierProvider.notifier)
        .signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
  }

  // After context.go there is nothing to pop, so fall back to the screen
  // that leads here.
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

    // A sign-up that returns a session needs nothing here: the router
    // redirects to /home.
    if (next is AuthAwaitingEmailConfirmation) {
      // Supabase answers this way for an email that is already registered,
      // too, so this copy must be true in both cases.
      showAppSnackBar(
        context,
        context.l10n.signupConfirmationSent,
        isError: false,
        duration: const Duration(seconds: 6),
      );
      context.go('/auth/login');
    } else if (next is AuthError) {
      showAppSnackBar(context, authErrorText(context.l10n, next.reason));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SmartMealAuthState>(authNotifierProvider, _onAuthStateChanged);

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;
    final l10n = context.l10n;

    // The system back (Android button/gesture) behaves like the on-screen
    // one instead of closing the app when there is nothing to pop.
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
                  // Header Row (Back button & Logo)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _goBack,
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      Image.asset(
                        AppAssets.appLogo,
                        height: 40,
                        excludeFromSemantics: true,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.restaurant_menu,
                              color: AppColors.warning,
                              size: 40,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Title Section
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                      children: [
                        TextSpan(text: '${l10n.signupTitleLead}\n'),
                        TextSpan(
                          text: l10n.signupTitleAccent,
                          style: const TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.signupSubtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Hero Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.asset(
                        AppAssets.authSignupHero,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                        errorBuilder: (context, error, stackTrace) =>
                            const ColoredBox(color: AppColors.surfaceVariant),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Email Field
                  CustomTextField(
                    label: l10n.emailLabel,
                    hint: l10n.emailHint,
                    prefixIcon: Iconsax.sms,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        fieldErrorText(l10n, validateEmail(value)),
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  CustomTextField(
                    label: l10n.passwordLabel,
                    hint: '••••••••',
                    prefixIcon: Iconsax.lock,
                    isPassword: true,
                    controller: _passwordController,
                    validator: (value) =>
                        fieldErrorText(l10n, validateNewPassword(value)),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  CustomTextField(
                    label: l10n.confirmPasswordLabel,
                    hint: '••••••••',
                    prefixIcon: Iconsax.lock_1,
                    isPassword: true,
                    controller: _confirmPasswordController,
                    validator: (value) => fieldErrorText(
                      l10n,
                      validatePasswordConfirmation(
                        value,
                        _passwordController.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Create Account Button
                  CustomButton(
                    text: l10n.createAccountButton,
                    onPressed: isLoading ? null : _signUp,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 32),

                  // Divider
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(
                          color: AppColors.surfaceVariant,
                          thickness: 1.5,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          l10n.orContinueWith,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(
                          color: AppColors.surfaceVariant,
                          thickness: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Google Sign-In
                  SocialAuthButton(
                    text: l10n.continueWithGoogle,
                    icon: Image.asset(
                      AppAssets.googleLogo,
                      width: 20,
                      height: 20,
                      excludeFromSemantics: true,
                    ),
                    onPressed: isLoading ? null : _signInWithGoogle,
                  ),
                  const SizedBox(height: 32),

                  // Log In Link
                  Center(
                    child: GestureDetector(
                      onTap: isLoading ? null : () => context.go('/auth/login'),
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(text: '${l10n.haveAccountPrompt} '),
                            TextSpan(
                              text: l10n.logInLink,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
