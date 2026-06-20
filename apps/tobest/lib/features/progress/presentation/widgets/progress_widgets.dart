// apps/tobest/lib/features/progress/presentation/widgets/progress_widgets.dart
//
// إصلاح: imports مبعثرة وسط الملف (خطأ Dart syntax) جُمعت بالأعلى
// إصلاح: part directive كانت 'pr_list.g.dart' (لا تطابق اسم هذا الملف) → صُحِّحت
// يحتوي: StepsChart, BodyChart, PRList

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/domain/entities/health_entity.dart';
import 'package:shared/domain/entities/workout_entity.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:tobest/features/auth/presentation/providers/auth_provider.dart';

part 'progress_widgets.g.dart';

/// مخطط الخطوات الأسبوعي
class StepsChart extends StatelessWidget {
  const StepsChart({super.key, required this.records, required this.isRtl});
  final List<StepsRecord> records;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(child: Text(isRtl ? 'لا بيانات بعد' : 'No data yet')),
      );
    }

    final maxSteps = records.map((r) => r.steps).reduce((a, b) => a > b ? a : b).toDouble();

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: records.map((r) {
          final pct = maxSteps > 0 ? r.steps / maxSteps : 0.0;
          final day = DateFormat('EEE', isRtl ? 'ar' : 'en').format(r.date);
          final color = r.steps >= 8000
              ? AppColors.primary
              : r.steps >= 5000
                  ? AppColors.accent3
                  : AppColors.accent5.withOpacity(0.4);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(_compactNum(r.steps),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: FractionallySizedBox(
                      heightFactor: pct.clamp(0.05, 1.0),
                      child: Container(color: color),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(day, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _compactNum(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

/// مخطط تغير الوزن وقياسات الجسم
class BodyChart extends ConsumerWidget {
  const BodyChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRtl ? 'تتبع الوزن' : 'Weight Progress',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 140,
              child: Center(
                child: Text(
                  isRtl ? 'سجّل قياساتك لعرض الرسم البياني' : 'Log measurements to see chart',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@riverpod
Future<List<PRRecord>> topPRs(Ref ref) async {
  final userId = ref.watch(authStateProvider).valueOrNull?.id;
  if (userId == null) return [];

  try {
    final gas  = await ref.read(gasClientProvider.future);
    final resp = await gas.get<Map<String, dynamic>>('/workout/prs/$userId');
    final list = resp.data?['prs'] as List<dynamic>? ?? [];
    return list
        .map((p) => PRRecord(
              exerciseId:   p['exerciseId'] as String,
              exerciseName: p['exerciseName'] as String,
              weight:       (p['weight'] as num).toDouble(),
              reps:         p['reps'] as int,
              epley1RM:     (p['epley1RM'] as num).toDouble(),
              date:         DateTime.parse(p['date'] as String),
            ))
        .toList();
  } catch (_) {
    return [];
  }
}

/// قائمة أفضل الأرقام القياسية
class PRList extends ConsumerWidget {
  const PRList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prsAsync = ref.watch(topPRsProvider);
    final theme     = Theme.of(context);
    final isRtl     = Directionality.of(context) == TextDirection.rtl;

    return prsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('$e')),
      data: (prs) {
        if (prs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events, size: 64, color: theme.colorScheme.primary.withOpacity(0.3)),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    isRtl ? 'لا أرقام قياسية بعد\nابدأ بالتمرين!' : 'No PRs yet\nStart working out!',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.base),
          itemCount: prs.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            final pr = prs[i];
            return Card(
              child: ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == 0
                        ? const Color(0xFFFFD700).withOpacity(0.15)
                        : i == 1
                            ? const Color(0xFFC0C0C0).withOpacity(0.15)
                            : i == 2
                                ? const Color(0xFFCD7F32).withOpacity(0.15)
                                : theme.colorScheme.primary.withOpacity(0.1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: i == 0
                          ? const Color(0xFFFFD700)
                          : i == 1
                              ? const Color(0xFF808080)
                              : i == 2
                                  ? const Color(0xFFCD7F32)
                                  : theme.colorScheme.primary,
                    ),
                  ),
                ),
                title: Text(pr.exerciseName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  isRtl ? '${pr.weight} كجم × ${pr.reps} تكرار' : '${pr.weight} kg × ${pr.reps} reps',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '≈ ${pr.epley1RM.toInt()} 1RM',
                      style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.primary, fontSize: AppTypography.labelMd),
                    ),
                    Text(_formatDate(pr.date, isRtl), style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime d, bool isRtl) {
    final months = isRtl
        ? ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر']
        : ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }
}
