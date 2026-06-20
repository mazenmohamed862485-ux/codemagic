import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/domain/entities/health_entity.dart';
import 'package:tobest/features/health/presentation/providers/health_provider.dart';

class SleepLogScreen extends HookConsumerWidget {
  const SleepLogScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hours    = useState(7);
    final minutes  = useState(0);
    final quality  = useState(SleepQuality.good);
    final isLoading = useState(false);
    final isRtl    = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(title: Text(isRtl ? 'تسجيل النوم' : 'Log Sleep')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(isRtl ? 'مدة النوم' : 'Sleep Duration',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(child: DropdownButton<int>(
              value: hours.value,
              items: List.generate(13, (i) => DropdownMenuItem(value: i, child: Text('$i h'))),
              onChanged: (v) => hours.value = v ?? 7,
              isExpanded: true,
            )),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: DropdownButton<int>(
              value: minutes.value,
              items: [0, 15, 30, 45].map((m) => DropdownMenuItem(value: m, child: Text('$m min'))).toList(),
              onChanged: (v) => minutes.value = v ?? 0,
              isExpanded: true,
            )),
          ]),
          const SizedBox(height: AppSpacing.xl),
          Text(isRtl ? 'جودة النوم' : 'Sleep Quality',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<SleepQuality>(
            segments: SleepQuality.values.map((q) =>
              ButtonSegment(value: q, label: Text(isRtl ? q.labelAr : q.labelEn))).toList(),
            selected: {quality.value},
            onSelectionChanged: (s) => quality.value = s.first,
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: isLoading.value ? null : () async {
              isLoading.value = true;
              try {
                await ref.read(sleepActionsProvider.notifier).saveSleep(
                  hours: hours.value, minutes: minutes.value, quality: quality.value,
                );
                if (context.mounted) Navigator.of(context).pop();
              } finally { isLoading.value = false; }
            },
            child: Text(isRtl ? 'حفظ' : 'Save'),
          ),
        ]),
      ),
    );
  }
}
