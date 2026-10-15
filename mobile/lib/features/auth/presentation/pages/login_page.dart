import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/features/auth/data/auth_repository.dart';
import 'package:mercadex/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:mercadex/core/widgets/app_top_bar.dart';
import 'package:mercadex/core/widgets/app_notification.dart';
import 'package:mercadex/core/widgets/mercadex_logo.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      showAppNotification(context, 'Informe seu e-mail e senha.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final accessToken = await const AuthRepository().login(
        email: email,
        password: password,
      );
      if (!mounted) {
        return;
      }

      ref
          .read(authSessionProvider.notifier)
          .logIn(email: email, accessToken: accessToken);

      showAppNotification(context, 'Login realizado com sucesso.');
      context.pop();
    } catch (_) {
      if (!mounted) {
        return;
      }

      showAppNotification(context, 'E-mail ou senha inválidos.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Entrar'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          const SizedBox(height: 12),
          const Center(
            child: MercadexLogo(markSize: 72, showSlogan: true, centered: true),
          ),
          const SizedBox(height: 36),
          Text(
            'Acesse sua conta',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Entre para compartilhar e confirmar ofertas de alimentos.',
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-mail'),
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
