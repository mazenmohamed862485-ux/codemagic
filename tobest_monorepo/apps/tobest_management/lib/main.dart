// apps/tobest_management/lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/infrastructure/background_service.dart';
import 'package:tobest_management/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await BackgroundService.initialize();

  runApp(
    const ProviderScope(
      child: ManagementApp(),
    ),
  );
}
