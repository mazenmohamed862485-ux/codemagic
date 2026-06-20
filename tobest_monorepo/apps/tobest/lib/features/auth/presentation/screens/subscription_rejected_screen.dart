// apps/tobest/lib/features/auth/presentation/screens/subscription_rejected_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/design/tokens.dart';
import 'package:tobest/features/auth/presentation/providers/auth_provider.dart';
import 'package:tobest/router.dart';

/// شاشة رفض طلب الاشتراك
class SubscriptionRejectedScreen extends ConsumerWidget {
  const SubscriptionRejectedScreen({super.key});

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
              Icon(Icons.cancel_outlined,
                  size: 80, color: theme.colorScheme.error),

              const SizedBox(height: AppSpacing.xl),

              Text(
                isRtl ? 'تم رفض الطلب' : 'Request Rejected',
                style:     theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color:      theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.base),

              Text(
                isRtl
                    ? 'للأسف تم رفض طلب اشتراكك.\nيمكنك التقديم مجدداً أو التواصل مع الدعم.'
                    : 'Unfortunately, your subscription request was rejected.\nYou can reapply or contact support.',
                style:     theme.textTheme.bodyMedium?.copyWith(
                  color:  theme.colorScheme.onSurface.withOpacity(0.6),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xxxl),

              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.subscription),
                icon:  const Icon(Icons.refresh),
                label: Text(isRtl ? 'تقديم طلب جديد' : 'Reapply'),
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
