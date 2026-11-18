import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/features/shopping_list/presentation/providers/shopping_list_provider.dart';

/// The shopping list lives on the device, so every tab is available without
/// signing in. An account is only needed to contribute prices.
class AppBottomNavigation extends ConsumerWidget {
  const AppBottomNavigation({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listCount = ref.watch(shoppingListProvider).asData?.value.length ?? 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Início',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: listCount > 0,
                label: Text('$listCount'),
                child: const Icon(Icons.list_alt_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: listCount > 0,
                label: Text('$listCount'),
                child: const Icon(Icons.list_alt),
              ),
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
