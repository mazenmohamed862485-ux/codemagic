// M-4: NotificationService + DB pre-warm + FoodSeedingService + FLAG_SECURE

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/infrastructure/background_service.dart';
import 'package:shared/infrastructure/food_seeding_service.dart';
import 'package:shared/infrastructure/isar_service.dart';
import 'package:shared/infrastructure/notification_service.dart';
import 'package:tobest/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // M-4: Background service
  await BackgroundService.initialize();

  // M-4: Pre-warm قاعدة البيانات
  final container = ProviderContainer();
  await container.read(isarServiceProvider.future);

  // N-1: زرع قاعدة الأطعمة (صامت — يعمل مرة واحدة فقط)
  container.read(foodSeedingServiceProvider);

  // M-4: تهيئة الإشعارات
  await container.read(notificationServiceProvider.future);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ToBestApp(),
    ),
  );
}
