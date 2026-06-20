// apps/tobest/lib/features/home/presentation/widgets/home_widgets.dart
//
// إصلاح: كل الـ imports المبعثرة وسط الملف (خطأ Dart syntax) جُمعت بالأعلى
// يحتوي: DailySummaryCard, QuickActionsRow, StreakHeatmap, TodayWorkoutCard

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/design/tokens.dart';
import 'package:tobest/features/health/presentation/providers/health_provider.dart';
import 'package:tobest/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:tobest/router.dart';

/// بطاقة ملخص اليوم: سعرات، بروتين، خطوات، نوم
class DailySummaryCard extends ConsumerWidget {
  const DailySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayMacros = ref.watch(todayMacroSummaryProvider);
    final todaySteps  = ref.watch(todayStepsProvider);
    final theme       = Theme.of(context);
    final isRtl       = Directionality.of(context) == TextDirection.rtl;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRtl ? 'ملخص اليوم' : "Today's Summary",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              Expanded(
                child: _MetricTile(
                  label: isRtl ? 'سعرات' : 'Cal',
                  value: todayMacros.when(
                    data:    (m) => '${m?.totalCalories.toInt() ?? 0}',
                    loading: () => '—',
                    error:   (_, __) => '—',
                  ),
                  unit:  isRtl ? 'كال' : 'kcal',
                  icon:  Icons.local_fire_department,
                  color: AppColors.warning,
                ),
              ),
              Expanded(
                child: _MetricTile(
                  label: isRtl ? 'بروتين' : 'Protein',
                  value: todayMacros.when(
                    data:    (m) => '${m?.totalProtein.toInt() ?? 0}',
                    loading: () => '—',
                    error:   (_, __) => '—',
                  ),
                  unit:  isRtl ? 'جم' : 'g',
                  icon:  Icons.egg_outlined,
                  color: AppColors.info,
                ),
              ),
              Expanded(
                child: _MetricTile(
                  label: isRtl ? 'خطوات' : 'Steps',
                  value: todaySteps.when(
                    data:    (s) => '${s?.steps ?? 0}',
                    loading: () => '—',
                    error:   (_, __) => '—',
                  ),
                  unit:  '',
                  icon:  Icons.directions_walk,
                  color: AppColors.success,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Icon(icon, color: color, size: AppSpacing.iconMd),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      if (unit.isNotEmpty) Text(unit, style: theme.textTheme.labelSmall),
      Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    ]);
  }
}

/// صف الإجراءات السريعة في الرئيسية
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _QuickAction(
          icon: Icons.fitness_center,
          label: isRtl ? 'تمرين' : 'Workout',
          color: AppColors.primary,
          onTap: () => context.go(AppRoutes.workout),
        ),
        _QuickAction(
          icon: Icons.restaurant,
          label: isRtl ? 'وجبة' : 'Meal',
          color: AppColors.info,
          onTap: () => context.go(AppRoutes.nutrition),
        ),
        _QuickAction(
          icon: Icons.bedtime_outlined,
          label: isRtl ? 'نوم' : 'Sleep',
          color: AppColors.accent1,
          onTap: () => context.push(AppRoutes.sleepLog),
        ),
        _QuickAction(
          icon: Icons.straighten,
          label: isRtl ? 'قياسات' : 'Measure',
          color: AppColors.accent3,
          onTap: () => context.push(AppRoutes.measurements),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ]),
      ),
    );
  }
}

/// Heatmap الانتظام — 4 أسابيع × 7 أيام
class StreakHeatmap extends StatelessWidget {
  const StreakHeatmap({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: 28,
      itemBuilder: (context, i) => _HeatCell(intensity: i % 4),
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({required this.intensity});
  final int intensity;

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.heatmapEmpty,
      AppColors.heatmapLight,
      AppColors.heatmapMedium,
      AppColors.heatmapDark,
    ];
    return Container(
      decoration: BoxDecoration(
        color: colors[intensity],
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

/// بطاقة تمرين اليوم في الرئيسية
class TodayWorkoutCard extends StatelessWidget {
  const TodayWorkoutCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Card(
      child: InkWell(
        onTap: () => context.go(AppRoutes.workout),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(Icons.fitness_center, color: theme.colorScheme.primary, size: 32),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRtl ? 'تمرين اليوم' : "Today's Workout",
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    isRtl ? 'اضغط للبدء' : 'Tap to start',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(isRtl ? Icons.arrow_back_ios : Icons.arrow_forward_ios, size: 16),
          ]),
        ),
      ),
    );
  }
}
