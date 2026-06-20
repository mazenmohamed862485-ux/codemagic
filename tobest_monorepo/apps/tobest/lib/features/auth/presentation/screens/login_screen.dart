// apps/tobest/lib/features/auth/presentation/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/utils/validators.dart';
import 'package:tobest/features/auth/presentation/providers/auth_provider.dart';
import 'package:tobest/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:tobest/router.dart';

/// شاشة تسجيل الدخول
class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey      = useMemoized(GlobalKey<FormState>.new);
    final emailCtrl    = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final showPassword = useState(false);
    final theme        = Theme.of(context);
    final isRtl        = Directionality.of(context) == TextDirection.rtl;

    // مراقبة حالة المصادقة
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    // عرض الخطأ
    ref.listen(authStateProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRtl ? 'خطأ في تسجيل الدخول: $e' : 'Login error: $e',
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        ),
      );
    });

    Future<void> onLogin() async {
      if (!formKey.currentState!.validate()) return;
      await ref.read(authStateProvider.notifier).loginWithEmail(
            email:    emailCtrl.text.trim(),
            password: passwordCtrl.text,
          );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxxl),

                // ── الشعار ──────────────────────────────────
                Center(
                  child: SizedBox(
                    width:  100,
                    height: 100,
                    child: Image.asset('assets/images/tb_icon_light.png'),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── العنوان ─────────────────────────────────
                Text(
                  isRtl ? 'مرحباً بك' : 'Welcome Back',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  isRtl ? 'سجّل الدخول للمتابعة' : 'Sign in to continue',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xxxl),

                // ── حقل الإيميل ──────────────────────────────
                TextFormField(
                  controller:  emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) => AppValidators.email(v, isRtl: isRtl),
                  decoration: InputDecoration(
                    labelText:    isRtl ? 'البريد الإلكتروني' : 'Email',
                    prefixIcon:   const Icon(Icons.email_outlined),
                    hintText:     'example@email.com',
                  ),
                ),

                const SizedBox(height: AppSpacing.base),

                // ── حقل كلمة المرور ──────────────────────────
                TextFormField(
                  controller:      passwordCtrl,
                  obscureText:     !showPassword.value,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => onLogin(),
                  validator: (v) => AppValidators.password(v, isRtl: isRtl),
                  decoration: InputDecoration(
                    labelText:  isRtl ? 'كلمة المرور' : 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showPassword.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          showPassword.value = !showPassword.value,
                    ),
                  ),
                ),

                // ── نسيت كلمة المرور ─────────────────────────
                Align(
                  alignment: isRtl
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                    child: Text(
                      isRtl ? 'نسيت كلمة المرور؟' : 'Forgot password?',
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.base),

                // ── زر تسجيل الدخول ──────────────────────────
                FilledButton(
                  onPressed: isLoading ? null : onLogin,
                  child: isLoading
                      ? const SizedBox(
                          width:  20,
                          height: 20,
                          child:  CircularProgressIndicator(
                            strokeWidth: 2,
                            color:       Colors.white,
                          ),
                        )
                      : Text(isRtl ? 'تسجيل الدخول' : 'Sign In'),
                ),

                const SizedBox(height: AppSpacing.base),

                // ── Divider ──────────────────────────────────
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: Text(
                      isRtl ? 'أو' : 'OR',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const Expanded(child: Divider()),
                ]),

                const SizedBox(height: AppSpacing.base),

                // ── Google Sign In ────────────────────────────
                const GoogleSignInButton(),

                const SizedBox(height: AppSpacing.xl),

                // ── تسجيل حساب جديد ──────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isRtl ? 'ليس لديك حساب؟' : "Don't have an account?",
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.register),
                      child: Text(
                        isRtl ? 'سجّل الآن' : 'Register',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
