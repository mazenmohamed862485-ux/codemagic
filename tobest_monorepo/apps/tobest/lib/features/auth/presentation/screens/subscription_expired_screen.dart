// apps/tobest/lib/features/auth/presentation/screens/subscription_expired_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/design/tokens.dart';
import 'package:tobest/features/auth/presentation/providers/auth_provider.dart';
import 'package:tobest/router.dart';

/// شاشة انتهاء صلاحية الاشتراك
class SubscriptionExpiredScreen extends ConsumerWidget {
  const SubscriptionExpiredScreen({super.key});

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
              Icon(Icons.timer_off_outlined,
                  size:  80,
                  color: theme.colorScheme.tertiary),

              const SizedBox(height: AppSpacing.xl),

              Text(
                isRtl ? 'انتهى اشتراكك' : 'Subscription Expired',
                style:     theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.base),

              Text(
                isRtl
                    ? 'انتهت صلاحية اشتراكك.\nجدّده الآن للاستمرار في برنامجك.'
                    : 'Your subscription has expired.\nRenew now to continue your program.',
                style:     theme.textTheme.bodyMedium?.copyWith(
                  color:  theme.colorScheme.onSurface.withOpacity(0.6),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xxxl),

              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.subscription),
                icon:  const Icon(Icons.autorenew),
                label: Text(isRtl ? 'تجديد الاشتراك' : 'Renew Subscription'),
              ),

              const SizedBox(height: AppSpacing.base),

              TextButton(
                onPressed: () =>
                    ref.read(authStateProvider.notifier).logout(),
                child: Text(
                  isRtl ? 'تسجيل الخروج' : 'Logout',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
