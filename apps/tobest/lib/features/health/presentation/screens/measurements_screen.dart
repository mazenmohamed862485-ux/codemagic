import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/design/tokens.dart';
import 'package:tobest/features/health/presentation/providers/health_provider.dart';

class MeasurementsScreen extends HookConsumerWidget {
  const MeasurementsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightCtrl = useTextEditingController();
    final waistCtrl  = useTextEditingController();
    final chestCtrl  = useTextEditingController();
    final hipCtrl    = useTextEditingController();
    final neckCtrl   = useTextEditingController();
    final isLoading  = useState(false);
    final isRtl      = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(title: Text(isRtl ? 'القياسات الجسدية' : 'Body Measurements')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final e in [
            (weightCtrl, isRtl ? 'الوزن (كجم)' : 'Weight (kg)'),
            (waistCtrl,  isRtl ? 'الخصر (سم)'  : 'Waist (cm)'),
            (chestCtrl,  isRtl ? 'الصدر (سم)'  : 'Chest (cm)'),
            (hipCtrl,    isRtl ? 'الورك (سم)'  : 'Hip (cm)'),
            (neckCtrl,   isRtl ? 'الرقبة (سم)' : 'Neck (cm)'),
          ]) ...[
            TextFormField(
              controller: e.$1,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: e.$2),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: isLoading.value ? null : () async {
              final w = double.tryParse(weightCtrl.text);
              if (w == null) return;
              isLoading.value = true;
              try {
                await ref.read(measurementActionsProvider.notifier).saveMeasurement(
                  weight: w,
                  waist: double.tryParse(waistCtrl.text),
                  chest: double.tryParse(chestCtrl.text),
                  hip:   double.tryParse(hipCtrl.text),
                  neck:  double.tryParse(neckCtrl.text),
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
