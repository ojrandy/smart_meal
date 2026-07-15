import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'scaffold_with_nav_bar.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/domain/auth_notifier.dart';
import '../../features/auth/domain/auth_state.dart';

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

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

// ── Router Refresh Notifier ────────────────────────────────────────────────
//
// A ChangeNotifier that bridges Riverpod auth state changes to GoRouter's
// refreshListenable. When auth state changes, this notifier fires and
// GoRouter re-evaluates its redirect function.

class _RouterRefreshNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterRefreshNotifier(this._ref) {
    // Listen to auth state changes and notify GoRouter to re-evaluate.
    _ref.listen<SmartMealAuthState>(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }
}

// ── Router Provider ────────────────────────────────────────────────────────

/// The main GoRouter instance exposed as a Riverpod provider.
/// Watches [authNotifierProvider] via [_RouterRefreshNotifier] so it
/// automatically re-evaluates redirects when the auth state changes.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,

    // ── Auth Guard ─────────────────────────────────────────────────────────
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isAuthenticated = authState is AuthAuthenticated;
      final loc = state.matchedLocation;

      // Public routes — never redirect away from these
      final isPublic = loc == '/splash' ||
          loc == '/onboarding' ||
          loc.startsWith('/auth');

      if (isPublic) {
        // If authenticated and trying to access auth screens → go home
        if (isAuthenticated && loc.startsWith('/auth')) {
          return '/home';
        }
        return null; // Allow through
      }

      // Protected routes — require authentication
      if (!isAuthenticated) {
        return '/auth/login';
      }

      return null; // Authenticated, allow through
    },

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
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Forgot Password'),
      ),

      // ── Setup / Preferences Flow ─────────────────────────────────────────
      GoRoute(
        path: '/setup/loading',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Getting Things Ready'),
      ),
      GoRoute(
        path: '/setup/lifestyle',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Lifestyle Setup'),
      ),
      GoRoute(
        path: '/setup/preferences',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Preferences & Budget'),
      ),
      GoRoute(
        path: '/setup/processing',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'AI Processing Experience'),
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
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'Home Screen'),
                routes: [
                  GoRoute(
                    path: 'recipe/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id'];
                      return PlaceholderScreen(title: 'Recipe Details: $id');
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
                    const PlaceholderScreen(title: 'Discover Screen'),
              ),
            ],
          ),
          // Planner
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/planner',
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'Planner Screen'),
              ),
            ],
          ),
          // Favorites
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'Favorites Screen'),
              ),
            ],
          ),
          // Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'Profile Screen'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
