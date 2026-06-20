// packages/shared/lib/infrastructure/food_seeding_service.dart
// N-1: خدمة زرع قاعدة الأطعمة (11,000 عنصر) — تُشغَّل مرة واحدة فقط

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/infrastructure/isar_service.dart';

part 'food_seeding_service.g.dart';

/// خدمة زرع قاعدة الأطعمة عند أول تشغيل
class FoodSeedingService {
  FoodSeedingService(this._db);
  final IsarService _db;

  /// تحقق من الحاجة للزرع وابدأ إذا لزم
  Future<void> seedIfNeeded() async {
    final count = await _db.getFoodCount();
    if (count > 0) {
      developer.log('Food DB already seeded: $count items', name: 'FoodSeeding');
      return;
    }
    await _seedFromAsset();
  }

  Future<void> _seedFromAsset() async {
    developer.log('Seeding food database from asset...', name: 'FoodSeeding');
    try {
      // تحميل الـ JSON Asset (11.2 MB) كـ String
      final raw = await rootBundle.loadString('assets/food_database.json');

      // تحويل JSON → List بشكل دُفعي (chunked decoding)
      final List<dynamic> all = jsonDecode(raw) as List<dynamic>;
      final foods = all.cast<Map<String, dynamic>>();

      // إدخال بـ 200 عنصر في كل دُفعة
      await _db.seedFoods(foods);

      developer.log('Food DB seeded: ${foods.length} items', name: 'FoodSeeding');
    } catch (e, st) {
      developer.log('Food seeding failed: $e\n$st', name: 'FoodSeeding');
    }
  }
}

@riverpod
Future<FoodSeedingService> foodSeedingService(Ref ref) async {
  final isar    = await ref.watch(isarServiceProvider.future);
  final service = FoodSeedingService(isar);
  await service.seedIfNeeded();
  return service;
}
