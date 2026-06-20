// apps/tobest_management/lib/features/auth/presentation/screens/mgmt_login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/utils/validators.dart';
import 'package:tobest_management/features/auth/presentation/providers/mgmt_auth_provider.dart';

class MgmtLoginScreen extends HookConsumerWidget {
  const MgmtLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey      = useMemoized(GlobalKey<FormState>.new);
    final emailCtrl    = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final showPass     = useState(false);
    final authState    = ref.watch(mgmtAuthStateProvider);
    final isLoading    = authState.isLoading;
    final theme        = Theme.of(context);
    final isRtl        = Directionality.of(context) == TextDirection.rtl;

    ref.listen(mgmtAuthStateProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: theme.colorScheme.error,
          ),
        ),
      );
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 80, height: 80,
                  child: Image.asset('assets/images/tom_icon_light.png'),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  isRtl ? 'لوحة الإدارة' : 'Management Panel',
                  style:     theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  isRtl ? 'للمدراء والدعم والاشتراكات فقط' : 'Staff access only',
                  style:     theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xxxl),

                TextFormField(
                  controller:   emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) => AppValidators.email(v, isRtl: isRtl),
                  decoration: InputDecoration(
                    labelText:  isRtl ? 'البريد الإلكتروني' : 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller:      passwordCtrl,
                  obscureText:     !showPass.value,
                  textInputAction: TextInputAction.done,
                  validator: (v) => AppValidators.password(v, isRtl: isRtl),
                  decoration: InputDecoration(
                    labelText:  isRtl ? 'كلمة المرور' : 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(showPass.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => showPass.value = !showPass.value,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          await ref.read(mgmtAuthStateProvider.notifier).login(
                                email:    emailCtrl.text.trim(),
                                password: passwordCtrl.text,
                              );
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white,
                          ),
                        )
                      : Text(isRtl ? 'دخول' : 'Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
