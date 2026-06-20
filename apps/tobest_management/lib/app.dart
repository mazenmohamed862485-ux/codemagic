// apps/tobest_management/lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/design/themes.dart';
import 'package:tobest_management/router.dart';

class ManagementApp extends ConsumerWidget {
  const ManagementApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeKey = ref.watch(mgmtThemeProvider);
    final locale   = ref.watch(mgmtLocaleProvider);
    final router   = ref.watch(mgmtRouterProvider);

    return MaterialApp.router(
      title:                      AppConfig.managementName,
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
        textDirection: locale?.languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: child!,
      ),
    );
  }

  ThemeData _buildTheme(String key, Brightness brightness) {
    return switch (key) {
      'blue'  => buildBlueTheme(),
      'pink'  => buildPinkTheme(),
      'light' => buildLightTheme(accent: const Color(0xFF1E3A8A)),
      'dark'  => buildDarkTheme(accent: const Color(0xFF1E3A8A)),
      _       => brightness == Brightness.dark
          ? buildDarkTheme(accent: const Color(0xFF1E3A8A))
          : buildLightTheme(accent: const Color(0xFF1E3A8A)),
    };
  }
}

final mgmtThemeProvider  = StateProvider<String>((ref) => 'auto');
final mgmtLocaleProvider = StateProvider<Locale?>((ref) => const Locale('ar'));
