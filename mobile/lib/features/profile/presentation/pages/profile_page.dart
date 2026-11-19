import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/core/config/app_config.dart';
import 'package:mercadex/core/theme/theme_mode_provider.dart';
import 'package:mercadex/core/widgets/app_notification.dart';
import 'package:mercadex/core/widgets/app_top_bar.dart';
import 'package:mercadex/core/widgets/mercadex_logo.dart';
import 'package:mercadex/features/auth/presentation/providers/auth_session_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _savingTheme = false;

  Future<void> _setDarkMode(bool enabled) async {
    if (_savingTheme) return;
    setState(() => _savingTheme = true);
    try {
      await ref.read(themeModeProvider.notifier).setDarkMode(enabled);
    } catch (error, stackTrace) {
      debugPrint('Theme storage failed: $error\n$stackTrace');
      if (mounted) {
        showAppNotification(context, 'Não foi possível salvar o tema.');
      }
    } finally {
      if (mounted) setState(() => _savingTheme = false);
    }
  }

  Future<void> _logOut() async {
    try {
      await ref.read(authSessionProvider.notifier).logOut();
      if (mounted) showAppNotification(context, 'Você saiu da sua conta.');
    } catch (_) {
      if (mounted) {
        showAppNotification(context, 'Não foi possível sair. Tente novamente.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final darkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const AppTopBar(title: 'Perfil'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: session == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Você não entrou', style: text.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Busca, lista e comparação funcionam sem conta. '
                          'Entre para informar preços à comunidade.',
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: () => context.push('/login'),
                          icon: const Icon(Icons.login),
                          label: const Text('Entrar'),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          child: Text(
                            session.username.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(session.username, style: text.titleMedium),
                              Text(
                                'Pode informar preços',
                                style: text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _logOut,
                          child: const Text('Sair'),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Preferências', style: text.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Modo escuro'),
              value: darkMode,
              onChanged: _savingTheme ? null : _setDarkMode,
            ),
          ),
          const SizedBox(height: 20),
          Text('Aplicativo', style: text.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    AppConfig.useMockData
                        ? Icons.wifi_off_rounded
                        : Icons.cloud_done_outlined,
                  ),
                  title: Text(
                    AppConfig.useMockData
                        ? 'Modo demonstração'
                        : 'Conectado ao servidor',
                  ),
                  subtitle: Text(
                    AppConfig.useMockData
                        ? 'Dados do catálogo local, sem envio de preços'
                        : AppConfig.apiUrl,
                  ),
                ),
                Divider(height: 1, color: scheme.outline),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Sobre o Mercadex'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (context) => const AboutSheet(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AboutSheet extends StatelessWidget {
  const AboutSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: MercadexLogo(
                markSize: 56,
                showSlogan: true,
                centered: true,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'O Mercadex compara preços de supermercados e mostra onde a sua '
              'lista de compras sai mais barata. Os preços são mantidos pela '
              'comunidade: quem vê um valor diferente na prateleira pode '
              'informá-lo.',
            ),
            const SizedBox(height: 12),
            Text(
              'Protótipo acadêmico. Os preços e endereços exibidos são '
              'fictícios, criados para demonstração; os nomes das redes são '
              'usados apenas como exemplo.',
              style: muted,
            ),
            const SizedBox(height: 12),
            Text(
              'Projeto Integrado I — Desenvolvimento Móvel\n'
              'Jorge Inácio e Fernando Vieira',
              style: muted,
            ),
          ],
        ),
      ),
    );
  }
}
