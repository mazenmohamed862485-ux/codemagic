import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/design/tokens.dart';
import 'package:tobest/features/health/presentation/providers/health_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:tobest/router.dart';

class HealthScreen extends HookConsumerWidget {
  const HealthScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepsAsync = ref.watch(todayStepsProvider);
    final liveSteps  = ref.watch(liveStepsProvider);
    final theme      = Theme.of(context);
    final isRtl      = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(title: Text(isRtl ? 'الصحة' : 'Health')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          // Live pedometer
          liveSteps.when(
            data: (s) => Card(
              child: ListTile(
                leading: const Icon(Icons.directions_walk, size: 36),
                title: Text('$s', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                subtitle: Text(isRtl ? 'خطوات مباشرة' : 'Live steps'),
                trailing: FilledButton(
                  onPressed: () => ref.read(stepsActionsProvider.notifier).saveSteps(s),
                  child: Text(isRtl ? 'حفظ' : 'Save'),
                ),
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => ListTile(
              leading: const Icon(Icons.warning_amber, color: Colors.orange),
              title: Text(isRtl ? 'Pedometer غير متاح' : 'Pedometer unavailable'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Quick log buttons
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.sleepLog),
                icon: const Icon(Icons.bedtime_outlined),
                label: Text(isRtl ? 'سجّل نومك' : 'Log Sleep'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.measurements),
                icon: const Icon(Icons.straighten),
                label: Text(isRtl ? 'قياسات' : 'Measurements'),
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.md),
          stepsAsync.when(
            data: (record) => record == null
                ? const SizedBox.shrink()
                : Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(isRtl ? 'إحصاءات اليوم' : "Today's Stats",
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: AppSpacing.sm),
                        Text('${record.steps} ${isRtl ? "خطوة" : "steps"}'),
                        Text('${record.distanceKm.toStringAsFixed(2)} km'),
                        Text('${record.caloriesBurned.toStringAsFixed(0)} ${isRtl ? "كال محروقة" : "kcal burned"}'),
                      ]),
                    ),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
