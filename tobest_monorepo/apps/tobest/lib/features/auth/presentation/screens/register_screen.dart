// apps/tobest/lib/features/auth/presentation/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/utils/validators.dart';
import 'package:tobest/features/auth/presentation/providers/auth_provider.dart';

/// شاشة تسجيل حساب جديد
class RegisterScreen extends HookConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey      = useMemoized(GlobalKey<FormState>.new);
    final nameCtrl     = useTextEditingController();
    final emailCtrl    = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final confirmCtrl  = useTextEditingController();
    final phoneCtrl    = useTextEditingController();
    final heightCtrl   = useTextEditingController();
    final weightCtrl   = useTextEditingController();
    final ageCtrl      = useTextEditingController();
    final referralCtrl = useTextEditingController();
    final gender       = useState('male');
    final showPassword = useState(false);
    final isLoading    = ref.watch(authStateProvider).isLoading;
    final theme        = Theme.of(context);
    final isRtl        = Directionality.of(context) == TextDirection.rtl;

    ref.listen(authStateProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: theme.colorScheme.error,
          ),
        ),
      );
    });

    Future<void> onRegister() async {
      if (!formKey.currentState!.validate()) return;
      await ref.read(authStateProvider.notifier).register(
            name:         nameCtrl.text.trim(),
            email:        emailCtrl.text.trim(),
            password:     passwordCtrl.text,
            phone:        phoneCtrl.text.trim(),
            height:       double.parse(heightCtrl.text.trim()),
            weight:       double.parse(weightCtrl.text.trim()),
            age:          int.parse(ageCtrl.text.trim()),
            gender:       gender.value,
            referralCode: referralCtrl.text.trim().isEmpty
                ? null
                : referralCtrl.text.trim(),
          );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'حساب جديد' : 'Create Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── البيانات الأساسية ────────────────────────────
              _SectionTitle(isRtl ? 'المعلومات الأساسية' : 'Basic Info'),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller:  nameCtrl,
                textInputAction: TextInputAction.next,
                validator: (v) => AppValidators.name(v, isRtl: isRtl),
                decoration: InputDecoration(
                  labelText:  isRtl ? 'الاسم الكامل' : 'Full Name',
                  prefixIcon: const Icon(Icons.person_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.base),

              TextFormField(
                controller:  emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) => AppValidators.email(v, isRtl: isRtl),
                decoration: InputDecoration(
                  labelText:  isRtl ? 'البريد الإلكتروني' : 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.base),

              TextFormField(
                controller:      passwordCtrl,
                obscureText:     !showPassword.value,
                textInputAction: TextInputAction.next,
                validator: (v) => AppValidators.password(v, isRtl: isRtl),
                decoration: InputDecoration(
                  labelText:  isRtl ? 'كلمة المرور' : 'Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(showPassword.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        showPassword.value = !showPassword.value,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.base),

              TextFormField(
                controller:      confirmCtrl,
                obscureText:     true,
                textInputAction: TextInputAction.next,
                validator: (v) => AppValidators.confirmPassword(
                  v, passwordCtrl.text,
                  isRtl: isRtl,
                ),
                decoration: InputDecoration(
                  labelText:  isRtl ? 'تأكيد كلمة المرور' : 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.base),

              TextFormField(
                controller:  phoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (v) => AppValidators.phone(v, isRtl: isRtl),
                decoration: InputDecoration(
                  labelText:  isRtl ? 'رقم الهاتف' : 'Phone',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  hintText: '+966XXXXXXXXX',
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── البيانات الصحية ──────────────────────────────
              _SectionTitle(isRtl ? 'البيانات الصحية' : 'Health Data'),
              const SizedBox(height: AppSpacing.md),

              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller:  heightCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: (v) => AppValidators.height(v, isRtl: isRtl),
                    decoration: InputDecoration(
                      labelText: isRtl ? 'الطول (سم)' : 'Height (cm)',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller:  weightCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: (v) => AppValidators.weight(v, isRtl: isRtl),
                    decoration: InputDecoration(
                      labelText: isRtl ? 'الوزن (كجم)' : 'Weight (kg)',
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: AppSpacing.base),

              TextFormField(
                controller:  ageCtrl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (v) => AppValidators.age(v, isRtl: isRtl),
                decoration: InputDecoration(
                  labelText:  isRtl ? 'العمر' : 'Age',
                  prefixIcon: const Icon(Icons.cake_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.base),

              // ── اختيار الجنس ─────────────────────────────────
              Text(
                isRtl ? 'الجنس' : 'Gender',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [
                Expanded(
                  child: _GenderCard(
                    label:     isRtl ? 'ذكر' : 'Male',
                    icon:      Icons.male,
                    selected:  gender.value == 'male',
                    onTap:     () => gender.value = 'male',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _GenderCard(
                    label:     isRtl ? 'أنثى' : 'Female',
                    icon:      Icons.female,
                    selected:  gender.value == 'female',
                    onTap:     () => gender.value = 'female',
                  ),
                ),
              ]),

              const SizedBox(height: AppSpacing.xl),

              // ── كود الإحالة (اختياري) ─────────────────────────
              TextFormField(
                controller:  referralCtrl,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText:  isRtl ? 'كود الإحالة (اختياري)' : 'Referral Code (optional)',
                  prefixIcon: const Icon(Icons.card_giftcard_outlined),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── زر التسجيل ───────────────────────────────────
              FilledButton(
                onPressed: isLoading ? null : onRegister,
                child: isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white,
                        ),
                      )
                    : Text(isRtl ? 'إنشاء الحساب' : 'Create Account'),
              ),

              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
      );
}

class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap:       onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: AnimatedContainer(
        duration:   AppDurations.fast,
        padding:    const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border:       Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
          color: selected
              ? theme.colorScheme.primary.withOpacity(0.08)
              : null,
        ),
        child: Column(children: [
          Icon(icon,
              color:
                  selected ? theme.colorScheme.primary : theme.colorScheme.onSurface),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color:      selected ? theme.colorScheme.primary : null,
              fontWeight: selected ? FontWeight.w600 : null,
            ),
          ),
        ]),
      ),
    );
  }
}
