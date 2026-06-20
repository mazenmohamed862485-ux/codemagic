// C-11: _toModel مُصلَح — يُنفَّذ حقيقياً بدل throw
// M-11: save لـ DB قبل GAS

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/domain/entities/nutrition_entity.dart';
import 'package:shared/infrastructure/drift/app_database.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:shared/infrastructure/isar_service.dart';
import 'package:tobest/features/auth/presentation/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;

part 'nutrition_provider.g.dart';

class MacroSummary {
  const MacroSummary({
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalFiber,
  });
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;
}

@riverpod
Future<List<MealEntry>> todayMeals(Ref ref) async {
  final userId = ref.watch(authStateProvider).valueOrNull?.id;
  if (userId == null) return [];
  final isar  = await ref.watch(isarServiceProvider.future);
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day);
  final end   = start.add(const Duration(days: 1));
  final rows = await (isar.db.select(isar.db.mealEntriesTable)
        ..where((t) => t.userId.equals(userId) & t.date.isBetweenValues(start, end))
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
      .get();
  return rows.map((r) => _rowToEntity(r.toJson())).toList();
}

@riverpod
Future<MacroSummary?> todayMacroSummary(Ref ref) async {
  final meals = await ref.watch(todayMealsProvider.future);
  if (meals.isEmpty) return null;
  return MacroSummary(
    totalCalories: meals.fold(0, (s, m) => s + m.totalCalories),
    totalProtein:  meals.fold(0, (s, m) => s + m.totalProtein),
    totalCarbs:    meals.fold(0, (s, m) => s + m.totalCarbs),
    totalFat:      meals.fold(0, (s, m) => s + m.totalFat),
    totalFiber:    meals.fold(0, (s, m) => s + m.totalFiber),
  );
}

@riverpod
Future<MacroResult?> dailyMacroGoal(Ref ref) async {
  final userId = ref.watch(authStateProvider).valueOrNull?.id;
  if (userId == null) return null;
  try {
    final gas  = await ref.read(gasClientProvider.future);
    final resp = await gas.get<Map<String, dynamic>>('/nutrition/goal/$userId');
    final d    = resp.data;
    if (d == null) return null;
    return MacroResult(
      calories: d['calories'] as int? ?? 2000,
      protein:  d['protein']  as int? ?? 150,
      carbs:    d['carbs']    as int? ?? 200,
      fat:      d['fat']      as int? ?? 65,
      fiber:    d['fiber']    as int? ?? 25,
    );
  } catch (_) { return null; }
}

@riverpod
class NutritionActions extends _$NutritionActions {
  @override
  void build() {}

  Future<void> deleteMeal(String mealId) async {
    final isar = await ref.read(isarServiceProvider.future);
    await (isar.db.delete(isar.db.mealEntriesTable)
          ..where((t) => t.id.equals(mealId)))
        .go();
    ref.invalidate(todayMealsProvider);
  }

  Future<void> saveParsedMeal(MealParseResult result, {String mealType = 'custom'}) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final entry = MealEntry(
      id:            const Uuid().v4(),
      userId:        user.id,
      date:          DateTime.now(),
      mealType:      mealType,
      items:         result.items,
      totalCalories: result.totalCalories,
      totalProtein:  result.totalProtein,
      totalCarbs:    result.totalCarbs,
      totalFat:      result.totalFat,
      totalFiber:    result.totalFiber,
      updatedAt:     DateTime.now(),
    );

    // C-11: _toModel مُنفَّذ حقيقياً
    await _saveToDb(entry);

    // GAS sync
    try {
      final gas = await ref.read(gasClientProvider.future);
      await gas.post('/nutrition/meal', data: _entryToJson(entry));
    } catch (e) {
      developer.log('GAS nutrition sync deferred: $e', name: 'NutritionActions');
    }
    ref.invalidate(todayMealsProvider);
  }

  Future<void> addSuggestedFood(FoodItem food) async {
    await saveParsedMeal(MealParseResult(
      totalCalories: food.calories,
      totalProtein:  food.protein,
      totalCarbs:    food.carbs,
      totalFat:      food.fat,
      totalFiber:    food.fiber,
      items: [MealFoodItem(
        foodId: food.id, foodName: food.name, amount: food.amount,
        calories: food.calories, protein: food.protein,
        carbs: food.carbs, fat: food.fat, fiber: food.fiber,
      )],
      unmatched: const [],
    ));
  }

  // C-11: مُنفَّذ بالكامل
  Future<void> _saveToDb(MealEntry entry) async {
    final isar = await ref.read(isarServiceProvider.future);
    await isar.db.into(isar.db.mealEntriesTable).insertOnConflictUpdate(
      MealEntriesTableCompanion(
        id:            Value(entry.id),
        userId:        Value(entry.userId),
        date:          Value(entry.date),
        mealType:      Value(entry.mealType),
        totalCalories: Value(entry.totalCalories),
        totalProtein:  Value(entry.totalProtein),
        totalCarbs:    Value(entry.totalCarbs),
        totalFat:      Value(entry.totalFat),
        totalFiber:    Value(entry.totalFiber),
        itemsJson:     Value(jsonEncode(entry.items.map((i) => {
          'foodId':   i.foodId,   'foodName': i.foodName,
          'amount':   i.amount,   'calories': i.calories,
          'protein':  i.protein,  'carbs':    i.carbs,
          'fat':      i.fat,      'fiber':    i.fiber,
        }).toList())),
        updatedAt:     Value(entry.updatedAt),
      ),
    );
  }

  Map<String, dynamic> _entryToJson(MealEntry e) => {
    'id': e.id, 'userId': e.userId,
    'date': e.date.toIso8601String(), 'mealType': e.mealType,
    'totalCalories': e.totalCalories, 'totalProtein': e.totalProtein,
    'totalCarbs': e.totalCarbs, 'totalFat': e.totalFat,
    'totalFiber': e.totalFiber, 'updatedAt': e.updatedAt?.toIso8601String(),
    'items': e.items.map((i) => {
      'foodId': i.foodId, 'foodName': i.foodName, 'amount': i.amount,
      'calories': i.calories, 'protein': i.protein,
      'carbs': i.carbs, 'fat': i.fat,
    }).toList(),
  };
}

MealEntry _rowToEntity(Map<String, dynamic> r) {
  final itemsRaw = r['itemsJson'] as String? ?? '[]';
  final items = (jsonDecode(itemsRaw) as List<dynamic>).map((i) {
    final m = i as Map<String, dynamic>;
    return MealFoodItem(
      foodId: m['foodId'] as String, foodName: m['foodName'] as String,
      amount: (m['amount'] as num).toDouble(),
      calories: (m['calories'] as num).toDouble(),
      protein: (m['protein'] as num).toDouble(),
      carbs: (m['carbs'] as num).toDouble(),
      fat: (m['fat'] as num).toDouble(),
      fiber: (m['fiber'] as num? ?? 0).toDouble(),
    );
  }).toList();

  return MealEntry(
    id:            r['id'] as String,
    userId:        r['userId'] as String,
    date:          r['date'] as DateTime,
    mealType:      r['mealType'] as String,
    items:         items,
    totalCalories: (r['totalCalories'] as num).toDouble(),
    totalProtein:  (r['totalProtein'] as num).toDouble(),
    totalCarbs:    (r['totalCarbs'] as num).toDouble(),
    totalFat:      (r['totalFat'] as num).toDouble(),
    totalFiber:    (r['totalFiber'] as num).toDouble(),
    updatedAt:     r['updatedAt'] as DateTime?,
  );
}
