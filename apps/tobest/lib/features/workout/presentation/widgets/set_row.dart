// apps/tobest/lib/features/workout/presentation/widgets/set_row.dart

import 'package:flutter/material.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/domain/entities/workout_entity.dart';

/// صف السِت في قائمة السيتات المسجلة
///
/// يدعم التعديل المضمّن (Inline Edit) والحذف بالسحب
class SetRow extends StatelessWidget {
  const SetRow({
    super.key,
    required this.index,
    required this.set,
    required this.onEdit,
    required this.onDelete,
    required this.isRtl,
  });

  final int index;
  final SetRecord set;
  final void Function(double weight, int reps) onEdit;
  final VoidCallback onDelete;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final epley  = set.epley1RM;

    return Dismissible(
      key:        ValueKey('set_$index'),
      direction:  isRtl ? DismissDirection.endToStart : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color:     theme.colorScheme.error,
        padding:   const EdgeInsets.only(right: AppSpacing.base),
        child:     const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin:  const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical:   AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color:        theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Row(children: [
          // ── رقم السِت ─────────────────────────────────────
          Container(
            width:  28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withOpacity(0.12),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color:      theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // ── الوزن ────────────────────────────────────────
          Expanded(
            child: Text(
              isRtl
                  ? '${set.weight} كجم × ${set.reps}'
                  : '${set.weight} kg × ${set.reps}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // ── 1RM Epley ────────────────────────────────────
          if (epley != null && epley > 0)
            Text(
              '≈ ${epley.toInt()} 1RM',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),

          // ── RPE ──────────────────────────────────────────
          if (set.rpe != null)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: Text(
                'RPE ${set.rpe}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
