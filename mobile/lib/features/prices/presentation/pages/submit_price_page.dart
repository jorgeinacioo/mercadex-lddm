import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/core/format/money.dart';
import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/core/widgets/app_notification.dart';
import 'package:mercadex/core/widgets/app_top_bar.dart';
import 'package:mercadex/core/widgets/category_avatar.dart';
import 'package:mercadex/core/widgets/state_views.dart';
import 'package:mercadex/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:mercadex/features/auth/presentation/require_login.dart';
import 'package:mercadex/features/markets/domain/market.dart';
import 'package:mercadex/features/markets/presentation/providers/markets_providers.dart';
import 'package:mercadex/features/markets/presentation/widgets/market_logo.dart';
import 'package:mercadex/features/prices/presentation/providers/prices_providers.dart';
import 'package:mercadex/features/products/domain/product_deals.dart';
import 'package:mercadex/features/products/presentation/providers/products_providers.dart';

typedef _FormData = ({ProductDeals product, List<MarketDetail> markets});

final _formDataProvider = FutureProvider.autoDispose.family<_FormData, String>((
  ref,
  productId,
) async {
  final product = await ref.watch(productDealsProvider(productId).future);
  final markets = await ref.watch(marketsProvider.future);
  final details = await Future.wait(
    markets.map((market) => ref.watch(marketDetailProvider(market.id).future)),
  );
  return (product: product, markets: details);
});

class SubmitPricePage extends ConsumerStatefulWidget {
  const SubmitPricePage({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<SubmitPricePage> createState() => _SubmitPricePageState();
}

class _SubmitPricePageState extends ConsumerState<SubmitPricePage> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  String? _marketId;
  String? _branchId;
  var _sending = false;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _selectMarket(MarketDetail market) {
    setState(() {
      _marketId = market.id;
      _branchId = market.branches.length == 1 ? market.branches.first.id : null;
    });
  }

  Future<void> _submit(ProductDeals product) async {
    final valid = _formKey.currentState!.validate();
    if (_branchId == null) {
      showAppNotification(context, 'Escolha onde você viu o preço.');
      return;
    }
    if (!valid || _sending) return;

    final session = ref.read(authSessionProvider);
    if (session == null) {
      if (!await requireLogin(context, ref) || !mounted) return;
      return _submit(product);
    }

    setState(() => _sending = true);
    try {
      await ref
          .read(pricesRepositoryProvider)
          .submit(
            productId: product.id,
            branchId: _branchId!,
            priceCents: parseUserPrice(_priceController.text)!,
            accessToken: session.accessToken,
          );
      if (!mounted) return;
      context.pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.isUnauthorized) {
        await ref.read(authSessionProvider.notifier).logOut();
        if (!mounted) return;
        showAppNotification(context, 'Sua sessão expirou. Entre novamente.');
      } else {
        showAppNotification(
          context,
          'Não foi possível enviar: ${error.message}',
        );
      }
    } catch (_) {
      if (mounted) {
        showAppNotification(context, 'Não foi possível enviar o preço.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(_formDataProvider(widget.productId));
    return Scaffold(
      appBar: const AppTopBar(title: 'Informar preço'),
      body: switch (data) {
        AsyncData(:final value) => _form(value),
        AsyncError(:final error) when !data.isLoading => ErrorView(
          message: friendlyError(error),
          onRetry: () => ref.invalidate(_formDataProvider(widget.productId)),
        ),
        _ => const LoadingView(),
      },
    );
  }

  Widget _form(_FormData data) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final available = ref.watch(pricesRepositoryProvider).isAvailable;
    final product = data.product;
    final market = data.markets.where((m) => m.id == _marketId).firstOrNull;
    final currentDeal = product.deals
        .where((deal) => deal.branchId == _branchId)
        .firstOrNull;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Row(
            children: [
              CategoryAvatar(category: product.category),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: text.titleMedium),
                    Text(
                      'Preço por ${product.packaging}',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!available) ...[
            const SizedBox(height: 18),
            const _InfoBox(
              icon: Icons.wifi_off_rounded,
              message:
                  'O envio de preços precisa do servidor do Mercadex. '
                  'No modo demonstração os preços podem ser consultados, '
                  'mas não publicados.',
            ),
          ],
          const SizedBox(height: 24),
          Text('Onde você viu?', style: text.titleMedium),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.9,
            children: [
              for (final option in data.markets)
                _MarketOption(
                  market: option,
                  selected: option.id == _marketId,
                  onTap: () => _selectMarket(option),
                ),
            ],
          ),
          if (market != null && market.branches.length > 1) ...[
            const SizedBox(height: 16),
            Text('Unidade', style: text.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final branch in market.branches)
                  ChoiceChip(
                    label: Text(branch.name),
                    selected: branch.id == _branchId,
                    onSelected: (_) => setState(() => _branchId = branch.id),
                  ),
              ],
            ),
          ],
          if (market != null && _branchId != null) ...[
            const SizedBox(height: 14),
            _BranchSummary(
              branch: market.branches.firstWhere((b) => b.id == _branchId),
              currentPriceCents: currentDeal?.priceCents,
            ),
          ],
          const SizedBox(height: 24),
          Text('Quanto custava?', style: text.titleMedium),
          const SizedBox(height: 10),
          TextFormField(
            controller: _priceController,
            enabled: available,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              LengthLimitingTextInputFormatter(8),
            ],
            style: text.headlineSmall,
            decoration: InputDecoration(
              hintText: '0,00',
              hintStyle: text.headlineSmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 18, right: 8),
                child: Text(
                  'R\$',
                  style: text.headlineSmall?.copyWith(color: scheme.primary),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(),
            ),
            validator: (value) => parseUserPrice(value ?? '') == null
                ? 'Informe um valor válido, por exemplo 4,29.'
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            'O novo valor substitui o preço atual desta unidade e aparece '
            'com o seu nome de usuário.',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: !available || _sending ? null : () => _submit(product),
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_sending ? 'Enviando...' : 'Publicar preço'),
          ),
        ],
      ),
    );
  }
}

class _MarketOption extends StatelessWidget {
  const _MarketOption({
    required this.market,
    required this.selected,
    required this.onTap,
  });

  final MarketDetail market;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              MarketLogo(marketName: market.name, width: 48, height: 40),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  market.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BranchSummary extends StatelessWidget {
  const _BranchSummary({required this.branch, this.currentPriceCents});

  final MarketBranch branch;
  final int? currentPriceCents;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.place_outlined, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(branch.name, style: text.titleSmall),
                Text(branch.address, style: text.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Preço atual', style: text.bodySmall),
              Text(
                currentPriceCents == null
                    ? 'Sem preço'
                    : formatBrl(currentPriceCents!),
                style: text.titleSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.onSurface),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
