// apps/tobest/lib/features/auth/presentation/screens/google_completion_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/utils/validators.dart';

/// إكمال البيانات عند أول تسجيل بـ Google Sign-In
///
/// عند نقص البيانات الصحية تظهر هذه الشاشة قبل الانتقال للرئيسية
class GoogleCompletionScreen extends HookConsumerWidget {
  const GoogleCompletionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey    = useMemoized(GlobalKey<FormState>.new);
    final phoneCtrl  = useTextEditingController();
    final heightCtrl = useTextEditingController();
    final weightCtrl = useTextEditingController();
    final ageCtrl    = useTextEditingController();
    final gender     = useState('male');
    final isLoading  = useState(false);
    final theme      = Theme.of(context);
    final isRtl      = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),
                Icon(Icons.fitness_center,
                    size:  72,
                    color: theme.colorScheme.primary),

                const SizedBox(height: AppSpacing.base),
                Text(
                  isRtl ? 'أكمل ملفك الصحي' : 'Complete Your Profile',
                  style:     theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  isRtl
                      ? 'نحتاج هذه المعلومات لتخصيص برنامجك'
                      : 'We need this info to personalize your program',
                  style:     theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xxxl),

                TextFormField(
                  controller:   phoneCtrl,
                  keyboardType: TextInputType.phone,
                  validator: (v) => AppValidators.phone(v, isRtl: isRtl),
                  decoration: InputDecoration(
                    labelText:  isRtl ? 'رقم الهاتف' : 'Phone',
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.base),

                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller:   heightCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) => AppValidators.height(v, isRtl: isRtl),
                      decoration: InputDecoration(
                        labelText: isRtl ? 'الطول (سم)' : 'Height (cm)',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller:   weightCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) => AppValidators.weight(v, isRtl: isRtl),
                      decoration: InputDecoration(
                        labelText: isRtl ? 'الوزن (كجم)' : 'Weight (kg)',
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: AppSpacing.base),

                TextFormField(
                  controller:   ageCtrl,
                  keyboardType: TextInputType.number,
                  validator: (v) => AppValidators.age(v, isRtl: isRtl),
                  decoration: InputDecoration(
                    labelText:  isRtl ? 'العمر' : 'Age',
                    prefixIcon: const Icon(Icons.cake_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.base),

                // اختيار الجنس
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'male',
                      label: Text(isRtl ? 'ذكر' : 'Male'),
                      icon: const Icon(Icons.male),
                    ),
                    ButtonSegment(
                      value: 'female',
                      label: Text(isRtl ? 'أنثى' : 'Female'),
                      icon: const Icon(Icons.female),
                    ),
                  ],
                  selected: {gender.value},
                  onSelectionChanged: (v) => gender.value = v.first,
                ),

                const SizedBox(height: AppSpacing.xl),

                FilledButton(
                  onPressed: isLoading.value ? null : () async {
                    if (!formKey.currentState!.validate()) return;
                    isLoading.value = true;
                    // الإكمال عبر AuthProvider
                    isLoading.value = false;
                  },
                  child: isLoading.value
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white,
                          ),
                        )
                      : Text(isRtl ? 'متابعة' : 'Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
