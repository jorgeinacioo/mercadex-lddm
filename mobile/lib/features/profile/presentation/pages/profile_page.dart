import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:mercadex/core/widgets/app_top_bar.dart';
import 'package:mercadex/core/widgets/app_notification.dart';
import 'package:mercadex/core/widgets/mercadex_logo.dart';
import 'package:mercadex/core/theme/theme_mode_provider.dart';

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
    } catch (_) {
      if (mounted) showAppNotification(context, 'Não foi possível salvar o tema.');
    } finally {
      if (mounted) setState(() => _savingTheme = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final darkMode = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: const AppTopBar(title: 'Perfil'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const MercadexLogo(markSize: 36),
          const SizedBox(height: 20),
          if (session == null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Entrar'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/login'),
              ),
            )
          else ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(session.username),
                subtitle: const Text('Conectado'),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sair'),
                onTap: () async {
                  try {
                    await ref.read(authSessionProvider.notifier).logOut();
                  } catch (_) {
                    if (context.mounted) {
                      showAppNotification(
                        context,
                        'Não foi possível sair. Tente novamente.',
                      );
                    }
                  }
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Modo escuro'),
              value: darkMode,
              onChanged: _savingTheme ? null : _setDarkMode,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Sobre o Mercadex'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showModalBottomSheet<void>(
                  context: context,
                  builder: (context) => const AboutSheet(),
                );
              },
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
            const SizedBox(height: 24),
            Text(
              'Sobre o Mercadex',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'O Mercadex ajuda você a encontrar ofertas de alimentos por perto, '
              'compartilhadas pela comunidade.',
            ),
          ],
        ),
      ),
    );
  }
}
