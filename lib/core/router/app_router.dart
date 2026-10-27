import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'scaffold_with_nav_bar.dart';
import '../l10n/l10n.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/domain/auth_session.dart';
import '../../features/auth/domain/password_recovery.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/onboarding/domain/onboarding_notifier.dart';
import '../../features/setup/domain/setup_status.dart';
import '../../features/setup/presentation/setup_loading_screen.dart';
import '../../features/setup/presentation/setup_processing_screen.dart';
import '../../features/setup/presentation/setup_questions_screen.dart';
import '../../features/splash/domain/launch_ready_notifier.dart';
import 'launch_redirect.dart';

// Placeholder screen — replace each one as features are built
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}

// ── Navigator Keys ─────────────────────────────────────────────────────────

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

// ── Router Refresh Notifier ────────────────────────────────────────────────
//
// A ChangeNotifier that bridges the Riverpod state routing depends on to
// GoRouter's refreshListenable. When any of it changes, this notifier fires
// and GoRouter re-evaluates its redirect function. New routing inputs are
// added here, never as a second refresh mechanism.

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    void refresh(_, _) => notifyListeners();
    ref.listen(authSessionProvider, refresh);
    ref.listen(passwordRecoveryProvider, refresh);
    ref.listen(setupStatusProvider, refresh);
    ref.listen(onboardingSeenProvider, refresh);
    ref.listen(launchReadyProvider, refresh);
  }
}

// ── Router Provider ────────────────────────────────────────────────────────

/// The main GoRouter instance exposed as a Riverpod provider.
/// Watches the session, recovery, setup, onboarding and launch-ready providers via
/// [_RouterRefreshNotifier] so it re-evaluates redirects when they change.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,

    // ── Auth Guard ─────────────────────────────────────────────────────────
    // The whole decision lives in resolveRedirect (launch_redirect.dart).
    redirect: (context, state) => resolveRedirect(
      LaunchSnapshot(
        location: state.matchedLocation,
        isReady: ref.read(launchReadyProvider),
        isSignedIn: ref.read(authSessionProvider) != null,
        isOnboardingSeen: ref.read(onboardingSeenProvider),
        isRecovering: ref.read(passwordRecoveryProvider),
        isSetupComplete: ref.read(setupStatusProvider) == SetupStatus.complete,
      ),
    ),

    routes: [
      // ── Authentication & Onboarding ──────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: resetPasswordRoute,
        builder: (context, state) => const ResetPasswordScreen(),
      ),

      // ── Setup / Preferences Flow ─────────────────────────────────────────
      GoRoute(
        path: setupEntryRoute,
        builder: (context, state) => const SetupLoadingScreen(),
      ),
      GoRoute(
        path: '/setup/lifestyle',
        builder: (context, state) =>
            const SetupQuestionsScreen(lifestyleSection: true),
      ),
      GoRoute(
        path: '/setup/preferences',
        builder: (context, state) =>
            const SetupQuestionsScreen(lifestyleSection: false),
      ),
      GoRoute(
        path: '/setup/processing',
        builder: (context, state) => const SetupProcessingScreen(),
      ),

      // ── Main Shell (Bottom Navigation) ───────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'recipe/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id'];
                      return PlaceholderScreen(
                        title: context.l10n.recipeDetailsTitle(id ?? ''),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // Discover
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                builder: (context, state) =>
                    PlaceholderScreen(title: context.l10n.navDiscover),
              ),
            ],
          ),
          // Planner
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/planner',
                builder: (context, state) =>
                    PlaceholderScreen(title: context.l10n.navPlanner),
              ),
            ],
          ),
          // Favorites
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (context, state) =>
                    PlaceholderScreen(title: context.l10n.navFavorites),
              ),
            ],
          ),
          // Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) =>
                    PlaceholderScreen(title: context.l10n.navProfile),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
