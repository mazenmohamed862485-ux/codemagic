// packages/shared/lib/design/themes.dart
//
// 5 ثيمات: Auto, Light, Dark, Blue, Pink
// Material 3 — Soft Accents فقط (ليس System كاملاً)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/design/tokens.dart';

/// إعداد الـ ThemeData للثيم الفاتح
ThemeData buildLightTheme({Color accent = AppColors.primary}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: accent,
    brightness: Brightness.light,
    primary:          accent,
    onPrimary:        Colors.white,
    secondary:        AppColors.primaryLight,
    surface:          AppColors.surfaceLight,
    onSurface:        AppColors.textPrimaryLight,
    surfaceContainerHighest: AppColors.surfaceVariantLight,
    error:            AppColors.error,
  );

  return _buildTheme(colorScheme, Brightness.light);
}

/// إعداد الـ ThemeData للثيم الداكن
ThemeData buildDarkTheme({Color accent = AppColors.primary}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: accent,
    brightness: Brightness.dark,
    primary:          accent,
    onPrimary:        Colors.white,
    secondary:        AppColors.primaryDark,
    surface:          AppColors.surfaceDark,
    onSurface:        AppColors.textPrimaryDark,
    surfaceContainerHighest: AppColors.surfaceVariantDark,
    error:            AppColors.error,
  );

  return _buildTheme(colorScheme, Brightness.dark);
}

/// الثيم الأزرق الكامل
ThemeData buildBlueTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.blueThemePrimary,
    brightness: Brightness.dark,
    primary:  AppColors.blueThemePrimary,
    surface:  AppColors.blueThemeSurface,
    onSurface: const Color(0xFFE2E8F0),
    surfaceContainerHighest: const Color(0xFF334155),
  );
  return _buildTheme(colorScheme, Brightness.dark);
}

/// الثيم الوردي الكامل
ThemeData buildPinkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.pinkThemePrimary,
    brightness: Brightness.light,
    primary:  AppColors.pinkThemePrimary,
    surface:  AppColors.pinkThemeSurface,
    onSurface: const Color(0xFF1F2937),
    surfaceContainerHighest: const Color(0xFFFCE7F3),
  );
  return _buildTheme(colorScheme, Brightness.light);
}

/// بناء الـ ThemeData المشترك
ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  // نظام الخطوط — Cairo للعربي، Inter للإنجليزي
  // يتبدل تلقائياً مع Locale
  final baseTextTheme = GoogleFonts.cairoTextTheme(
    ThemeData(brightness: brightness).textTheme,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme:  colorScheme,
    brightness:   brightness,

    // ── Typography ──────────────────────────────────────────
    textTheme: baseTextTheme.copyWith(
      displayLarge:  baseTextTheme.displayLarge?.copyWith(fontWeight: FontWeight.w700),
      displayMedium: baseTextTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium:baseTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
      titleLarge:    baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium:   baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      bodyLarge:     baseTextTheme.bodyLarge?.copyWith(fontSize: AppTypography.bodyLg),
      bodyMedium:    baseTextTheme.bodyMedium?.copyWith(fontSize: AppTypography.bodyMd),
      bodySmall:     baseTextTheme.bodySmall?.copyWith(fontSize: AppTypography.bodySm),
      labelLarge:    baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    ),

    // ── App Bar ─────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      elevation:      0,
      centerTitle:    false,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      titleTextStyle: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    ),

    // ── Cards ───────────────────────────────────────────────
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      color: colorScheme.surface,
    ),

    // ── Buttons ─────────────────────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        textStyle: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
      ),
    ),

    // ── Input Fields ────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled:            true,
      fillColor:         colorScheme.surfaceContainerHighest.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
    ),

    // ── Bottom Navigation ────────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      elevation:    0,
      indicatorColor: colorScheme.primary.withOpacity(0.12),
      backgroundColor: colorScheme.surface,
      labelTextStyle: WidgetStateProperty.all(
        baseTextTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
      ),
    ),

    // ── Divider ─────────────────────────────────────────────
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withOpacity(0.5),
      space: 1,
      thickness: 1,
    ),

    // ── List Tile ────────────────────────────────────────────
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
    ),

    // ── Scaffold ─────────────────────────────────────────────
    scaffoldBackgroundColor: isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight,
  );
}

/// قائمة الثيمات المتاحة
enum AppTheme {
  auto('auto'),
  light('light'),
  dark('dark'),
  blue('blue'),
  pink('pink');

  const AppTheme(this.key);
  final String key;

  static AppTheme fromKey(String key) =>
      AppTheme.values.firstWhere((t) => t.key == key, orElse: () => AppTheme.auto);
}

/// الحصول على ThemeMode من مفتاح الثيم
ThemeMode getThemeMode(String themeKey) {
  return switch (themeKey) {
    'light' => ThemeMode.light,
    'dark'  => ThemeMode.dark,
    _       => ThemeMode.system,
  };
}
