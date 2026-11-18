import 'package:go_router/go_router.dart';
import 'package:mercadex/core/widgets/app_bottom_navigation.dart';
import 'package:mercadex/features/auth/presentation/pages/login_page.dart';
import 'package:mercadex/features/home/presentation/pages/home_page.dart';
import 'package:mercadex/features/markets/presentation/pages/comparison_page.dart';
import 'package:mercadex/features/markets/presentation/pages/market_page.dart';
import 'package:mercadex/features/prices/presentation/pages/submit_price_page.dart';
import 'package:mercadex/features/products/presentation/pages/product_page.dart';
import 'package:mercadex/features/products/presentation/pages/search_results_page.dart';
import 'package:mercadex/features/profile/presentation/pages/profile_page.dart';
import 'package:mercadex/features/scanner/presentation/pages/scanner_page.dart';
import 'package:mercadex/features/shopping_list/presentation/pages/shopping_list_page.dart';

final appRouter = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppBottomNavigation(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomePage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/shopping-list',
              builder: (context, state) => const ShoppingListPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/compare',
      builder: (context, state) => const ComparisonPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) =>
          LoginPage(reason: state.uri.queryParameters['reason']),
    ),
    GoRoute(path: '/scan', builder: (context, state) => const ScannerPage()),
    GoRoute(
      path: '/market/:marketId',
      builder: (context, state) =>
          MarketPage(marketId: state.pathParameters['marketId']!),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) =>
          SearchResultsPage(query: state.uri.queryParameters['query'] ?? ''),
    ),
    GoRoute(
      path: '/product/:productId',
      builder: (context, state) =>
          ProductPage(productId: state.pathParameters['productId']!),
    ),
    GoRoute(
      path: '/product/:productId/informar-preco',
      builder: (context, state) =>
          SubmitPricePage(productId: state.pathParameters['productId']!),
    ),
  ],
);
