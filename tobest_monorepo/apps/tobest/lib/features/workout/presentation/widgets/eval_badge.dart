// apps/tobest/lib/features/workout/presentation/widgets/eval_badge.dart

import 'package:flutter/material.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/domain/entities/workout_entity.dart';

/// شارة التقييم الملونة
///
/// تظهر فوراً عند إدخال الوزن والتكرارات
class EvalBadge extends StatelessWidget {
  const EvalBadge({super.key, required this.result, required this.isRtl});

  final EvalResult result;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor) = _colors(result.code);
    final label = isRtl ? result.labelAr : result.labelEn;

    return AnimatedSwitcher(
      duration: AppDurations.normal,
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: anim,
        child: child,
      ),
      child: Container(
        key:     ValueKey(result.code),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical:   AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color:        bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow:    AppShadows.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icon(result.code),
              size:  18,
              color: textColor,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                color:      textColor,
                fontWeight: FontWeight.w700,
                fontSize:   AppTypography.labelMd,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color bg, Color text) _colors(String code) {
    return switch (code) {
      's1' => (AppColors.primary, Colors.white),
      's2' => (AppColors.success, Colors.white),
      's3' => (AppColors.info, Colors.white),
      'rv' => (AppColors.accent2, Colors.white),
      'gd' => (AppColors.primaryLight.withOpacity(0.2), AppColors.primary),
      'st' => (AppColors.warning.withOpacity(0.15), AppColors.warning),
      'ws' => (AppColors.warning.withOpacity(0.25), AppColors.warning),
      'dn' => (AppColors.error.withOpacity(0.15), AppColors.error),
      _    => (Colors.grey.withOpacity(0.15), Colors.grey),
    };
  }

  IconData _icon(String code) {
    return switch (code) {
      's1' => Icons.emoji_events,
      's2' => Icons.star,
      's3' => Icons.thumb_up,
      'rv' => Icons.trending_up,
      'gd' => Icons.check_circle,
      'st' => Icons.remove_circle_outline,
      'ws' => Icons.warning_amber,
      'dn' => Icons.arrow_circle_down,
      _    => Icons.play_circle_outline,
    };
  }
}
