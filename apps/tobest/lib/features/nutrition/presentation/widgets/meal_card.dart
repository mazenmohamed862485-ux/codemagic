// apps/tobest/lib/features/nutrition/presentation/widgets/meal_card.dart

import 'package:flutter/material.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/domain/entities/nutrition_entity.dart';
import 'package:intl/intl.dart';

/// بطاقة وجبة يومية
class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.meal,
    required this.isRtl,
    required this.onDelete,
  });
  final MealEntry meal;
  final bool isRtl;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = DateFormat('h:mm a').format(meal.date);
    final mealLabel = _mealLabel(meal.mealType, isRtl);

    return Dismissible(
      key:       ValueKey(meal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color:     theme.colorScheme.error,
        padding:   const EdgeInsets.only(right: AppSpacing.base),
        child:     const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────
              Row(children: [
                Icon(_mealIcon(meal.mealType),
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  mealLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  timeStr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ]),

              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),

              // ── الماكرو الإجمالي ──────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MacroChip(
                    value: meal.totalCalories.toInt().toString(),
                    label: isRtl ? 'كال' : 'kcal',
                    color: AppColors.warning,
                  ),
                  _MacroChip(
                    value: '${meal.totalProtein.toInt()}g',
                    label: isRtl ? 'بروتين' : 'Protein',
                    color: AppColors.info,
                  ),
                  _MacroChip(
                    value: '${meal.totalCarbs.toInt()}g',
                    label: isRtl ? 'كارب' : 'Carbs',
                    color: AppColors.success,
                  ),
                  _MacroChip(
                    value: '${meal.totalFat.toInt()}g',
                    label: isRtl ? 'دهون' : 'Fat',
                    color: AppColors.accent4,
                  ),
                ],
              ),

              // ── قائمة الأطعمة ──────────────────────────────
              if (meal.items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  meal.items.map((i) =>
                      '${i.foodName} (${i.amount.toInt()}g)').join('، '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  maxLines:  2,
                  overflow:  TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _mealLabel(String type, bool isRtl) {
    final labels = {
      'breakfast': isRtl ? 'الفطور'     : 'Breakfast',
      'lunch':     isRtl ? 'الغداء'     : 'Lunch',
      'dinner':    isRtl ? 'العشاء'     : 'Dinner',
      'snack':     isRtl ? 'سناك'       : 'Snack',
      'custom':    isRtl ? 'وجبة مخصصة' : 'Custom Meal',
    };
    return labels[type] ?? type;
  }

  IconData _mealIcon(String type) {
    return switch (type) {
      'breakfast' => Icons.wb_sunny_outlined,
      'lunch'     => Icons.wb_cloudy_outlined,
      'dinner'    => Icons.nights_stay_outlined,
      'snack'     => Icons.cookie_outlined,
      _           => Icons.restaurant_outlined,
    };
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color:      color,
          fontSize:   AppTypography.bodyMd,
        ),
      ),
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    ]);
  }
}
