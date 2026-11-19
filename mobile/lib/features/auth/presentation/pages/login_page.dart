import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/core/config/app_config.dart';
import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/core/widgets/app_notification.dart';
import 'package:mercadex/core/widgets/mercadex_logo.dart';
import 'package:mercadex/features/auth/data/auth_repository.dart';
import 'package:mercadex/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:mercadex/features/auth/presentation/providers/auth_session_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.reason});

  /// `contribute` when the login was requested to report a price.
  final String? reason;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  var _isSubmitting = false;
  var _obscure = true;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final result = await ref
          .read(authRepositoryProvider)
          .login(
            username: _usernameController.text,
            password: _passwordController.text,
          );
      await ref
          .read(authSessionProvider.notifier)
          .logIn(username: result.username, accessToken: result.accessToken);
      if (!mounted) return;
      showAppNotification(context, 'Bem-vindo, ${result.username}!');
      context.pop(true);
    } on InvalidCredentialsException {
      if (mounted) setState(() => _error = 'Usuário ou senha inválidos.');
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível entrar. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final contributing = widget.reason == 'contribute';

    return Scaffold(
      appBar: AppBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            const Center(child: MercadexLogo(markSize: 64, centered: true)),
            const SizedBox(height: 28),
            Text(
              contributing ? 'Entre para contribuir' : 'Bem-vindo de volta',
              textAlign: TextAlign.center,
              style: text.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              contributing
                  ? 'Os preços informados ficam associados à sua conta.'
                  : 'Entre para informar preços e ajudar a comunidade.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _usernameController,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Usuário',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Informe seu usuário.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _login(),
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) =>
                  (value ?? '').isEmpty ? 'Informe sua senha.' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.error_outline, color: scheme.error, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: scheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _login,
              child: Text(_isSubmitting ? 'Entrando...' : 'Entrar'),
            ),
            if (AppConfig.useMockData) ...[
              const SizedBox(height: 20),
              Text(
                'Modo demonstração: use admin / admin ou jorge / mercadex.',
                textAlign: TextAlign.center,
                style: text.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
