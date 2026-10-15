import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/social_auth_button.dart';
import '../../domain/auth_notifier.dart';
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

    if (next is AuthAuthenticated) {
      // Email confirmation is OFF — user is immediately signed in.
      context.go('/home');
    } else if (next is AuthUnauthenticated && previous is AuthLoading) {
      // Email confirmation is ON in Supabase dashboard.
      // User created but must verify email before session is active.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text(
              '✅ Account created! Please check your email to verify your account.',
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      // Navigate to login so they can sign in after confirming.
      context.go('/auth/login');
    } else if (next is AuthError) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SmartMealAuthState>(authNotifierProvider, _onAuthStateChanged);

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

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
                  const Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                      children: [
                        TextSpan(text: 'Create your\n'),
                        TextSpan(
                          text: 'Smart Meal account',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Discover personalized meals made for your taste ✨',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Hero Image
                  Center(
                    child: Image.asset(
                      AppAssets.authSignupHero,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      excludeFromSemantics: true,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        width: double.infinity,
                        color: AppColors.surfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Email Field
                  CustomTextField(
                    label: 'Email',
                    hint: 'user@email.com',
                    prefixIcon: Iconsax.sms,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  CustomTextField(
                    label: 'Password',
                    hint: '••••••••',
                    prefixIcon: Iconsax.lock,
                    isPassword: true,
                    controller: _passwordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  CustomTextField(
                    label: 'Confirm Password',
                    hint: '••••••••',
                    prefixIcon: Iconsax.lock_1,
                    isPassword: true,
                    controller: _confirmPasswordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Create Account Button
                  CustomButton(
                    text: 'Create Account ✨',
                    onPressed: isLoading ? null : _signUp,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 32),

                  // Divider
                  const Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: AppColors.surfaceVariant,
                          thickness: 1.5,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or continue with',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
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
                    text: 'Continue with Google',
                    icon: const FaIcon(
                      FontAwesomeIcons.google,
                      color: AppColors.socialGoogle,
                      size: 20,
                    ),
                    onPressed: isLoading ? null : _signInWithGoogle,
                  ),
                  const SizedBox(height: 16),

                  // Apple Sign-In (placeholder)
                  SocialAuthButton(
                    text: 'Continue with Apple',
                    icon: const FaIcon(
                      FontAwesomeIcons.apple,
                      color: AppColors.socialApple,
                      size: 24,
                    ),
                    onPressed: isLoading
                        ? null
                        : () {
                            // TODO: Implement Apple Sign-In (requires Apple Developer account)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Apple Sign-In coming soon'),
                              ),
                            );
                          },
                  ),
                  const SizedBox(height: 16),

                  // Facebook Sign-In (placeholder)
                  SocialAuthButton(
                    text: 'Continue with Facebook',
                    icon: const FaIcon(
                      FontAwesomeIcons.facebook,
                      color: AppColors.socialFacebook,
                      size: 24,
                    ),
                    onPressed: isLoading
                        ? null
                        : () {
                            // TODO: Implement Facebook Sign-In
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Facebook Sign-In coming soon'),
                              ),
                            );
                          },
                  ),
                  const SizedBox(height: 32),

                  // Log In Link
                  Center(
                    child: GestureDetector(
                      onTap: isLoading ? null : () => context.go('/auth/login'),
                      child: const Text.rich(
                        TextSpan(
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Log in',
                              style: TextStyle(
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
