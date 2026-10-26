import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercadex/core/routing/app_router.dart';
import 'package:mercadex/core/theme/app_theme.dart';
import 'package:mercadex/core/theme/theme_mode_provider.dart';
import 'package:mercadex/core/theme/theme_preferences.dart';
import 'package:mercadex/features/auth/data/auth_session_storage.dart';
import 'package:mercadex/features/auth/presentation/providers/auth_session_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const storage = SecureAuthSessionStorage();
  final session = await storage.read().catchError((Object _) => null);
  final themePreferences = SharedPreferencesThemePreferences();
  final darkMode = await themePreferences.readDarkMode().catchError(
    (Object _) => false,
  );
  runApp(
    ProviderScope(
      overrides: [
        authSessionProvider.overrideWith(
          () => AuthSessionNotifier(initialSession: session, storage: storage),
        ),
        themeModeProvider.overrideWith(
          () => ThemeModeNotifier(
            initialMode: darkMode ? ThemeMode.dark : ThemeMode.light,
            preferences: themePreferences,
          ),
        ),
      ],
      child: const MercadexApp(),
    ),
  );
}

class MercadexApp extends ConsumerWidget {
  const MercadexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Mercadex',
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: appRouter,
    );
  }
}
