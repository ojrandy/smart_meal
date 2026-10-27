import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // A common pattern when using bottom navigation bars is to support
      // navigating to the initial location when tapping the item that is
      // already active.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: _goBranch,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Iconsax.home_2),
              activeIcon: const Icon(Iconsax.home_1),
              label: context.l10n.navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Iconsax.discover),
              activeIcon: const Icon(Iconsax.discover_1),
              label: context.l10n.navDiscover,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Iconsax.calendar_1),
              activeIcon: const Icon(Iconsax.calendar),
              label: context.l10n.navPlanner,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Iconsax.heart),
              activeIcon: const Icon(Iconsax.heart_tick),
              label: context.l10n.navFavorites,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Iconsax.profile_circle),
              activeIcon: const Icon(Iconsax.profile_tick),
              label: context.l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}
