// apps/tobest/lib/features/nutrition/presentation/widgets/macro_ring.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/domain/entities/nutrition_entity.dart';
import 'package:tobest/features/nutrition/presentation/providers/nutrition_provider.dart';

/// حلقات الماكرو الدائرية
///
/// تعرض: سعرات، بروتين، كارب، دهون كـ Progress Rings
class MacroRing extends StatelessWidget {
  const MacroRing({
    super.key,
    required this.summary,
    required this.goal,
    required this.isRtl,
  });

  final MacroSummary? summary;
  final MacroResult? goal;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final calories = summary?.totalCalories ?? 0;
    final protein  = summary?.totalProtein ?? 0;
    final carbs    = summary?.totalCarbs ?? 0;
    final fat      = summary?.totalFat ?? 0;

    final goalCal  = goal?.calories ?? 2000;
    final goalPro  = goal?.protein  ?? 150;
    final goalCarb = goal?.carbs    ?? 200;
    final goalFat  = goal?.fat      ?? 65;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          children: [
            // ── الحلقة الرئيسية (السعرات) ─────────────────
            SizedBox(
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(160, 160),
                    painter: _RingPainter(
                      progress: (calories / goalCal).clamp(0, 1),
                      color:    AppColors.primary,
                      strokeWidth: 14,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        calories.toInt().toString(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color:      theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        isRtl ? 'كال / $goalCal' : 'kcal / $goalCal',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── أشرطة الماكرو ────────────────────────────
            Row(children: [
              Expanded(
                child: _MacroBar(
                  label:    isRtl ? 'بروتين' : 'Protein',
                  current:  protein,
                  goal:     goalPro.toDouble(),
                  color:    AppColors.info,
                  unit:     'g',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MacroBar(
                  label:    isRtl ? 'كارب' : 'Carbs',
                  current:  carbs,
                  goal:     goalCarb.toDouble(),
                  color:    AppColors.success,
                  unit:     'g',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MacroBar(
                  label:    isRtl ? 'دهون' : 'Fat',
                  current:  fat,
                  goal:     goalFat.toDouble(),
                  color:    AppColors.accent4,
                  unit:     'g',
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
    required this.unit,
  });
  final String label;
  final double current;
  final double goal;
  final Color color;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final theme    = Theme.of(context);

    return Column(children: [
      Text(label, style: theme.textTheme.labelSmall),
      const SizedBox(height: AppSpacing.xs),
      ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: LinearProgressIndicator(
          value:           progress,
          backgroundColor: color.withOpacity(0.15),
          valueColor:      AlwaysStoppedAnimation(color),
          minHeight:       8,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        '${current.toInt()}/$unit${goal.toInt()}',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ]);
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });
  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect   = Rect.fromCircle(center: center, radius: radius);

    // خلفية الحلقة
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color       = color.withOpacity(0.12)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap   = StrokeCap.round,
    );

    // الحلقة الممتلئة
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color       = color
        ..style       = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap   = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
