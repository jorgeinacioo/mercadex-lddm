import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mercadex/features/home/presentation/providers/home_products_provider.dart';
import 'package:mercadex/core/widgets/app_top_bar.dart';
import 'package:mercadex/core/widgets/app_search_field.dart';
import 'package:mercadex/features/home/presentation/widgets/ad_banner.dart';
import 'package:mercadex/features/home/presentation/widgets/home_product_section.dart';
import 'package:mercadex/features/home/presentation/widgets/top_markets.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentProducts = ref.watch(recentProductsProvider);
    final hotTodayProducts = ref.watch(hotTodayProductsProvider);

    return Scaffold(
      appBar: const AppTopBar(title: 'Mercadex', showBrand: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          AppSearchField(
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push('/scan'),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Escanear produto'),
            ),
          ),
          const SizedBox(height: 20),
          const AdBanner(),
          const SizedBox(height: 24),
          const TopMarkets(),
          const SizedBox(height: 24),
          HomeProductSection(
            title: 'Destaques de hoje',
            products: hotTodayProducts,
            emptyMessage: 'Nenhum produto disponível.',
          ),
          const SizedBox(height: 24),
          HomeProductSection(
            title: 'Pesquisados recentemente',
            products: recentProducts,
            emptyMessage: 'Pesquise e abra um produto para vê-lo aqui.',
          ),
        ],
      ),
    );
  }
}
