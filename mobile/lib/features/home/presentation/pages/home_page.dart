import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mercadex/core/config/app_config.dart';
import 'package:mercadex/core/theme/app_colors.dart';
import 'package:mercadex/core/widgets/app_search_field.dart';
import 'package:mercadex/core/widgets/mercadex_logo.dart';
import 'package:mercadex/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:mercadex/features/home/presentation/providers/home_products_provider.dart';
import 'package:mercadex/features/home/presentation/widgets/ad_banner.dart';
import 'package:mercadex/features/home/presentation/widgets/home_product_section.dart';
import 'package:mercadex/features/home/presentation/widgets/top_markets.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentProducts = ref.watch(recentProductsProvider);
    final hotTodayProducts = ref.watch(hotTodayProductsProvider);
    final session = ref.watch(authSessionProvider);
    final name = _firstName(session?.username);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Row(
              children: [
                const Spacer(),
                if (AppConfig.useMockData) const _DebugChip(),
                const SizedBox(width: 12),
                const _BrandAction(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              name == null ? 'Olá!' : 'Olá, $name!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Boas compras hoje!',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            AppSearchField(
              hintText: 'Buscar produto...',
              onSubmitted: (query) {
                final searchQuery = query.trim();
                if (searchQuery.isEmpty) {
                  return;
                }

                context.push(
                  '/search?query=${Uri.encodeQueryComponent(searchQuery)}',
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _HomeShortcut(
                  icon: Icons.qr_code_scanner,
                  label: 'Escanear',
                  onTap: () => context.push('/scan'),
                ),
                _HomeShortcut(
                  icon: Icons.list_alt_outlined,
                  label: 'Lista',
                  onTap: () {
                    if (session == null) {
                      context.push('/login');
                      return;
                    }
                    context.go('/shopping-list');
                  },
                ),
                _HomeShortcut(
                  icon: Icons.balance_outlined,
                  label: 'Comparar',
                  onTap: () => context.push('/compare'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            hotTodayProducts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text(
                'Não foi possível carregar as ofertas em destaque.',
              ),
              data: (products) => HomeProductSection(
                title: 'Ofertas em destaque',
                products: products,
                emptyMessage: 'Nenhum produto disponível.',
              ),
            ),
            const SizedBox(height: 24),
            const AdBanner(),
            const SizedBox(height: 24),
            const TopMarkets(),
            const SizedBox(height: 24),
            HomeProductSection(
              title: 'Pesquisados recentemente',
              products: recentProducts,
              emptyMessage: 'Pesquise e abra um produto para vê-lo aqui.',
            ),
          ],
        ),
      ),
    );
  }
}

String? _firstName(String? username) {
  if (username == null || username.trim().isEmpty) return null;
  final local = username.split(RegExp(r'[.\-_]')).first.trim();
  if (local.isEmpty) return null;
  return local[0].toUpperCase() + local.substring(1);
}

class _BrandAction extends StatelessWidget {
  const _BrandAction();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: MercadexMark(size: 22, onDark: true),
      ),
    );
  }
}

class _DebugChip extends StatelessWidget {
  const _DebugChip();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(99)),
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          'DEBUG',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _HomeShortcut extends StatelessWidget {
  const _HomeShortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 88,
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 64,
                height: 64,
                child: Icon(icon, color: AppColors.primary, size: 28),
              ),
            ),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}
