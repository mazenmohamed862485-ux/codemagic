// packages/shared/test/evaluator_test.dart
//
// اختبارات وحدة لمحرك التقييم — يضمن مطابقة منطق evaluator.js حرفياً

import 'package:flutter_test/flutter_test.dart';
import 'package:shared/domain/entities/nutrition_entity.dart';
import 'package:shared/domain/entities/workout_entity.dart';
import 'package:shared/utils/evaluator.dart';

void main() {
  group('Epley 1RM Formula', () {
    test('single rep returns weight itself', () {
      expect(Evaluator.epley(100, 1), 100);
    });

    test('calculates correctly for multiple reps', () {
      // 100 * (1 + 5/30) = 116.67 → rounds to 117
      final result = Evaluator.epley(100, 5);
      expect(result, closeTo(116.67, 1));
    });

    test('returns 0 for invalid inputs', () {
      expect(Evaluator.epley(0, 5), 0);
      expect(Evaluator.epley(100, 0), 0);
      expect(Evaluator.epley(-10, 5), 0);
    });
  });

  group('Volume Calculation', () {
    test('sums weight × reps across all sets', () {
      final sets = [
        const SetRecord(weight: 100, reps: 10),
        const SetRecord(weight: 100, reps: 8),
      ];
      expect(Evaluator.volume(sets), 1800);
    });

    test('returns 0 for empty sets', () {
      expect(Evaluator.volume([]), 0);
    });
  });

  group('Best Set Selection', () {
    test('returns null for empty list', () {
      expect(Evaluator.bestSet([]), isNull);
    });

    test('picks set with highest Epley 1RM', () {
      final sets = [
        const SetRecord(weight: 80, reps: 10),  // epley ≈ 106.7
        const SetRecord(weight: 100, reps: 5),  // epley ≈ 116.7
        const SetRecord(weight: 60, reps: 15),  // epley ≈ 90
      ];
      final best = Evaluator.bestSet(sets);
      expect(best!.weight, 100);
      expect(best.reps, 5);
    });
  });

  group('Rep Suggestion', () {
    test('suggests weight increase at threshold reps (≥12)', () {
      final s = Evaluator.repSuggestion(12);
      expect(s, isNotNull);
      expect(s!.type, 'up');
    });

    test('suggests weight decrease at low reps (≤4)', () {
      final s = Evaluator.repSuggestion(4);
      expect(s, isNotNull);
      expect(s!.type, 'down');
    });

    test('no suggestion in normal range', () {
      expect(Evaluator.repSuggestion(8), isNull);
    });
  });

  group('Evaluation Logic — evaluate()', () {
    test('returns "beg" when no previous performance', () {
      final result = Evaluator.evaluate(
        prev: null,
        curr: const PerformancePoint(weight: 50, reps: 10, date: null),
      );
      expect(result.code, 'beg');
    });

    test('same weight, more reps within a week → s1/s2', () {
      final now = DateTime.now();
      final result = Evaluator.evaluate(
        prev: PerformancePoint(weight: 50, reps: 8, date: now.subtract(const Duration(days: 3))),
        curr: PerformancePoint(weight: 50, reps: 10, date: now),
      );
      expect(['s1', 's2'].contains(result.code), isTrue);
    });

    test('same weight, same reps → stagnation (st)', () {
      final now = DateTime.now();
      final result = Evaluator.evaluate(
        prev: PerformancePoint(weight: 50, reps: 10, date: now.subtract(const Duration(days: 7))),
        curr: PerformancePoint(weight: 50, reps: 10, date: now),
      );
      expect(result.code, 'st');
    });

    test('weight decreased → decline (dn)', () {
      final now = DateTime.now();
      final result = Evaluator.evaluate(
        prev: PerformancePoint(weight: 60, reps: 10, date: now.subtract(const Duration(days: 7))),
        curr: PerformancePoint(weight: 50, reps: 10, date: now),
      );
      expect(result.code, 'dn');
    });

    test('weight increased with same or more reps → s1', () {
      final now = DateTime.now();
      final result = Evaluator.evaluate(
        prev: PerformancePoint(weight: 50, reps: 10, date: now.subtract(const Duration(days: 7))),
        curr: PerformancePoint(weight: 55, reps: 10, date: now),
      );
      expect(result.code, 's1');
    });
  });

  group('3-Week Stagnation Detection', () {
    test('detects stagnation when last 3 distinct weeks match', () {
      final now = DateTime.now();
      final history = [
        WorkoutLogEntry(
          id: '1', userId: 'u', exerciseId: 'e', exerciseName: 'Bench',
          date: now.subtract(const Duration(days: 21)),
          sets: const [SetRecord(weight: 50, reps: 10)],
        ),
        WorkoutLogEntry(
          id: '2', userId: 'u', exerciseId: 'e', exerciseName: 'Bench',
          date: now.subtract(const Duration(days: 14)),
          sets: const [SetRecord(weight: 50, reps: 10)],
        ),
        WorkoutLogEntry(
          id: '3', userId: 'u', exerciseId: 'e', exerciseName: 'Bench',
          date: now.subtract(const Duration(days: 7)),
          sets: const [SetRecord(weight: 50, reps: 10)],
        ),
      ];
      expect(Evaluator.isStagnant3Weeks(history), isTrue);
    });

    test('returns false with fewer than 3 entries', () {
      final history = [
        WorkoutLogEntry(
          id: '1', userId: 'u', exerciseId: 'e', exerciseName: 'Bench',
          date: DateTime.now(),
          sets: const [SetRecord(weight: 50, reps: 10)],
        ),
      ];
      expect(Evaluator.isStagnant3Weeks(history), isFalse);
    });
  });

  group('PR Detection', () {
    test('detects new PR when current exceeds all history', () {
      final history = [
        WorkoutLogEntry(
          id: '1', userId: 'u', exerciseId: 'e', exerciseName: 'Squat',
          date: DateTime.now().subtract(const Duration(days: 7)),
          sets: const [SetRecord(weight: 100, reps: 5)],
        ),
      ];
      expect(Evaluator.checkPR(history, 110, 5), isTrue);
      expect(Evaluator.checkPR(history, 90, 5), isFalse);
    });

    test('no PR possible with empty history', () {
      expect(Evaluator.checkPR([], 100, 5), isFalse);
    });
  });

  group('BMR Calculation (Mifflin-St Jeor)', () {
    test('male formula adds 5', () {
      final bmr = Evaluator.calcBMR(weight: 80, height: 180, age: 30, gender: 'male');
      // 10*80 + 6.25*180 - 5*30 + 5 = 800 + 1125 - 150 + 5 = 1780
      expect(bmr, 1780);
    });

    test('female formula subtracts 161', () {
      final bmr = Evaluator.calcBMR(weight: 60, height: 165, age: 25, gender: 'female');
      // 10*60 + 6.25*165 - 5*25 - 161 = 600 + 1031.25 - 125 - 161 = 1345.25 → 1345
      expect(bmr, closeTo(1345, 1));
    });
  });

  group('TDEE Calculation', () {
    test('sedentary multiplies by 1.2', () {
      expect(Evaluator.calcTDEE(1500, 'sedentary'), 1800);
    });

    test('moderate multiplies by 1.55', () {
      expect(Evaluator.calcTDEE(1500, 'moderate'), closeTo(2325, 1));
    });

    test('unknown key defaults to 1.55', () {
      expect(Evaluator.calcTDEE(1500, 'unknown_key'), closeTo(2325, 1));
    });
  });

  group('Macro Calculation', () {
    test('loseWeight produces 35/35/30 split', () {
      final macros = Evaluator.calcMacros(calories: 2000, goal: NutritionGoal.loseWeight);
      expect(macros.protein, closeTo(175, 2));   // 2000*0.35/4
      expect(macros.carbs,   closeTo(175, 2));   // 2000*0.35/4
      expect(macros.fat,     closeTo(67, 2));    // 2000*0.30/9
    });

    test('gainMuscle produces higher carb ratio', () {
      final macros = Evaluator.calcMacros(calories: 2500, goal: NutritionGoal.gainMuscle);
      expect(macros.carbs, greaterThan(macros.protein));
    });
  });

  group('Meal Text Parsing — parseMealText()', () {
    final foodDB = [
      const FoodItem(id: '1', name: 'صدر دجاج', calories: 165, protein: 31, carbs: 0, fat: 3.6, amount: 100),
      const FoodItem(id: '2', name: 'أرز أبيض', calories: 130, protein: 2.7, carbs: 28, fat: 0.3, amount: 100),
      const FoodItem(id: '3', name: 'بيض', calories: 155, protein: 13, carbs: 1.1, fat: 11, amount: 100),
    ];

    test('parses simple gram-based entry', () {
      final result = Evaluator.parseMealText(text: '150 صدر دجاج', foodDB: foodDB);
      expect(result.items.length, 1);
      expect(result.items.first.foodName, 'صدر دجاج');
      // 165 * 1.5 = 247.5
      expect(result.totalCalories, closeTo(247.5, 1));
    });

    test('parses multiple lines', () {
      final result = Evaluator.parseMealText(
        text: '150 صدر دجاج\nكوب أرز أبيض',
        foodDB: foodDB,
      );
      expect(result.items.length, 2);
    });

    test('reports unmatched items', () {
      final result = Evaluator.parseMealText(text: 'عنصر_غير_موجود_تماما', foodDB: foodDB);
      expect(result.hasUnmatched, isTrue);
    });

    test('handles Arabic normalization (أ/ا confusion)', () {
      final result = Evaluator.parseMealText(text: '100 ارز ابيض', foodDB: foodDB);
      // يجب أن يتطابق مع "أرز أبيض" رغم اختلاف الألف
      expect(result.items.isNotEmpty, isTrue);
    });
  });

  group('Meal Suggestion', () {
    final foodDB = List.generate(20, (i) => FoodItem(
      id: '$i',
      name: 'Food $i',
      calories: 100.0 + i * 20,
      protein: 10.0 + i,
      carbs: 15,
      fat: 5,
      amount: 100,
    ));

    test('returns foods within calorie range', () {
      final results = Evaluator.suggestMeal(
        remainingCalories: 300,
        pref: MealSuggestionPref.bestMatch,
        foodDB: foodDB,
      );
      expect(results, isNotEmpty);
      expect(results.length, lessThanOrEqualTo(6));
    });

    test('empty foodDB returns empty list', () {
      final results = Evaluator.suggestMeal(
        remainingCalories: 300,
        pref: MealSuggestionPref.bestMatch,
        foodDB: [],
      );
      expect(results, isEmpty);
    });
  });

  group('Adjust By Amount', () {
    test('scales nutrition values proportionally', () {
      const food = FoodItem(id: '1', name: 'Test', calories: 100, protein: 10, carbs: 20, fat: 5, amount: 100);
      final adjusted = Evaluator.adjustByAmount(food, 200);
      expect(adjusted.calories, 200);
      expect(adjusted.protein, 20);
      expect(adjusted.amount, 200);
    });
  });

  group('Navy Body Fat Calculation', () {
    test('male formula requires waist and neck only', () {
      final result = BodyMeasurement.calcNavyBodyFat(
        gender: 'male', waistCm: 85, neckCm: 38, heightCm: 175,
      );
      expect(result, isNotNull);
      expect(result, greaterThan(0));
    });

    test('female formula requires hip too', () {
      final result = BodyMeasurement.calcNavyBodyFat(
        gender: 'female', waistCm: 75, neckCm: 32, heightCm: 165, hipCm: 95,
      );
      expect(result, isNotNull);
    });

    test('female without hip returns null', () {
      final result = BodyMeasurement.calcNavyBodyFat(
        gender: 'female', waistCm: 75, neckCm: 32, heightCm: 165,
      );
      expect(result, isNull);
    });
  });
}
