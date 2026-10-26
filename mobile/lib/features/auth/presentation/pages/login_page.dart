import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/features/auth/data/auth_repository.dart';
import 'package:mercadex/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:mercadex/core/widgets/app_notification.dart';
import 'package:mercadex/core/widgets/mercadex_logo.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  var _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      showAppNotification(context, 'Informe seu usuário e senha.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final accessToken = await const AuthRepository().login(
        username: username,
        password: password,
      );
      if (!mounted) {
        return;
      }

      await ref
          .read(authSessionProvider.notifier)
          .logIn(username: username, accessToken: accessToken);
      if (!mounted) return;

      showAppNotification(context, 'Login realizado com sucesso.');
      context.pop();
    } catch (_) {
      if (!mounted) {
        return;
      }

      showAppNotification(context, 'Usuário ou senha inválidos.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          const Center(child: MercadexLogo(markSize: 64, centered: true)),
          const SizedBox(height: 28),
          Text(
            'Bem-vindo de volta',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Entre para continuar',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _usernameController,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: 'Usuário',
              hintText: 'admin',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Senha'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _login,
            child: Text(_isSubmitting ? 'Entrando...' : 'Entrar'),
          ),
        ],
      ),
    );
  }
}
