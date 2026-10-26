import 'package:flutter/material.dart';
import 'package:mercadex/core/theme/app_colors.dart';

class AppTheme {
  const AppTheme._();

  static const _radius = 20.0;

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final onPrimary = isDark ? const Color(0xFF092016) : AppColors.surface;
    final background = isDark ? const Color(0xFF101914) : AppColors.background;
    final surface = isDark ? const Color(0xFF1D2A22) : AppColors.surface;
    final ink = isDark ? const Color(0xFFF1F6F2) : AppColors.ink;
    final muted = isDark ? const Color(0xFFB7C9BB) : AppColors.textSecondary;
    final border = isDark ? const Color(0xFF3B5140) : AppColors.border;

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: onPrimary,
          primaryContainer: isDark
              ? const Color(0xFF244833)
              : const Color(0xFFDCFCE7),
          onPrimaryContainer: isDark ? ink : AppColors.deepGreen,
          secondary: AppColors.amber,
          onSecondary: AppColors.deepGreen,
          tertiary: AppColors.orange,
          onTertiary: ink,
          surface: surface,
          onSurface: ink,
          onSurfaceVariant: muted,
          outline: border,
        );

    final textTheme =
        (isDark
                ? Typography.material2021().white
                : Typography.material2021().black)
            .apply(fontFamily: 'Inter', bodyColor: ink, displayColor: ink)
            .copyWith(
              headlineSmall: TextStyle(
                color: ink,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                height: 1.2,
              ),
              titleLarge: TextStyle(
                color: ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                height: 1.25,
              ),
              titleMedium: TextStyle(
                color: ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
              titleSmall: TextStyle(
                color: ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
              bodyLarge: TextStyle(
                color: ink,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
              bodyMedium: TextStyle(
                color: ink,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
              bodySmall: TextStyle(
                color: muted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
              labelLarge: TextStyle(
                color: ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radius),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Inter',
      textTheme: textTheme,
      scaffoldBackgroundColor: background,
      splashColor: primary.withValues(alpha: 0.08),
      highlightColor: primary.withValues(alpha: 0.04),
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: primary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: textTheme.bodyMedium?.copyWith(color: muted),
        hintStyle: textTheme.bodyMedium?.copyWith(color: muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _inputBorder(border),
        enabledBorder: _inputBorder(border),
        focusedBorder: _inputBorder(primary, width: 1.6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: surface,
        indicatorColor: primary.withValues(alpha: 0.12),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primary : muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? primary : muted);
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: primary.withValues(alpha: 0.35),
          disabledForegroundColor: onPrimary,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: shape,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? primary : AppColors.deepGreen,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: primary),
          shape: shape,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: primary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        side: BorderSide(color: border),
        labelStyle: textTheme.labelLarge,
        shape: const StadiumBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF244833) : AppColors.deepGreen,
        contentTextStyle: TextStyle(color: isDark ? ink : AppColors.surface),
        behavior: SnackBarBehavior.floating,
        shape: shape,
      ),
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: surface,
        surfaceTintColor: surface,
        dividerColor: border,
        contentTextStyle: TextStyle(
          color: ink,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
