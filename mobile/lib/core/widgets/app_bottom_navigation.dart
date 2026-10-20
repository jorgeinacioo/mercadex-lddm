import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/core/theme/app_colors.dart';
import 'package:mercadex/features/auth/presentation/providers/auth_session_provider.dart';

class AppBottomNavigation extends ConsumerWidget {
  const AppBottomNavigation({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(authSessionProvider) != null;
    final visibleBranches = loggedIn ? [0, 1, 2] : [0, 2];
    final selectedIndex = visibleBranches.indexOf(navigationShell.currentIndex);

    if (selectedIndex == -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        navigationShell.goBranch(0);
      });
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex == -1 ? 0 : selectedIndex,
          onDestinationSelected: (index) {
            final branch = visibleBranches[index];
            navigationShell.goBranch(
              branch,
              initialLocation: branch == navigationShell.currentIndex,
            );
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Início',
            ),
            if (loggedIn)
              const NavigationDestination(
                icon: Icon(Icons.list_alt_outlined),
                selectedIcon: Icon(Icons.list_alt),
                label: 'Lista',
              ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
