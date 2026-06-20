// packages/shared/lib/domain/entities/nutrition_entity.dart

import 'dart:convert';

/// عنصر غذائي من قاعدة البيانات
///
/// الحقول تطابق دليل_القيم_الغذائية.jsonl (11,000 عنصر حقيقي)
class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.amount = 100,
    this.unit = 'g',
    this.aliases = const [],
    this.cost,
    this.category = 'general',
    this.state = 'raw',
    this.preparationMethod = 'none',
    this.normalizedName = '',
    this.searchKey = '',
    this.searchHints = const [],
  });

  final String id;
  final String name;

  /// السعرات الحرارية لكل [amount] من [unit]
  final double calories;

  /// البروتين (g)
  final double protein;

  /// الكربوهيدرات (g)
  final double carbs;

  /// الدهون (g)
  final double fat;

  /// الألياف (g)
  final double fiber;

  /// الكمية التي تنطبق عليها القيم الغذائية (يقابل basis_g في قاعدة البيانات)
  final double amount;

  /// الوحدة (g, ml, إلخ)
  final String unit;

  /// أسماء بديلة للبحث
  final List<String> aliases;

  /// تكلفة تقريبية للترتيب (اختياري)
  final double? cost;

  /// فئة الطعام (لحوم، خضروات، حبوب...)
  final String category;

  /// حالة الطعام (raw, cooked...)
  final String state;

  /// طريقة التحضير (grilled, fried, boiled...)
  final String preparationMethod;

  /// الاسم بعد التطبيع لتسهيل البحث
  final String normalizedName;

  /// مفتاح بحث مُحسَّن
  final String searchKey;

  /// تلميحات بحث إضافية
  final List<String> searchHints;

  /// تحويل من صف قاعدة بيانات (drift row كـ Map) إلى Entity
  factory FoodItem.fromDbRow(Map<String, dynamic> row) {
    List<String> parseList(dynamic raw) {
      if (raw == null) return const [];
      if (raw is List) return raw.cast<String>();
      if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) return decoded.cast<String>();
        } catch (_) {
          return const [];
        }
      }
      return const [];
    }

    return FoodItem(
      id:                row['id'] as String? ?? '',
      name:              row['name'] as String? ?? '',
      calories:          (row['calories'] as num?)?.toDouble() ?? 0,
      protein:           (row['protein'] as num?)?.toDouble() ?? 0,
      carbs:             (row['carbs'] as num?)?.toDouble() ?? 0,
      fat:               (row['fat'] as num?)?.toDouble() ?? 0,
      fiber:             (row['fiber'] as num?)?.toDouble() ?? 0,
      amount:            (row['basisG'] as num?)?.toDouble() ?? 100,
      unit:              'g',
      aliases:           parseList(row['aliasesJson']),
      category:          row['category'] as String? ?? 'general',
      state:             row['state'] as String? ?? 'raw',
      preparationMethod: row['preparationMethod'] as String? ?? 'none',
      normalizedName:    row['normalizedName'] as String? ?? '',
      searchKey:         row['searchKey'] as String? ?? '',
      searchHints:       parseList(row['searchHintsJson']),
    );
  }

  FoodItem copyWith({
    String? id,
    String? name,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? amount,
    String? unit,
    List<String>? aliases,
    double? cost,
    String? category,
    String? state,
    String? preparationMethod,
    String? normalizedName,
    String? searchKey,
    List<String>? searchHints,
  }) =>
      FoodItem(
        id: id ?? this.id,
        name: name ?? this.name,
        calories: calories ?? this.calories,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
        fiber: fiber ?? this.fiber,
        amount: amount ?? this.amount,
        unit: unit ?? this.unit,
        aliases: aliases ?? this.aliases,
        cost: cost ?? this.cost,
        category: category ?? this.category,
        state: state ?? this.state,
        preparationMethod: preparationMethod ?? this.preparationMethod,
        normalizedName: normalizedName ?? this.normalizedName,
        searchKey: searchKey ?? this.searchKey,
        searchHints: searchHints ?? this.searchHints,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodItem && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// وجبة يومية تحتوي على عناصر غذائية
class MealEntry {
  const MealEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    required this.items,
    this.totalCalories = 0,
    this.totalProtein = 0,
    this.totalCarbs = 0,
    this.totalFat = 0,
    this.totalFiber = 0,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final DateTime date;

  /// 'breakfast' | 'lunch' | 'dinner' | 'snack'
  final String mealType;
  final List<MealFoodItem> items;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;
  final DateTime? updatedAt;
}

/// عنصر داخل وجبة مع الكمية المحددة
class MealFoodItem {
  const MealFoodItem({
    required this.foodId,
    required this.foodName,
    required this.amount,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
  });

  final String foodId;
  final String foodName;
  final double amount;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
}

/// نتائج تحليل نص الوجبة
class MealParseResult {
  const MealParseResult({
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalFiber,
    required this.items,
    required this.unmatched,
  });

  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;
  final List<MealFoodItem> items;

  /// الأطعمة التي لم يتم التعرف عليها
  final List<String> unmatched;

  bool get hasUnmatched => unmatched.isNotEmpty;
}

/// نتائج حساب الماكرو
class MacroResult {
  const MacroResult({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int fiber;
}

/// أهداف التغذية اليومية
enum NutritionGoal {
  loseWeight('loseWeight'),
  maintain('maintain'),
  gainMuscle('gainMuscle');

  const NutritionGoal(this.key);
  final String key;
}

/// تفضيل اقتراح الوجبة
enum MealSuggestionPref {
  bestMatch('bestMatch'),
  cheapest('cheapest'),
  bestProtein('bestProtein'),
  lightest('lightest'),
  cleanest('cleanest');

  const MealSuggestionPref(this.key);
  final String key;
}
