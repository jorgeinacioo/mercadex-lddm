import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercadex/core/routing/app_router.dart';
import 'package:mercadex/core/theme/app_theme.dart';
import 'package:mercadex/features/auth/data/auth_session_storage.dart';
import 'package:mercadex/features/auth/presentation/providers/auth_session_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const storage = SecureAuthSessionStorage();
  final session = await storage.read().catchError((Object _) => null);
  runApp(
    ProviderScope(
      overrides: [
        authSessionProvider.overrideWith(
          () => AuthSessionNotifier(initialSession: session, storage: storage),
        ),
      ],
      child: const MercadexApp(),
    ),
  );
}

class MercadexApp extends StatelessWidget {
  const MercadexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mercadex',
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
