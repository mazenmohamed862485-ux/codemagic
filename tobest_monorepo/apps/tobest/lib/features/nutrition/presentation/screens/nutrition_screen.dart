// apps/tobest/lib/features/nutrition/presentation/screens/nutrition_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/domain/entities/nutrition_entity.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:shared/infrastructure/isar_service.dart';
import 'package:shared/utils/evaluator.dart';
import 'package:tobest/features/auth/presentation/providers/auth_provider.dart';
import 'package:tobest/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:tobest/features/nutrition/presentation/widgets/macro_ring.dart';
import 'package:tobest/features/nutrition/presentation/widgets/meal_card.dart';
import 'package:tobest/features/nutrition/presentation/widgets/food_search_delegate.dart';

part 'nutrition_screen.g.dart';

/// شاشة التغذية
///
/// الميزات:
/// - حلقات الماكرو الدائرية (Macro Rings)
/// - قائمة وجبات اليوم
/// - محلل النص العربي (parseMealText)
/// - البحث في قاعدة الأطعمة
/// - اقتراح وجبة بناءً على السعرات المتبقية
class NutritionScreen extends HookConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync  = ref.watch(todayMealsProvider);
    final macroSumary = ref.watch(todayMacroSummaryProvider);
    final goal        = ref.watch(dailyMacroGoalProvider);
    final theme       = Theme.of(context);
    final isRtl       = Directionality.of(context) == TextDirection.rtl;
    final tabController = useTabController(initialLength: 2);

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'التغذية' : 'Nutrition'),
        actions: [
          // ── اقتراح وجبة ──────────────────────────────────
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: isRtl ? 'اقتراح وجبة' : 'Suggest Meal',
            onPressed: () => _showMealSuggestion(context, ref, isRtl),
          ),
          // ── البحث في الأطعمة ──────────────────────────────
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(
              context: context,
              delegate: FoodSearchDelegate(ref: ref, isRtl: isRtl),
            ),
          ),
        ],
        bottom: TabBar(
          controller: tabController,
          tabs: [
            Tab(text: isRtl ? 'اليوم' : 'Today'),
            Tab(text: isRtl ? 'تحليل النص' : 'Text Parser'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          // ── تبويب اليوم ──────────────────────────────────
          _TodayTab(
            mealsAsync:  mealsAsync,
            macroSumary: macroSumary,
            goal:        goal,
            isRtl:       isRtl,
            ref:         ref,
          ),
          // ── تبويب محلل النص ───────────────────────────────
          _TextParserTab(isRtl: isRtl, ref: ref),
        ],
      ),
    );
  }

  void _showMealSuggestion(BuildContext context, WidgetRef ref, bool isRtl) {
    final macroSummary = ref.read(todayMacroSummaryProvider).valueOrNull;
    final goal         = ref.read(dailyMacroGoalProvider).valueOrNull;
    if (goal == null) return;

    final remaining = goal.calories - (macroSummary?.totalCalories ?? 0);
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          isRtl ? 'لقد استكملت سعراتك اليوم ✓' : 'You reached your calorie goal ✓',
        ),
        backgroundColor: AppColors.success,
      ));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _MealSuggestionSheet(
        remainingCalories: remaining.toDouble(),
        isRtl: isRtl,
        ref: ref,
      ),
    );
  }
}

// ── تبويب اليوم ──────────────────────────────────────────────

class _TodayTab extends StatelessWidget {
  const _TodayTab({
    required this.mealsAsync,
    required this.macroSumary,
    required this.goal,
    required this.isRtl,
    required this.ref,
  });

  final AsyncValue<List<MealEntry>> mealsAsync;
  final AsyncValue<MacroSummary?> macroSumary;
  final AsyncValue<MacroResult?> goal;
  final bool isRtl;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── حلقات الماكرو ─────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: MacroRing(
              summary: macroSumary.valueOrNull,
              goal:    goal.valueOrNull,
              isRtl:   isRtl,
            ),
          ),
        ),

        // ── قائمة الوجبات ─────────────────────────────────
        mealsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SliverToBoxAdapter(
            child: Center(
              child: Text('$e',
                  style: TextStyle(color: Colors.red.shade400)),
            ),
          ),
          data: (meals) {
            if (meals.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: Text(
                      isRtl ? 'لا وجبات اليوم بعد' : 'No meals logged yet',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: MealCard(
                      meal:     meals[i],
                      isRtl:    isRtl,
                      onDelete: () => ref
                          .read(nutritionActionsProvider.notifier)
                          .deleteMeal(meals[i].id),
                    ),
                  ),
                  childCount: meals.length,
                ),
              ),
            );
          },
        ),

        const SliverPadding(
            padding: EdgeInsets.only(bottom: AppSpacing.xxxl)),
      ],
    );
  }
}

// ── تبويب محلل النص ──────────────────────────────────────────

class _TextParserTab extends HookWidget {
  const _TextParserTab({required this.isRtl, required this.ref});
  final bool isRtl;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final result     = useState<MealParseResult?>(null);
    final isLoading  = useState(false);
    final theme      = Theme.of(context);

    Future<void> onParse() async {
      if (controller.text.trim().isEmpty) return;
      isLoading.value = true;

      try {
        // جلب قاعدة الأطعمة كاملة من قاعدة البيانات المحلية
        final isar  = await ref.read(isarServiceProvider.future);
        final rows  = await isar.getAllFoods();
        final foodEntities = rows.map(FoodItem.fromDbRow).toList();

        result.value = Evaluator.parseMealText(
          text:   controller.text.trim(),
          foodDB: foodEntities,
        );
      } finally {
        isLoading.value = false;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── تعليمات ─────────────────────────────────────
          Card(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                isRtl
                    ? 'اكتب وجبتك بشكل طبيعي، مثال:\n'
                      '2 بيضة\n'
                      'كوب أرز\n'
                      '150 جرام صدر دجاج مشوي\n'
                      'ملعقة كبيرة زيت زيتون'
                    : 'Write your meal naturally, e.g.:\n'
                      '2 eggs\n'
                      '1 cup rice\n'
                      '150g grilled chicken breast\n'
                      '1 tbsp olive oil',
                style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── حقل النص ─────────────────────────────────────
          TextField(
            controller:  controller,
            maxLines:    8,
            keyboardType: TextInputType.multiline,
            textAlign:   isRtl ? TextAlign.right : TextAlign.left,
            decoration: InputDecoration(
              hintText:    isRtl ? 'اكتب وجبتك هنا...' : 'Write your meal here...',
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          FilledButton.icon(
            onPressed: isLoading.value ? null : onParse,
            icon: isLoading.value
                ? const SizedBox(
                    width:  16,
                    height: 16,
                    child:  CircularProgressIndicator(
                      strokeWidth: 2,
                      color:       Colors.white,
                    ),
                  )
                : const Icon(Icons.calculate),
            label: Text(isRtl ? 'تحليل الوجبة' : 'Analyze Meal'),
          ),

          // ── نتائج التحليل ──────────────────────────────
          if (result.value != null) ...[
            const SizedBox(height: AppSpacing.xl),
            _ParseResultCard(result: result.value!, isRtl: isRtl, ref: ref),
          ],
        ],
      ),
    );
  }
}

// ── بطاقة نتائج التحليل ──────────────────────────────────────

class _ParseResultCard extends StatelessWidget {
  const _ParseResultCard({
    required this.result,
    required this.isRtl,
    required this.ref,
  });
  final MealParseResult result;
  final bool isRtl;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── الإجماليات ────────────────────────────────
            Text(
              isRtl ? 'نتائج التحليل' : 'Analysis Results',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ResultItem(
                  label: isRtl ? 'سعرات' : 'Cal',
                  value: result.totalCalories.toInt().toString(),
                  color: AppColors.warning,
                ),
                _ResultItem(
                  label: isRtl ? 'بروتين' : 'Pro',
                  value: '${result.totalProtein.toInt()}g',
                  color: AppColors.info,
                ),
                _ResultItem(
                  label: isRtl ? 'كارب' : 'Carb',
                  value: '${result.totalCarbs.toInt()}g',
                  color: AppColors.success,
                ),
                _ResultItem(
                  label: isRtl ? 'دهون' : 'Fat',
                  value: '${result.totalFat.toInt()}g',
                  color: AppColors.accent4,
                ),
              ],
            ),

            // ── عناصر غير معروفة ──────────────────────────
            if (result.hasUnmatched) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              Text(
                isRtl ? 'غير معروف:' : 'Unrecognized:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              Text(
                result.unmatched.join(', '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error.withOpacity(0.8),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // ── زر الحفظ ──────────────────────────────────
            FilledButton.icon(
              onPressed: () {
                ref
                    .read(nutritionActionsProvider.notifier)
                    .saveParsedMeal(result);
                Navigator.of(context).pop();
              },
              icon:  const Icon(Icons.save),
              label: Text(isRtl ? 'حفظ الوجبة' : 'Save Meal'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultItem extends StatelessWidget {
  const _ResultItem({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(
        value,
        style: TextStyle(
          fontSize:   AppTypography.titleSm,
          fontWeight: FontWeight.w700,
          color:      color,
        ),
      ),
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    ]);
  }
}

// ── Bottom Sheet اقتراح وجبة ──────────────────────────────────

class _MealSuggestionSheet extends HookConsumerWidget {
  const _MealSuggestionSheet({
    required this.remainingCalories,
    required this.isRtl,
    required this.ref,
  });
  final double remainingCalories;
  final bool isRtl;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef innerRef) {
    final pref      = useState(MealSuggestionPref.bestMatch);
    final isLoading = useState(false);
    final suggestions = useState<List<FoodItem>>([]);
    final theme     = Theme.of(context);

    Future<void> getSuggestions() async {
      isLoading.value = true;
      try {
        final isar  = await innerRef.read(isarServiceProvider.future);
        final rows  = await isar.getAllFoods();
        final db    = rows.map(FoodItem.fromDbRow).toList();

        suggestions.value = Evaluator.suggestMeal(
          remainingCalories: remainingCalories,
          pref:              pref.value,
          foodDB:            db,
        );
      } finally {
        isLoading.value = false;
      }
    }

    return DraggableScrollableSheet(
      expand:          false,
      initialChildSize: 0.6,
      maxChildSize:     0.9,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color:        theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
        child: Column(
          children: [
            // ── Handle ────────────────────────────────────
            Container(
              margin:     const EdgeInsets.symmetric(vertical: AppSpacing.md),
              width:      40,
              height:     4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Column(children: [
                Text(
                  isRtl
                      ? 'اقتراح وجبة — ${remainingCalories.toInt()} كال متبقية'
                      : 'Meal Suggestion — ${remainingCalories.toInt()} kcal remaining',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ── اختيار التفضيل ────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: MealSuggestionPref.values.map((p) {
                      final labels = {
                        MealSuggestionPref.bestMatch:  isRtl ? 'الأنسب'     : 'Best',
                        MealSuggestionPref.cheapest:   isRtl ? 'الأرخص'    : 'Cheapest',
                        MealSuggestionPref.bestProtein:isRtl ? 'بروتين أعلى': 'High Protein',
                        MealSuggestionPref.lightest:   isRtl ? 'الأخف'     : 'Lightest',
                        MealSuggestionPref.cleanest:   isRtl ? 'الأنظف'    : 'Cleanest',
                      };
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label:    Text(labels[p]!),
                          selected: pref.value == p,
                          onSelected: (_) => pref.value = p,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                FilledButton.icon(
                  onPressed: isLoading.value ? null : getSuggestions,
                  icon:  const Icon(Icons.auto_awesome),
                  label: Text(isRtl ? 'اقترح' : 'Suggest'),
                ),
              ]),
            ),

            // ── قائمة الاقتراحات ──────────────────────────
            Expanded(
              child: isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      controller:    scrollCtrl,
                      padding:       const EdgeInsets.all(AppSpacing.base),
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemCount: suggestions.value.length,
                      itemBuilder: (ctx, i) {
                        final food = suggestions.value[i];
                        return ListTile(
                          title: Text(food.name),
                          subtitle: Text(
                            isRtl
                                ? '${food.amount.toInt()}جم • '
                                  '${food.calories.toInt()} كال'
                                : '${food.amount.toInt()}g • '
                                  '${food.calories.toInt()} kcal',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle),
                            onPressed: () {
                              innerRef
                                  .read(nutritionActionsProvider.notifier)
                                  .addSuggestedFood(food);
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
