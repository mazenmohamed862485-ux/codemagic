// apps/tobest/lib/features/progress/presentation/screens/progress_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/design/tokens.dart';
import 'package:tobest/features/health/presentation/providers/health_provider.dart';
import 'package:tobest/features/progress/presentation/widgets/body_chart.dart';
import 'package:tobest/features/progress/presentation/widgets/pr_list.dart';
import 'package:tobest/features/progress/presentation/widgets/steps_chart.dart';

/// شاشة التقدم — Charts + PRs + قياسات
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isRtl ? 'التقدم' : 'Progress'),
          bottom: TabBar(
            tabs: [
              Tab(text: isRtl ? 'الخطوات' : 'Steps'),
              Tab(text: isRtl ? 'الأرقام القياسية' : 'PRs'),
              Tab(text: isRtl ? 'الجسم' : 'Body'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _StepsTab(),
            _PRsTab(),
            _BodyTab(),
          ],
        ),
      ),
    );
  }
}

class _StepsTab extends ConsumerWidget {
  const _StepsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepsAsync = ref.watch(weeklyStepsProvider);
    final isRtl      = Directionality.of(context) == TextDirection.rtl;

    return stepsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('$e')),
      data: (steps) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRtl ? 'خطوات آخر 7 أيام' : 'Last 7 Days Steps',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            StepsChart(records: steps, isRtl: isRtl),
            const SizedBox(height: AppSpacing.xl),

            // ── إحصاءات الأسبوع ────────────────────────────
            Row(children: [
              Expanded(
                child: _StatCard(
                  label: isRtl ? 'إجمالي الأسبوع' : 'Weekly Total',
                  value: steps.fold(0, (s, r) => s + r.steps).toString(),
                  unit:  isRtl ? 'خطوة' : 'steps',
                  icon:  Icons.directions_walk,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  label: isRtl ? 'المسافة الكلية' : 'Total Distance',
                  value: steps
                      .fold(0.0, (s, r) => s + r.distanceKm)
                      .toStringAsFixed(1),
                  unit:  'km',
                  icon:  Icons.route,
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

class _PRsTab extends StatelessWidget {
  const _PRsTab();

  @override
  Widget build(BuildContext context) {
    return const PRList();
  }
}

class _BodyTab extends ConsumerWidget {
  const _BodyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        children: [
          const BodyChart(),
          const SizedBox(height: AppSpacing.xl),

          // ── زر إضافة قياسات ────────────────────────────
          FilledButton.icon(
            onPressed: () => _showMeasurementDialog(context, ref, isRtl),
            icon:  const Icon(Icons.add),
            label: Text(isRtl ? 'تسجيل قياسات' : 'Log Measurements'),
          ),
        ],
      ),
    );
  }

  void _showMeasurementDialog(BuildContext ctx, WidgetRef ref, bool isRtl) {
    showModalBottomSheet(
      context:          ctx,
      isScrollControlled: true,
      builder: (_) => _MeasurementSheet(isRtl: isRtl, ref: ref),
    );
  }
}

class _MeasurementSheet extends StatefulWidget {
  const _MeasurementSheet({required this.isRtl, required this.ref});
  final bool isRtl;
  final WidgetRef ref;

  @override
  State<_MeasurementSheet> createState() => _MeasurementSheetState();
}

class _MeasurementSheetState extends State<_MeasurementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _weight  = TextEditingController();
  final _waist   = TextEditingController();
  final _chest   = TextEditingController();
  final _hip     = TextEditingController();
  final _neck    = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left:   AppSpacing.base,
        right:  AppSpacing.base,
        top:    AppSpacing.base,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isRtl ? 'تسجيل القياسات' : 'Log Measurements',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.base),

            _field(_weight, widget.isRtl ? 'الوزن (كجم)' : 'Weight (kg)'),
            _field(_waist,  widget.isRtl ? 'الخصر (سم)'  : 'Waist (cm)'),
            _field(_chest,  widget.isRtl ? 'الصدر (سم)'  : 'Chest (cm)'),
            _field(_hip,    widget.isRtl ? 'الورك (سم)'  : 'Hip (cm)'),
            _field(_neck,   widget.isRtl ? 'الرقبة (سم)' : 'Neck (cm)'),

            const SizedBox(height: AppSpacing.md),

            FilledButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white,
                      ),
                    )
                  : Text(widget.isRtl ? 'حفظ' : 'Save'),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: TextFormField(
          controller:   ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration:   InputDecoration(
            labelText: label,
            isDense:   true,
          ),
        ),
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final w = double.tryParse(_weight.text);
      if (w == null) return;

      await widget.ref.read(measurementActionsProvider.notifier).saveMeasurement(
        weight: w,
        waist:  double.tryParse(_waist.text),
        chest:  double.tryParse(_chest.text),
        hip:    double.tryParse(_hip.text),
        neck:   double.tryParse(_neck.text),
      );

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _weight.dispose();
    _waist.dispose();
    _chest.dispose();
    _hip.dispose();
    _neck.dispose();
    super.dispose();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: AppSpacing.iconLg),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color:      color,
              ),
            ),
            Text(unit, style: theme.textTheme.labelSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
