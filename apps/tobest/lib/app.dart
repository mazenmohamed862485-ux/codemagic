// M-2: theme يُخزَّن في SharedPreferences
// M-3: locale يُخزَّن في SharedPreferences

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/design/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tobest/features/auth/presentation/providers/auth_provider.dart';
import 'package:tobest/router.dart';

part 'app.g.dart';

// ── Persisted Theme Provider (M-2) ──────────────────────────
@riverpod
class UserTheme extends _$UserTheme {
  static const _kKey = 'selected_theme';

  @override
  String build() {
    // load async — sync init via SharedPreferences
    _load();
    return 'auto';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_kKey) ?? 'auto';
  }

  Future<void> set(String theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, theme);
  }
}

// ── Persisted Locale Provider (M-3) ─────────────────────────
@riverpod
class UserLocale extends _$UserLocale {
  static const _kKey = 'selected_locale';

  @override
  Locale build() {
    _load();
    return const Locale('ar');
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code  = prefs.getString(_kKey) ?? 'ar';
    state = Locale(code);
  }

  Future<void> set(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, locale.languageCode);
  }
}

class ToBestApp extends ConsumerWidget {
  const ToBestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeKey = ref.watch(userThemeProvider);
    final locale   = ref.watch(userLocaleProvider);
    final router   = ref.watch(routerProvider);

    return MaterialApp.router(
      title:                      AppConfig.toBestName,
      debugShowCheckedModeBanner: false,
      theme:     _buildTheme(themeKey, Brightness.light),
      darkTheme: _buildTheme(themeKey, Brightness.dark),
      themeMode: getThemeMode(themeKey),
      routerConfig: router,
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
    );
  }

  ThemeData _buildTheme(String key, Brightness brightness) => switch (key) {
    'blue'  => buildBlueTheme(),
    'pink'  => buildPinkTheme(),
    'light' => buildLightTheme(),
    'dark'  => buildDarkTheme(),
    _       => brightness == Brightness.dark ? buildDarkTheme() : buildLightTheme(),
  };
}
