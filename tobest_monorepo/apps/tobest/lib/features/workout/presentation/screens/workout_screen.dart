// apps/tobest/lib/features/workout/presentation/screens/workout_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/design/widgets/breathing_animation.dart';
import 'package:shared/domain/entities/workout_entity.dart';
import 'package:shared/utils/evaluator.dart';
import 'package:tobest/features/workout/presentation/providers/workout_provider.dart';
import 'package:tobest/features/workout/presentation/widgets/eval_badge.dart';
import 'package:tobest/features/workout/presentation/widgets/set_row.dart';
import 'package:tobest/features/workout/presentation/widgets/video_carousel.dart';

/// شاشة التمارين — محور التطبيق
///
/// تدفق الاستخدام:
/// 1. قائمة تمارين اليوم (Accordion)
/// 2. فتح تمرين → Carousel الفيديو + Carousel تفاصيل التمرين
/// 3. تسجيل السيتات مع التقييم الفوري
/// 4. Rest Timer مع Breathing Animation
/// 5. حفظ الجلسة محلياً + GAS
class WorkoutScreen extends HookConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(todayExercisesProvider);
    final session        = ref.watch(activeWorkoutSessionProvider);
    final theme          = Theme.of(context);
    final isRtl          = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'تمارين اليوم' : "Today's Workout"),
        actions: [
          if (session.isActive)
            TextButton.icon(
              icon:  const Icon(Icons.check),
              label: Text(isRtl ? 'إنهاء' : 'Finish'),
              onPressed: () => _showFinishDialog(context, ref, isRtl),
            ),
        ],
      ),
      body: exercisesAsync.when(
        loading: () => const Center(child: BreathingAnimation(size: 80, showText: false)),
        error:   (e, _) => _ErrorView(error: e, isRtl: isRtl),
        data: (exercises) {
          if (exercises.isEmpty) return _EmptyWorkoutView(isRtl: isRtl);
          return _ExerciseList(exercises: exercises, isRtl: isRtl);
        },
      ),
    );
  }

  Future<void> _showFinishDialog(
      BuildContext context, WidgetRef ref, bool isRtl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRtl ? 'إنهاء الجلسة؟' : 'Finish Session?'),
        content: Text(
          isRtl
              ? 'سيتم حفظ جميع التمارين المسجلة.'
              : 'All logged exercises will be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: Text(isRtl ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => ctx.pop(true),
            child: Text(isRtl ? 'حفظ وإنهاء' : 'Save & Finish'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(activeWorkoutSessionProvider.notifier).finishSession(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isRtl ? 'تم حفظ الجلسة ✓' : 'Session saved ✓'),
          backgroundColor: AppColors.success,
        ));
      }
    }
  }
}

// ── قائمة التمارين بـ Accordion ──────────────────────────────

class _ExerciseList extends StatelessWidget {
  const _ExerciseList({required this.exercises, required this.isRtl});
  final List<ExerciseEntity> exercises;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    // تجميع التمارين: رئيسية ثم مساعدة
    final primary   = exercises.where((e) => e.isPrimary).toList();
    final secondary = exercises.where((e) => !e.isPrimary).toList();

    return CustomScrollView(
      slivers: [
        // ── التمارين الرئيسية ──────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.base, AppSpacing.base, AppSpacing.base, 0),
          sliver: SliverToBoxAdapter(
            child: Text(
              isRtl ? 'التمارين الرئيسية' : 'Primary Exercises',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.base),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ExerciseCard(exercise: primary[i], isRtl: isRtl),
              ),
              childCount: primary.length,
            ),
          ),
        ),

        // ── التمارين المساعدة ──────────────────────────────
        if (secondary.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.base, 0, AppSpacing.base, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                isRtl ? 'التمارين المساعدة' : 'Accessory Exercises',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.base),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child:
                      _ExerciseCard(exercise: secondary[i], isRtl: isRtl),
                ),
                childCount: secondary.length,
              ),
            ),
          ),
        ],

        const SliverPadding(
            padding: EdgeInsets.only(bottom: AppSpacing.xxxl)),
      ],
    );
  }
}

// ── بطاقة تمرين واحد (Accordion) ─────────────────────────────

class _ExerciseCard extends HookConsumerWidget {
  const _ExerciseCard({required this.exercise, required this.isRtl});
  final ExerciseEntity exercise;
  final bool isRtl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded  = useState(false);
    final showRest    = useState(false);
    final restSeconds = useState(180);
    final weightCtrl  = useTextEditingController();
    final repsCtrl    = useTextEditingController();
    final session     = ref.watch(activeWorkoutSessionProvider);
    final theme       = Theme.of(context);

    // تقييم فوري بناءً على المدخلات
    final currWeight = double.tryParse(weightCtrl.text) ?? 0;
    final currReps   = int.tryParse(repsCtrl.text) ?? 0;
    final evalResult = ref.watch(liveEvaluationProvider(
      exerciseId:    exercise.id,
      currentWeight: currWeight,
      currentReps:   currReps,
      now:           DateTime.now(),
    ));

    // اقتراح الوزن
    final suggestion = ref.watch(repSuggestionProvider(currReps));

    return AnimatedContainer(
      duration: AppDurations.normal,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isExpanded.value
              ? theme.colorScheme.primary.withOpacity(0.4)
              : theme.colorScheme.outline.withOpacity(0.2),
          width: isExpanded.value ? 1.5 : 1,
        ),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────
          InkWell(
            onTap:       () => isExpanded.value = !isExpanded.value,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(children: [
                // مؤشر التمرين الرئيسي
                Container(
                  width:  4,
                  height: 40,
                  decoration: BoxDecoration(
                    color:        exercise.isPrimary
                        ? theme.colorScheme.primary
                        : theme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${exercise.muscle} • ${exercise.repRange ?? ''} reps',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(isExpanded.value
                    ? Icons.expand_less
                    : Icons.expand_more),
              ]),
            ),
          ),

          // ── المحتوى المنسدل ──────────────────────────────
          if (isExpanded.value)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: Column(
                children: [
                  const Divider(),

                  // ── فيديو التمرين ────────────────────────
                  if (exercise.videoIds.isNotEmpty)
                    VideoCarousel(
                      exerciseId: exercise.id,
                      videoIds:   exercise.videoIds,
                    ),

                  const SizedBox(height: AppSpacing.md),

                  // ── معلومات التمرين ──────────────────────
                  _ExerciseInfo(exercise: exercise, isRtl: isRtl),

                  const SizedBox(height: AppSpacing.md),

                  // ── السيتات المسجلة ──────────────────────
                  if (session.isActive && session.exercise?.id == exercise.id)
                    ...session.sets.asMap().entries.map(
                          (e) => SetRow(
                            index:    e.key,
                            set:      e.value,
                            onEdit:   (w, r) => ref
                                .read(activeWorkoutSessionProvider.notifier)
                                .editSet(e.key, weight: w, reps: r),
                            onDelete: () => ref
                                .read(activeWorkoutSessionProvider.notifier)
                                .removeSet(e.key),
                            isRtl: isRtl,
                          ),
                        ),

                  const SizedBox(height: AppSpacing.md),

                  // ── مدخلات السِت الجديد ───────────────────
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller:   weightCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: isRtl ? 'الوزن (كجم)' : 'Weight (kg)',
                          isDense:   true,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextField(
                        controller:   repsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isRtl ? 'التكرارات' : 'Reps',
                          isDense:   true,
                        ),
                      ),
                    ),
                  ]),

                  // ── اقتراح الوزن ─────────────────────────
                  if (suggestion != null)
                    AnimatedSwitcher(
                      duration: AppDurations.normal,
                      child: Container(
                        key:    ValueKey(suggestion.type),
                        margin: const EdgeInsets.only(top: AppSpacing.sm),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical:   AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: suggestion.type == 'up'
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.warning.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              suggestion.type == 'up'
                                  ? Icons.arrow_circle_up
                                  : Icons.arrow_circle_down,
                              size: 16,
                              color: suggestion.type == 'up'
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              suggestion.type == 'up'
                                  ? (isRtl ? 'ارفع الوزن 💪' : 'Increase weight 💪')
                                  : (isRtl ? 'انزل الوزن' : 'Decrease weight'),
                              style: theme.textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── شارة التقييم الفوري ───────────────────
                  if (evalResult != null && currWeight > 0 && currReps > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: EvalBadge(result: evalResult, isRtl: isRtl),
                    ),

                  const SizedBox(height: AppSpacing.md),

                  // ── أزرار التحكم ─────────────────────────
                  Row(children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          final w = double.tryParse(weightCtrl.text);
                          final r = int.tryParse(repsCtrl.text);
                          if (w == null || r == null) return;

                          // بدء الجلسة إذا لم تكن مبدوءة
                          if (!session.isActive) {
                            ref
                                .read(activeWorkoutSessionProvider.notifier)
                                .startSession(exercise);
                          }

                          ref
                              .read(activeWorkoutSessionProvider.notifier)
                              .addSet(weight: w, reps: r);

                          weightCtrl.clear();
                          repsCtrl.clear();

                          // فرض الراحة بعد السِت
                          showRest.value = true;
                        },
                        icon:  const Icon(Icons.add),
                        label: Text(isRtl ? 'إضافة سِت' : 'Add Set'),
                      ),
                    ),
                  ]),

                  // ── Rest Timer ────────────────────────────
                  if (showRest.value)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Card(
                        color: theme.colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: RestTimerWidget(
                            durationSeconds: restSeconds.value,
                            isRtl:           isRtl,
                            onComplete: () => showRest.value = false,
                            onSkip:     () => showRest.value = false,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── معلومات التمرين ───────────────────────────────────────────

class _ExerciseInfo extends StatelessWidget {
  const _ExerciseInfo({required this.exercise, required this.isRtl});
  final ExerciseEntity exercise;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing:  AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        if (exercise.warmupSets != null)
          _InfoChip(
            label: isRtl
                ? 'إحماء: ${exercise.warmupSets}'
                : 'Warmup: ${exercise.warmupSets}',
            color: AppColors.warning,
          ),
        if (exercise.targetSets != null)
          _InfoChip(
            label: isRtl
                ? '${exercise.targetSets} سيتات'
                : '${exercise.targetSets} sets',
            color: theme.colorScheme.primary,
          ),
        if (exercise.repRange != null)
          _InfoChip(
            label: isRtl
                ? '${exercise.repRange} تكرار'
                : '${exercise.repRange} reps',
            color: AppColors.info,
          ),
        if (exercise.restRange != null)
          _InfoChip(
            label: isRtl
                ? 'راحة: ${exercise.restRange} دقيقة'
                : 'Rest: ${exercise.restRange} min',
            color: AppColors.accent2,
          ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border:       Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── حالات الخطأ والفراغ ───────────────────────────────────────

class _EmptyWorkoutView extends StatelessWidget {
  const _EmptyWorkoutView({required this.isRtl});
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available,
                size: 80,
                color: theme.colorScheme.primary.withOpacity(0.4)),
            const SizedBox(height: AppSpacing.xl),
            Text(
              isRtl ? 'لا تمارين اليوم 🎉' : 'Rest Day 🎉',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isRtl
                  ? 'استرح وكن مستعداً للغد!'
                  : 'Rest up and get ready for tomorrow!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.isRtl});
  final Object error;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        isRtl ? 'فشل التحميل: $error' : 'Load failed: $error',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
