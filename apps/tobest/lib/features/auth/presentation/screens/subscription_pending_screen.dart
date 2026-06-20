// apps/tobest/lib/features/auth/presentation/screens/subscription_pending_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/design/widgets/breathing_animation.dart';
import 'package:tobest/features/auth/presentation/providers/auth_provider.dart';

/// شاشة انتظار مراجعة الاشتراك
///
/// تعرض Breathing Animation مع زر Refresh لإعادة التحقق
class SubscriptionPendingScreen extends ConsumerWidget {
  const SubscriptionPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Breathing Animation كـ Loading Indicator ──
              BreathingAnimation(
                size:     120,
                isRtl:    isRtl,
                inhaleTextAr: 'جاري المراجعة...',
                exhaleTextAr: 'شكراً لانتظارك',
                inhaleTextEn: 'Under review...',
                exhaleTextEn: 'Thank you for waiting',
              ),

              const SizedBox(height: AppSpacing.xxxl),

              Text(
                isRtl ? 'طلبك قيد المراجعة' : 'Request Under Review',
                style:     theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.base),

              Text(
                isRtl
                    ? 'يتم مراجعة طلب اشتراكك من قبل فريقنا.\nسيتم إشعارك فور الموافقة.'
                    : 'Your subscription request is being reviewed by our team.\nYou will be notified once approved.',
                style:     theme.textTheme.bodyMedium?.copyWith(
                  color:  theme.colorScheme.onSurface.withOpacity(0.6),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // ── زر إعادة التحقق ───────────────────────────
              OutlinedButton.icon(
                onPressed: () async {
                  // إعادة جلب حالة المستخدم
                  await ref.refresh(authStateProvider.future);
                },
                icon:  const Icon(Icons.refresh),
                label: Text(isRtl ? 'إعادة التحقق' : 'Refresh Status'),
              ),

              const SizedBox(height: AppSpacing.base),

              // ── تسجيل الخروج ─────────────────────────────
              TextButton(
                onPressed: () =>
                    ref.read(authStateProvider.notifier).logout(),
                child: Text(
                  isRtl ? 'تسجيل الخروج' : 'Logout',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
