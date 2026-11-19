import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercadex/core/theme/app_theme.dart';
import 'package:mercadex/core/theme/theme_mode_provider.dart';
import 'package:mercadex/core/theme/theme_preferences.dart';
import 'package:mercadex/features/profile/presentation/pages/profile_page.dart';

class MemoryThemePreferences implements ThemePreferences {
  bool enabled = false;
  bool failWrites = false;

  @override
  Future<bool> readDarkMode() async => enabled;

  @override
  Future<void> writeDarkMode(bool value) async {
    if (failWrites) throw StateError('Storage unavailable');
    enabled = value;
  }
}

void main() {
  test('saved dark mode restores in a new provider', () async {
    final preferences = MemoryThemePreferences();
    final first = ProviderContainer(
      overrides: [
        themeModeProvider.overrideWith(
          () => ThemeModeNotifier(preferences: preferences),
        ),
      ],
    );

    expect(first.read(themeModeProvider), ThemeMode.light);
    await first.read(themeModeProvider.notifier).setDarkMode(true);
    expect(first.read(themeModeProvider), ThemeMode.dark);
    first.dispose();

    final second = ProviderContainer(
      overrides: [
        themeModeProvider.overrideWith(
          () => ThemeModeNotifier(
            initialMode: (preferences.enabled
                ? ThemeMode.dark
                : ThemeMode.light),
            preferences: preferences,
          ),
        ),
      ],
    );
    addTearDown(second.dispose);
    expect(second.read(themeModeProvider), ThemeMode.dark);

    await second.read(themeModeProvider.notifier).setDarkMode(false);
    expect(await preferences.readDarkMode(), isFalse);
  });

  test('failed write keeps current mode', () async {
    final preferences = MemoryThemePreferences()..failWrites = true;
    final container = ProviderContainer(
      overrides: [
        themeModeProvider.overrideWith(
          () => ThemeModeNotifier(preferences: preferences),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(themeModeProvider.notifier).setDarkMode(true),
      throwsStateError,
    );
    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  testWidgets('profile switch changes app theme', (tester) async {
    final preferences = MemoryThemePreferences();
    final container = ProviderContainer(
      overrides: [
        themeModeProvider.overrideWith(
          () => ThemeModeNotifier(preferences: preferences),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, child) => MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ref.watch(themeModeProvider),
            home: const ProfilePage(),
          ),
        ),
      ),
    );

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    await tester.tap(find.text('Modo escuro'));
    await tester.pumpAndSettle();

    expect(preferences.enabled, isTrue);
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    expect(
      AppTheme.dark.scaffoldBackgroundColor,
      isNot(AppTheme.light.scaffoldBackgroundColor),
    );
  });
}
