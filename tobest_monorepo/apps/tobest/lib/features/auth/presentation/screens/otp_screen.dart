// apps/tobest/lib/features/auth/presentation/screens/otp_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/utils/validators.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:shared/infrastructure/secure_screen_service.dart';

/// شاشة التحقق من OTP
///
/// محمية بـ FLAG_SECURE حقيقي (Android) — يمنع لقطات الشاشة والتسجيل
/// ⚠️ على iOS لا توجد آلية برمجية مكافئة (قيد من Apple)
/// OTP صالح لـ 10 دقائق فقط — مع عداد للإرسال مجدداً
class OtpScreen extends HookConsumerWidget {
  const OtpScreen({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey   = useMemoized(GlobalKey<FormState>.new);
    final otpCtrl   = useTextEditingController();
    final isLoading = useState(false);
    final resendCountdown = useState(AppConfig.otpResendSeconds);
    final theme     = Theme.of(context);
    final isRtl     = Directionality.of(context) == TextDirection.rtl;

    // FLAG_SECURE حقيقي — يُفعَّل عند الدخول ويُعطَّل عند الخروج
    useEffect(() {
      SecureScreenService.enable();
      return () => SecureScreenService.disable();
    }, const []);

    // عداد تنازلي لإعادة الإرسال
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (resendCountdown.value > 0) {
          resendCountdown.value--;
        } else {
          t.cancel();
        }
      });
      return timer.cancel;
    }, const []);

    Future<void> onVerify() async {
      if (!formKey.currentState!.validate()) return;
      isLoading.value = true;

      try {
        final gasClient = await ref.read(gasClientProvider.future);
        final response = await gasClient.post<Map<String, dynamic>>(
          '/auth/verify-otp',
          data: {'email': email, 'otp': otpCtrl.text.trim()},
        );

        if (response.data?['verified'] == true) {
          // الانتقال لإعادة تعيين كلمة المرور
          if (context.mounted) {
            context.pushNamed('reset-password', extra: {
              'email': email,
              'token': response.data?['resetToken'],
            });
          }
        } else {
          throw Exception(isRtl ? 'الرمز غير صحيح' : 'Invalid code');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$e'),
            backgroundColor: theme.colorScheme.error,
          ));
        }
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> onResend() async {
      resendCountdown.value = AppConfig.otpResendSeconds;
      try {
        final gasClient = await ref.read(gasClientProvider.future);
        await gasClient.post('/auth/send-otp', data: {'email': email});

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isRtl ? 'تم إرسال رمز جديد' : 'New code sent'),
          ));
        }
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'التحقق من الرمز' : 'Verify Code'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),

              Icon(Icons.verified_outlined,
                  size: 72, color: theme.colorScheme.primary),

              const SizedBox(height: AppSpacing.xl),

              Text(
                isRtl ? 'أدخل رمز التحقق' : 'Enter Verification Code',
                style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isRtl
                    ? 'تم إرسال رمز مكوّن من 6 أرقام إلى\n$email'
                    : 'A 6-digit code was sent to\n$email',
                style:     theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // ── حقل OTP كبير ──────────────────────────────
              TextFormField(
                controller:   otpCtrl,
                keyboardType: TextInputType.number,
                textAlign:    TextAlign.center,
                maxLength:    6,
                style:        theme.textTheme.headlineMedium?.copyWith(
                  letterSpacing: 8,
                  fontWeight:    FontWeight.w700,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => AppValidators.otp(v, isRtl: isRtl),
                decoration: InputDecoration(
                  counterText: '',
                  hintText:    '000000',
                  hintStyle: theme.textTheme.headlineMedium?.copyWith(
                    letterSpacing: 8,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // ── صلاحية الرمز ──────────────────────────────
              Text(
                isRtl
                    ? 'صالح لـ ${AppConfig.otpExpiryMinutes} دقائق'
                    : 'Valid for ${AppConfig.otpExpiryMinutes} minutes',
                style:     theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              FilledButton(
                onPressed: isLoading.value ? null : onVerify,
                child: isLoading.value
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white,
                        ),
                      )
                    : Text(isRtl ? 'تحقق' : 'Verify'),
              ),

              const SizedBox(height: AppSpacing.base),

              // ── إعادة الإرسال ─────────────────────────────
              TextButton(
                onPressed:
                    resendCountdown.value == 0 ? onResend : null,
                child: Text(
                  resendCountdown.value > 0
                      ? (isRtl
                          ? 'إعادة الإرسال بعد ${resendCountdown.value}s'
                          : 'Resend in ${resendCountdown.value}s')
                      : (isRtl ? 'إعادة إرسال الرمز' : 'Resend Code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
