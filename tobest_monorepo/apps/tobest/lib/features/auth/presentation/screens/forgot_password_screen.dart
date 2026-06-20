// apps/tobest/lib/features/auth/presentation/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/utils/validators.dart';
import 'package:tobest/router.dart';
import 'package:shared/infrastructure/gas_client.dart';

/// شاشة نسيان كلمة المرور — الخطوة الأولى: إدخال الإيميل
class ForgotPasswordScreen extends HookConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey   = useMemoized(GlobalKey<FormState>.new);
    final emailCtrl = useTextEditingController();
    final isLoading = useState(false);
    final isRtl     = Directionality.of(context) == TextDirection.rtl;
    final theme     = Theme.of(context);

    Future<void> onSendOtp() async {
      if (!formKey.currentState!.validate()) return;
      isLoading.value = true;

      try {
        final gasClient = await ref.read(gasClientProvider.future);
        await gasClient.post('/auth/send-otp', data: {
          'email': emailCtrl.text.trim(),
        });

        if (context.mounted) {
          context.push(AppRoutes.otp, extra: emailCtrl.text.trim());
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isRtl
                ? 'فشل إرسال الرمز: $e'
                : 'Failed to send code: $e'),
            backgroundColor: theme.colorScheme.error,
          ));
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'استعادة كلمة المرور' : 'Reset Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Icon(Icons.lock_reset,
                  size: 72,
                  color: theme.colorScheme.primary),

              const SizedBox(height: AppSpacing.xl),
              Text(
                isRtl
                    ? 'أدخل بريدك الإلكتروني وسنرسل لك رمز للتحقق'
                    : 'Enter your email and we will send a verification code',
                style:     theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xxxl),

              TextFormField(
                controller:   emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => AppValidators.email(v, isRtl: isRtl),
                decoration: InputDecoration(
                  labelText:  isRtl ? 'البريد الإلكتروني' : 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              FilledButton(
                onPressed: isLoading.value ? null : onSendOtp,
                child: isLoading.value
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white,
                        ),
                      )
                    : Text(isRtl ? 'إرسال الرمز' : 'Send Code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
