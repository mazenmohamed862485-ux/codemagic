// packages/shared/lib/utils/evaluator.dart
//
// ترجمة حرفية من evaluator.js — كل منطق التقييم والحسابات الغذائية
// لا تُعدَّل خوارزميات هذا الملف بدون مراجعة evaluator.js الأصلي

import 'dart:math' as math;

import 'package:shared/config/app_config.dart';
import 'package:shared/domain/entities/nutrition_entity.dart';
import 'package:shared/domain/entities/workout_entity.dart';

/// محرك تقييم الأداء وحسابات التغذية
///
/// جميع الدوال static ونقية (بلا side effects)
/// ترجمة حرفية من evaluator.js بحفاظ كامل على المنطق الأصلي
class Evaluator {
  Evaluator._();

  // ═══════════════════════════════════════════════════════════
  //  حسابات التمارين
  // ═══════════════════════════════════════════════════════════

  /// حساب الـ 1RM بمعادلة Epley: weight × (1 + reps/30)
  ///
  /// [weight] الوزن بالكيلوغرام
  /// [reps] عدد التكرارات
  /// يُرجع 0 عند قيم غير صالحة
  static double epley(double weight, int reps) {
    if (weight <= 0 || reps <= 0) return 0;
    if (reps == 1) return weight;
    return (weight * (1 + reps / 30)).roundToDouble();
  }

  /// حجم التدريب الكلي: مجموع (وزن × تكرارات) لكل سِت
  static double volume(List<SetRecord> sets) {
    return sets.fold(0, (sum, s) => sum + (s.weight * s.reps));
  }

  /// أفضل سِت بناءً على أعلى 1RM محسوب
  ///
  /// يُرجع null إذا كانت القائمة فارغة
  static SetRecord? bestSet(List<SetRecord> sets) {
    if (sets.isEmpty) return null;
    return sets.reduce((best, s) {
      return epley(s.weight, s.reps) > epley(best.weight, best.reps) ? s : best;
    });
  }

  /// الرقم القياسي الشخصي من السجل التاريخي
  static _PRData? getPersonalRecord(List<WorkoutLogEntry> history) {
    if (history.isEmpty) return null;
    _PRData? best;
    double bestEpley = 0;

    for (final entry in history) {
      final bs = bestSet(entry.sets);
      if (bs == null) continue;
      final e = epley(bs.weight, bs.reps);
      if (e > bestEpley) {
        bestEpley = e;
        best = _PRData(
          weight: bs.weight,
          reps: bs.reps,
          epley: e,
          date: entry.date,
        );
      }
    }
    return best;
  }

  /// عدد الأيام بين تاريخين
  static int daysBetween(DateTime a, DateTime b) {
    final diff = b.difference(a);
    return diff.inDays.abs();
  }

  /// عدد الأسابيع بين تاريخين
  static double weeksBetween(DateTime a, DateTime b) => daysBetween(a, b) / 7;

  /// رقم الأسبوع في السنة (مطابق لـ JavaScript)
  static int _weekNum(DateTime d) {
    final jan1 = DateTime(d.year, 1, 1);
    return ((d.difference(jan1).inDays + jan1.weekday + 1) / 7).ceil();
  }

  /// فحص ركود 3 أسابيع متتالية
  ///
  /// يحلل آخر 3 أسابيع مختلفة في السجل
  /// يُرجع true إذا كان الوزن والتكرارات متطابقَين في الثلاث أسابيع
  static bool isStagnant3Weeks(List<WorkoutLogEntry> history) {
    if (history.length < 3) return false;

    // ترتيب تنازلي (الأحدث أولاً) — مطابق للـ JS
    final sorted = List<WorkoutLogEntry>.from(history)
      ..sort((a, b) => b.date.compareTo(a.date));

    final seenWeeks = <String>{};
    final weekEntries = <_WeekEntry>[];

    for (final entry in sorted) {
      final wk = '${entry.date.year}-${_weekNum(entry.date)}';
      if (!seenWeeks.contains(wk)) {
        seenWeeks.add(wk);
        final bs = bestSet(entry.sets);
        if (bs != null) {
          weekEntries.add(_WeekEntry(
            date: entry.date,
            weight: bs.weight,
            reps: bs.reps,
          ));
        }
      }
      if (weekEntries.length >= 3) break;
    }

    if (weekEntries.length < 3) return false;

    // الأسابيع الثلاثة الأخيرة يجب أن تكون متطابقة
    return weekEntries[0].weight == weekEntries[1].weight &&
        weekEntries[1].weight == weekEntries[2].weight &&
        weekEntries[0].reps == weekEntries[1].reps &&
        weekEntries[1].reps == weekEntries[2].reps;
  }

  /// فحص استعادة المستوى
  ///
  /// يُرجع true إذا كان الأداء الحالي يتجاوز أفضل أداء سابق
  /// بعد انخفاض في الجلسة السابقة مباشرة
  static bool isRecovery(
    List<WorkoutLogEntry> history,
    double currWeight,
    int currReps,
  ) {
    if (history.length < 2) return false;

    // أفضل 1RM تاريخياً (باستثناء الجلسة الأخيرة)
    final historyExcludingLast = history.sublist(0, history.length - 1);
    double prevBest = historyExcludingLast.fold(0.0, (maxE, h) {
      final bs = bestSet(h.sets);
      return bs != null ? math.max(maxE, epley(bs.weight, bs.reps)) : maxE;
    });

    // 1RM الجلسة قبل الأخيرة
    final secondToLast = history[history.length - 2];
    final prevLastSet  = secondToLast.sets.isNotEmpty
        ? secondToLast.sets.last
        : null;
    final prevLastEpley = prevLastSet != null
        ? epley(prevLastSet.weight, prevLastSet.reps)
        : 0.0;

    final currEpley = epley(currWeight, currReps);

    return currEpley >= prevBest && prevLastEpley < prevBest;
  }

  /// الدالة الرئيسية للتقييم
  ///
  /// [prev] آخر أداء مسجل: {weight, reps, date}
  /// [curr] الأداء الحالي: {weight, reps, date}
  /// [history] السجل التاريخي كاملاً (مرتب)
  ///
  /// ترجمة حرفية بالكامل من دالة evaluate() في evaluator.js
  static EvalResult evaluate({
    PerformancePoint? prev,
    required PerformancePoint curr,
    List<WorkoutLogEntry> history = const [],
  }) {
    // بداية — لا يوجد سجل سابق
    if (prev == null) return EvalResult.all['beg']!;

    final wD = double.parse((curr.weight - prev.weight).toStringAsFixed(2));
    final rD = curr.reps - prev.reps;

    // استعادة المستوى
    if (isRecovery(history, curr.weight, curr.reps)) {
      return EvalResult.all['rv']!;
    }

    // ركود 3 أسابيع
    if (isStagnant3Weeks(history)) return EvalResult.all['ws']!;

    // انخفاض
    if (wD < 0 || (wD == 0 && rD < 0)) return EvalResult.all['dn']!;

    // ثبات
    if (wD == 0 && rD == 0) return EvalResult.all['st']!;

    // الوزن نفسه، التكرارات أكثر
    if (wD == 0 && rD > 0) {
      final weeks = prev.date != null
          ? weeksBetween(prev.date!, curr.date)
          : 99.0;

      if (rD >= 2) {
        if (weeks <= 1) return EvalResult.all['s1']!;
        if (weeks <= 2) return EvalResult.all['s2']!;
        if (weeks <= 3) return EvalResult.all['s3']!;
        return EvalResult.all['gd']!;
      }
      if (rD == 1) {
        if (weeks <= 1) return EvalResult.all['s2']!;
        if (weeks <= 2) return EvalResult.all['s3']!;
        if (weeks <= 3) return EvalResult.all['gd']!;
        return EvalResult.all['st']!;
      }
    }

    // الوزن أكثر
    if (wD > 0) {
      if (rD >= 0) return EvalResult.all['s1']!;

      final rDown = rD.abs();

      if (wD >= 2 && wD <= 3) {
        if (rDown == 1) return EvalResult.all['s3']!;
        if (rDown == 2) return EvalResult.all['gd']!;
        if (rDown == 3) return EvalResult.all['st']!;
        return EvalResult.all['dn']!;
      }

      if (wD >= 4 && wD <= 6) {
        if (rDown == 1) return EvalResult.all['s2']!;
        if (rDown == 2) return EvalResult.all['s3']!;
        if (rDown == 3) return EvalResult.all['st']!;
        return EvalResult.all['dn']!;
      }

      // أي زيادة أخرى في الوزن
      if (rDown <= 1) return EvalResult.all['s3']!;
      if (rDown <= 2) return EvalResult.all['gd']!;
      if (rDown <= 3) return EvalResult.all['st']!;
      return EvalResult.all['dn']!;
    }

    return EvalResult.all['st']!;
  }

  /// اقتراح تعديل الوزن بناءً على التكرارات
  ///
  /// ≥12 تكرار → ارفع الوزن | ≤4 تكرارات → انزل الوزن
  static RepSuggestion? repSuggestion(int reps) {
    if (reps >= AppConfig.repsUpThreshold) {
      return const RepSuggestion(type: 'up',   messageKey: 'increaseWeight');
    }
    if (reps <= AppConfig.repsDownThreshold) {
      return const RepSuggestion(type: 'down', messageKey: 'decreaseWeight');
    }
    return null;
  }

  /// فحص تحقيق رقم قياسي جديد
  static bool checkPR(
    List<WorkoutLogEntry> history,
    double currWeight,
    int currReps,
  ) {
    if (history.isEmpty) return false;
    final prevBest = history.fold(0.0, (maxE, h) {
      final bs = bestSet(h.sets);
      return bs != null ? math.max(maxE, epley(bs.weight, bs.reps)) : maxE;
    });
    return epley(currWeight, currReps) > prevBest;
  }

  // ═══════════════════════════════════════════════════════════
  //  حسابات التغذية
  // ═══════════════════════════════════════════════════════════

  /// حساب BMR (معدل الأيض الأساسي) بمعادلة Mifflin-St Jeor
  ///
  /// ذكر:  10×وزن + 6.25×طول − 5×عمر + 5
  /// أنثى: 10×وزن + 6.25×طول − 5×عمر − 161
  static double calcBMR({
    required double weight,
    required double height,
    required int age,
    required String gender,
  }) {
    final base = 10 * weight + 6.25 * height - 5 * age;
    return gender == 'male' ? (base + 5).roundToDouble() : (base - 161).roundToDouble();
  }

  /// حساب TDEE (إجمالي إنفاق الطاقة اليومي)
  static double calcTDEE(double bmr, String activityKey) {
    final factor = _activityFactors[activityKey] ?? 1.55;
    return (bmr * factor).roundToDouble();
  }

  /// معاملات مستويات النشاط — مطابقة لـ CFG.ACTIVITY_LEVELS في config.js
  static const Map<String, double> _activityFactors = {
    'sedentary':    1.2,
    'light':        1.375,
    'moderate':     1.55,
    'active':       1.725,
    'very_active':  1.9,
  };

  /// حساب الماكرو بناءً على السعرات والهدف
  static MacroResult calcMacros({
    required int calories,
    required NutritionGoal goal,
  }) {
    const ratios = {
      NutritionGoal.loseWeight:  (p: 0.35, c: 0.35, f: 0.30),
      NutritionGoal.maintain:    (p: 0.30, c: 0.40, f: 0.30),
      NutritionGoal.gainMuscle:  (p: 0.25, c: 0.50, f: 0.25),
    };
    final r = ratios[goal]!;
    return MacroResult(
      calories: calories,
      protein: (calories * r.p / 4).round(),
      carbs:   (calories * r.c / 4).round(),
      fat:     (calories * r.f / 9).round(),
      fiber:   (calories * 0.014).round(),
    );
  }

  /// تعديل عنصر غذائي بناءً على كمية جديدة
  static FoodItem adjustByAmount(FoodItem food, double newAmount) {
    final f = newAmount / (food.amount > 0 ? food.amount : 100);
    return food.copyWith(
      amount:   newAmount,
      calories: double.parse((food.calories * f).toStringAsFixed(0)),
      protein:  double.parse((food.protein  * f).toStringAsFixed(1)),
      carbs:    double.parse((food.carbs    * f).toStringAsFixed(1)),
      fat:      double.parse((food.fat      * f).toStringAsFixed(1)),
      fiber:    double.parse((food.fiber    * f).toStringAsFixed(1)),
    );
  }

  /// تعديل عنصر غذائي بناءً على هدف سعرات
  static FoodItem adjustByCalories(FoodItem food, double targetCal) {
    final factor = targetCal / (food.calories > 0 ? food.calories : 1);
    final newAmount = ((food.amount > 0 ? food.amount : 100) * factor).round().toDouble();
    return adjustByAmount(food, newAmount);
  }

  /// اقتراح وجبة بناءً على السعرات المتبقية
  ///
  /// [remaining] السعرات المتبقية من اليوم
  /// [pref] تفضيل الترتيب
  /// [foodDB] قاعدة الأطعمة كاملة
  static List<FoodItem> suggestMeal({
    required double remainingCalories,
    required MealSuggestionPref pref,
    required List<FoodItem> foodDB,
  }) {
    if (foodDB.isEmpty) return [];

    var scored = foodDB
        .where((f) =>
            f.calories > 0 &&
            f.calories <= remainingCalories * 1.25 &&
            f.calories >= remainingCalories * 0.3)
        .map((f) {
      final ratio = remainingCalories / f.calories;
      final newAmt = (f.amount * ratio).round().toDouble();
      final adj    = adjustByAmount(f, newAmt);
      return _ScoredFood(food: adj, calDiff: (adj.calories - remainingCalories).abs());
    }).toList();

    switch (pref) {
      case MealSuggestionPref.cheapest:
        scored.sort((a, b) => (a.food.cost ?? 5).compareTo(b.food.cost ?? 5));
      case MealSuggestionPref.bestProtein:
        scored.sort((a, b) => b.food.protein.compareTo(a.food.protein));
      case MealSuggestionPref.lightest:
        scored.sort((a, b) => a.food.calories.compareTo(b.food.calories));
      case MealSuggestionPref.cleanest:
        scored.sort((a, b) => a.food.fat.compareTo(b.food.fat));
      default:
        scored.sort((a, b) => a.calDiff.compareTo(b.calDiff));
    }

    return scored.take(6).map((s) => s.food).toList();
  }

  // ═══════════════════════════════════════════════════════════
  //  parseMealText — محلل نص الوجبة مع Fuzzy + Arabic norm
  //  ترجمة حرفية من parseMealText في evaluator.js
  // ═══════════════════════════════════════════════════════════

  /// تحليل نص الوجبة باللغة العربية أو الإنجليزية
  ///
  /// يدعم:
  /// - وحدات عربية (كوب، ملعقة كبيرة، حبة، شريحة...)
  /// - Fuzzy matching بمسافة Levenshtein
  /// - تطبيع النص العربي (ألفات، تاء مربوطة، حركات)
  static MealParseResult parseMealText({
    required String text,
    required List<FoodItem> foodDB,
  }) {
    final lines = text.split('\n').where((l) => l.isNotEmpty).toList();

    double totalCalories = 0, totalProtein = 0, totalCarbs = 0,
           totalFat = 0, totalFiber = 0;
    final items     = <MealFoodItem>[];
    final unmatched = <String>[];

    for (final line in lines) {
      double amount = 100;
      String query  = line;

      // محاولة استخراج الكمية والوحدة
      final amtMatch = _amtRegex.firstMatch(line);
      if (amtMatch != null) {
        final num  = double.tryParse(amtMatch.group(1) ?? '0') ?? 0;
        final unit = amtMatch.group(2)?.trim() ?? '';
        final unitGrams = _unitToGrams[unit];
        amount = unitGrams != null ? num * unitGrams : num;
        query  = line.replaceFirst(amtMatch.group(0)!, '');
      } else {
        // رقم مجرد في البداية = غرام
        final numStart = _numStartRegex.firstMatch(line);
        if (numStart != null) {
          amount = double.tryParse(numStart.group(1) ?? '0') ?? 100;
          query  = line.replaceFirst(numStart.group(0)!, '');
        }
      }

      // تنظيف الاستعلام من الحروف الزائدة
      query = query
          .replaceAll(RegExp(r'[\d\.،,\-_()\[\]]+'), ' ')
          .replaceAll(RegExp(r'\b(من|مع|على|في|و|أو|بدون|بدُون)\b'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (query.isEmpty) continue;

      final food = _findFood(query, foodDB);
      if (food != null) {
        final adj = adjustByAmount(food, amount);
        totalCalories += adj.calories;
        totalProtein  += adj.protein;
        totalCarbs    += adj.carbs;
        totalFat      += adj.fat;
        totalFiber    += adj.fiber;
        items.add(MealFoodItem(
          foodId:   food.id,
          foodName: food.name,
          amount:   amount,
          calories: adj.calories,
          protein:  adj.protein,
          carbs:    adj.carbs,
          fat:      adj.fat,
          fiber:    adj.fiber,
        ));
      } else {
        unmatched.add(query);
      }
    }

    return MealParseResult(
      totalCalories: totalCalories,
      totalProtein:  totalProtein,
      totalCarbs:    totalCarbs,
      totalFat:      totalFat,
      totalFiber:    totalFiber,
      items:         items,
      unmatched:     unmatched,
    );
  }

  // ── تطبيع النص العربي — مطابق لـ normAr() في evaluator.js ────
  static String _normAr(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp('[أإآاى]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll(RegExp('[\u064B-\u065F\u0670]'), '') // حركات
        .replaceAll('ال', '')                              // أداة تعريف
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ── Levenshtein Distance — مطابق للـ lev() في evaluator.js ───
  static int _lev(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final row = List<int>.generate(b.length + 1, (i) => i);
    for (int i = 1; i <= a.length; i++) {
      int prev = i;
      for (int j = 1; j <= b.length; j++) {
        final val = a[i - 1] == b[j - 1]
            ? row[j - 1]
            : 1 + [row[j - 1], row[j], prev].reduce(math.min);
        row[j - 1] = prev;
        prev       = val;
      }
      row[b.length] = prev;
    }
    return row[b.length];
  }

  // ── حساب التشابه 0-1 — مطابق لـ sim() في evaluator.js ───────
  static double _sim(String query, String name) {
    final nq = _normAr(query);
    final nn = _normAr(name);
    if (nq.isEmpty || nn.isEmpty) return 0;
    if (nq == nn) return 1;
    if (nn.contains(nq) || nq.contains(nn)) return 0.92;

    // تطابق جزئي على كلمات
    final qWords = nq.split(' ').where((w) => w.length > 1).toList();
    final nWords = nn.split(' ').where((w) => w.length > 1).toList();
    final wordHit = qWords.any((qw) => nWords.any(
        (nw) => nw.contains(qw) || qw.contains(nw) || _lev(qw, nw) <= 1));
    if (wordHit) return 0.82;

    final dist = _lev(nq, nn);
    final maxL = math.max(nq.length, nn.length);
    return maxL > 0 ? math.max(0, 1 - dist / maxL) : 0;
  }

  // ── البحث عن أفضل تطابق في قاعدة الأطعمة ───────────────────
  static FoodItem? _findFood(String query, List<FoodItem> foodDB) {
    FoodItem? best;
    double bestScore = 0.58; // حد أدنى للتطابق — مطابق للـ JS

    for (final food in foodDB) {
      double s = _sim(query, food.name);
      if (s > bestScore) { bestScore = s; best = food; }
      for (final alias in food.aliases) {
        s = _sim(query, alias);
        if (s > bestScore) { bestScore = s; best = food; }
      }
    }
    return best;
  }

  // ── نمط استخراج الكمية والوحدة ──────────────────────────────
  static final _amtRegex = RegExp(
    r'(\d+(?:\.\d+)?)\s*(جرام|جم|g|غ|gram|gm|'
    r'كوب كبير|كوب صغير|كوب|كأس|'
    r'ملعقة كبيرة|ملعقه كبيره|ملعقة صغيرة|ملعقه صغيره|ملعقة|ملعقه|'
    r'قطعة|قطعه|حبة|حبه|شريحة|شريحه|'
    r'وحدة|وحده|حصة|حصه|كيلو|kg)',
    caseSensitive: false,
  );

  static final _numStartRegex = RegExp(r'^\s*(\d+(?:\.\d+)?)\s+');

  /// تحويل الوحدات إلى غرامات — مطابق لـ UNIT_G في evaluator.js
  static const Map<String, double> _unitToGrams = {
    'كوب':            240,
    'كأس':            240,
    'كوب كبير':       300,
    'كوب صغير':       180,
    'ملعقة كبيرة':    15,
    'ملعقه كبيره':    15,
    'ملعقة صغيرة':    5,
    'ملعقه صغيره':    5,
    'ملعقة':          12,
    'ملعقه':          12,
    'قطعة':           100,
    'قطعه':           100,
    'حبة':            100,
    'حبه':            100,
    'شريحة':          30,
    'شريحه':          30,
    'وحدة':           100,
    'وحده':           100,
    'حصة':            100,
    'حصه':            100,
    'كيلو':           1000,
    'kg':             1000,
  };
}

// ── هياكل بيانات عامة ─────────────────────────────────────────

/// نقطة أداء (وزن + تكرارات + تاريخ) — تُستخدم في Evaluator.evaluate()
///
/// عامة (public) عمداً: التطبيقات (tobest, tobest_management) تحتاج
/// بناء قيم من هذا النوع لتمريرها إلى evaluate()
class PerformancePoint {
  const PerformancePoint({
    required this.weight,
    required this.reps,
    this.date,
  });

  final double weight;
  final int reps;
  final DateTime? date;
}

class _PRData {
  const _PRData({
    required this.weight,
    required this.reps,
    required this.epley,
    required this.date,
  });

  final double weight;
  final int reps;
  final double epley;
  final DateTime date;
}

class _WeekEntry {
  const _WeekEntry({
    required this.date,
    required this.weight,
    required this.reps,
  });

  final DateTime date;
  final double weight;
  final int reps;
}

class _ScoredFood {
  const _ScoredFood({required this.food, required this.calDiff});
  final FoodItem food;
  final double calDiff;
}
